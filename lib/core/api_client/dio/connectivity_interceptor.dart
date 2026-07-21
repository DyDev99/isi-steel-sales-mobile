import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_exception.dart';
import 'package:isi_steel_sales_mobile/core/api_client/network/network_checker.dart';

/// Marks a request that must bypass the offline fast-path.
///
/// Mirrors `skipAuthFlag`. Set it for calls where a cached "offline" verdict is
/// not a useful answer — above all **login**, which by definition requires
/// internet (`docs/OFFLINE_FIRST.md` §4: "Authentication requires internet.
/// After successful login application must continue working offline").
///
/// Gating login on the cached verdict adds a failure mode and buys nothing: the
/// user is actively waiting, there is no local data to fall back to, and a
/// stale or wrong cache turns a working network into an unexplained
/// "No internet connection." Letting the request go and reporting what the
/// socket actually says is both simpler and more honest.
const String skipConnectivityFlag = 'skip_connectivity_check';

/// Rejects requests before they are sent when the device is plainly offline.
///
/// Without this, an offline call sits until the connect timeout expires —
/// 30 seconds of spinner for an answer that was knowable immediately. Failing
/// fast lets the UI fall back to local Drift data at once, which is what
/// offline-first requires (`docs/OFFLINE_FIRST.md`).
///
/// Ordered **first** in the chain: there is no point attaching a token, logging,
/// or arming a retry for a request that will not be dispatched.
class ConnectivityInterceptor extends Interceptor {
  const ConnectivityInterceptor(this._checker);

  final NetworkChecker _checker;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Opted out (login): send it and let the socket give the real answer.
    if (options.extra[skipConnectivityFlag] == true) {
      return handler.next(options);
    }

    if (await _checker.isConnected) return handler.next(options);

    // This rejection used to be completely silent. Because this interceptor
    // runs *before* LoggingInterceptor, a blocked request produced only an
    // `✗ connectionError` line with no `→ POST` line, no status code and no
    // duration — indistinguishable from a request that was sent and failed.
    // Saying so explicitly turns "the app says offline and I don't know why"
    // into a one-line answer.
    //
    // Method and path only: `docs/SECURITY.md` §10 permits the endpoint, and
    // the path is logged without its query string because SAP's filter routes
    // carry customer names and numbers there.
    if (kDebugMode) {
      final path = options.path;
      final queryStart = path.indexOf('?');
      debugPrint(
        '[connectivity] BLOCKED ${options.method} '
        '${queryStart == -1 ? path : path.substring(0, queryStart)} — '
        'ConnectivityService reports offline, so the request was never sent. '
        'Check the connectivity.probe_* logs for why the probe failed.',
      );
    }

    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: NoInternetException(endpoint: options.path),
      ),
      // `true` marks this as a resolved rejection so Dio does not run the
      // remaining error interceptors — notably the retry interceptor, which
      // would otherwise back off and re-attempt a request that cannot succeed
      // until connectivity returns. Reconnect is an event, not something to
      // wait out in a retry loop.
      true,
    );
  }
}
