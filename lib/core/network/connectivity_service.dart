import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/config/env.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';

/// Application-wide connectivity state.
///
/// [online] means **the app can actually reach its API**, not merely that the OS
/// reports a network interface — see [ConnectivityService].
enum ConnectivityStatus { online, offline }

/// Confirms real internet reachability, separate from interface-up state.
///
/// Extracted as a seam so [ConnectivityServiceImpl] is testable without a
/// network (`docs/AI_ENGINEERING_PLAYBOOK.md` §7.6: a test that mocks away the
/// thing under test is worse than no test — here the probe is a collaborator,
/// not the logic being verified).
abstract interface class ReachabilityProbe {
  Future<bool> isReachable();
}

/// Probes the app's **own** API gateway ([Env.sapBaseUrlPrimary]).
///
/// ADR-005 is explicit that the probe must target our own infrastructure rather
/// than a third-party endpoint, so "reachable" means "reachable enough to sync"
/// — a third-party host being down must never make the app think it is offline.
///
/// `docs/SECURITY.md` §6 requires a timeout and a defined retry policy on every
/// network call: this issues a single bounded-timeout request and never retries
/// (the caller re-probes on the next connectivity event; retry/backoff is the
/// sync engine's job, per `docs/SYNC_ENGINE.md` §4).
class HttpReachabilityProbe implements ReachabilityProbe {
  HttpReachabilityProbe({
    required Dio dio,
    required AppLogger logger,
    Duration timeout = const Duration(seconds: 5),
  })  : _dio = dio,
        _logger = logger,
        _timeout = timeout;

  final Dio _dio;
  final AppLogger _logger;
  final Duration _timeout;

  @override
  Future<bool> isReachable() async {
    final target = Env.sapBaseUrlPrimary;
    try {
      final response = await _dio.head<void>(
        target,
        options: Options(
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
          // Any HTTP answer proves the network path works. A 401/404 still means
          // we reached the gateway, which is what "online" must mean here — the
          // alternative (requiring 2xx) would report offline whenever the token
          // is stale, and ADR-002 forbids coupling connectivity to auth.
          validateStatus: (_) => true,
        ),
      );
      // Logged on success too: "the probe succeeded" was previously invisible,
      // so an app stuck offline looked identical to one that had simply never
      // probed. `status` is the response code, which §10 permits.
      _logger.debug('connectivity.probe_ok',
          fields: {'host': target, 'status': response.statusCode});
      return response.statusCode != null;
    } on DioException catch (e) {
      // §10: type names and the endpoint only — never a request or response
      // body. `errorType` is the underlying exception's *class*, which is the
      // single most useful field here: a `HandshakeException` means the
      // certificate pin is missing or wrong (fix `SAP_CERT_SHA256`), whereas a
      // `SocketException` means the host is unreachable from this network
      // (wrong subnet, VPN down, or an IP allowlist refusing this client).
      // Collapsing both into `connectionError` hid exactly that distinction.
      _logger.debug('connectivity.probe_failed', fields: {
        'host': target,
        'reason': e.type.name,
        'errorType': e.error?.runtimeType.toString(),
      });
      return false;
    } catch (e) {
      // Previously `catch (_)` — a silent swallow, which
      // `docs/ENGINEERING_STANDARD.md` §7 disallows. The type alone is enough
      // to tell a config error from a transport one.
      _logger.debug('connectivity.probe_failed', fields: {
        'host': target,
        'reason': 'unexpected',
        'errorType': e.runtimeType.toString(),
      });
      return false;
    }
  }
}

/// The single source of truth for connectivity across the app (ADR-005).
///
/// Every consumer — the UI status pill (`docs/OFFLINE_FIRST.md` §5) and the sync
/// drain trigger (`docs/SYNC_ENGINE.md` §9) — subscribes here, so the pill and
/// the sync engine can never disagree. **No UI, bloc, repository or DAO may call
/// `connectivity_plus` directly** (ADR-005 §3).
abstract interface class ConnectivityService {
  /// Last known state, readable synchronously so guards and the sync
  /// coordinator don't have to await (mirrors the `SessionManager` pattern in
  /// `docs/OFFLINE_FIRST.md` §2.6).
  ConnectivityStatus get status;

  bool get isOnline;

  /// Broadcast stream of **distinct** state changes — never emits the same
  /// state twice in a row, so a flapping radio can't trigger repeated drains.
  Stream<ConnectivityStatus> get changes;

  /// Begins monitoring. Idempotent: calling twice does not create a second
  /// listener (ADR-005: "prevent duplicate listeners").
  Future<void> start();

  /// Forces an immediate reachability re-check, e.g. on foreground resume
  /// (`docs/SYNC_ENGINE.md` §9).
  Future<ConnectivityStatus> refresh();

  Future<void> dispose();
}

class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl({
    required Connectivity connectivity,
    required ReachabilityProbe probe,
    required AppLogger logger,
    Duration debounce = const Duration(milliseconds: 500),
  })  : _connectivity = connectivity,
        _probe = probe,
        _logger = logger,
        _debounce = debounce;

  final Connectivity _connectivity;
  final ReachabilityProbe _probe;
  final AppLogger _logger;
  final Duration _debounce;

  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounceTimer;

  /// Guards against overlapping probes when events arrive faster than the probe
  /// resolves — without this, a flapping radio queues probes indefinitely.
  bool _probing = false;

  /// Starts pessimistic: nothing is "online" until a probe proves it.
  ConnectivityStatus _status = ConnectivityStatus.offline;

  @override
  ConnectivityStatus get status => _status;

  @override
  bool get isOnline => _status == ConnectivityStatus.online;

  @override
  Stream<ConnectivityStatus> get changes => _controller.stream;

  @override
  Future<void> start() async {
    // Idempotent (ADR-005: no duplicate listeners).
    if (_subscription != null) return;

    _subscription = _connectivity.onConnectivityChanged.listen(
      _onInterfaceChanged,
      // ADR-005 §4: this service reports state, it never throws to signal
      // offline. A plugin error means "cannot confirm reachability".
      onError: (Object e) {
        _logger.warning(
          'connectivity.stream_error',
          fields: {'reason': e.runtimeType.toString()},
        );
        _publish(ConnectivityStatus.offline);
      },
    );

    await refresh();
  }

  void _onInterfaceChanged(List<ConnectivityResult> results) {
    // Cheap first filter (ADR-005 §1): if the radio is plainly off there is no
    // point spending battery on a probe — go offline immediately.
    if (_isInterfaceDown(results)) {
      _debounceTimer?.cancel();
      _publish(ConnectivityStatus.offline);
      return;
    }

    // Interface up proves nothing (captive portal, no data plan), so debounce
    // then confirm with a real probe (ADR-005 §2).
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => unawaited(refresh()));
  }

  bool _isInterfaceDown(List<ConnectivityResult> results) =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  @override
  Future<ConnectivityStatus> refresh() async {
    if (_probing) {
      _logger.debug('connectivity.refresh_skipped',
          fields: {'reason': 'probe_already_running'});
      return _status;
    }
    _probing = true;
    try {
      final List<ConnectivityResult> results;
      try {
        results = await _connectivity.checkConnectivity();
      } catch (e) {
        // Previously unguarded: a plugin throw propagated out of `refresh()`,
        // out of `start()`, and was swallowed by the bootstrap catch — leaving
        // the app permanently offline with the reason recorded as a generic
        // `bootstrap.failed`. Failing to *confirm* connectivity is not the same
        // as being offline, but offline is the safe assumption; what matters is
        // that it is no longer silent (ADR-005 §4).
        _logger.warning('connectivity.interface_check_failed',
            fields: {'errorType': e.runtimeType.toString()});
        _publish(ConnectivityStatus.offline);
        return _status;
      }

      // The raw plugin verdict. This is the single most useful connectivity
      // diagnostic and was previously invisible: when the interface reads as
      // down, `refresh()` returns before probing, so `connectivity.probe_*`
      // never fires — an app stuck offline produced no log line at all, which
      // is indistinguishable from the probe failing.
      _logger.debug('connectivity.interface_check', fields: {
        'results': results.map((r) => r.name).toList().toString(),
        'interfaceDown': _isInterfaceDown(results),
      });

      if (_isInterfaceDown(results)) {
        _logger.warning('connectivity.offline_no_interface', fields: {
          'results': results.map((r) => r.name).toList().toString(),
          'note': 'probe skipped — OS reports no usable network interface',
        });
        _publish(ConnectivityStatus.offline);
        return _status;
      }

      final reachable = await _probe.isReachable();
      _publish(
        reachable ? ConnectivityStatus.online : ConnectivityStatus.offline,
      );
      // Logged every time, not only on transition: `_publish` is deliberately
      // edge-triggered so `changes` stays distinct, which means a refresh that
      // confirms the *existing* state emits nothing. That is right for the
      // stream and wrong for diagnostics.
      _logger.debug('connectivity.refresh_result',
          fields: {'reachable': reachable, 'status': _status.name});
      return _status;
    } finally {
      _probing = false;
    }
  }

  /// Emits only on an actual transition, so `changes` stays distinct.
  void _publish(ConnectivityStatus next) {
    if (_status == next) return;
    _status = next;
    _logger.info('connectivity.changed', fields: {'status': next.name});
    if (!_controller.isClosed) _controller.add(next);
  }

  @override
  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _controller.close();
  }
}
