import 'package:isi_steel_sales_mobile/core/network/connectivity_service.dart';

/// Whether a request is worth attempting.
///
/// A thin seam over the existing [ConnectivityService] so the networking layer
/// does not depend on it directly — and so tests can drive connectivity without
/// a platform channel.
abstract interface class NetworkChecker {
  /// Best current judgement, answered from cached state.
  Future<bool> get isConnected;
}

/// Backed by the app's [ConnectivityService] (ADR-005: real reachability, not
/// interface-up).
///
/// **Reads cached state; never probes.** `ConnectivityService` establishes
/// reachability with an HTTP probe against our own gateway. Running that before
/// every request would add a full round-trip to every call — doubling latency on
/// exactly the slow links where it hurts most — and would itself be a request,
/// which is circular. The cached verdict, refreshed by connectivity events, is
/// what the pre-flight check consults.
///
/// The cached answer can be stale for a moment, so a request may still be sent
/// into a dead network. That is deliberate and harmless: the request fails and
/// maps to [NetworkException]. The pre-flight check is a fast-path optimisation
/// for the common, obvious offline case, not a correctness guarantee.
class ConnectivityNetworkChecker implements NetworkChecker {
  const ConnectivityNetworkChecker(this._connectivity);

  final ConnectivityService _connectivity;

  @override
  Future<bool> get isConnected async => _connectivity.isOnline;
}

/// Always-online checker for unit tests and for wiring where connectivity is
/// irrelevant.
class AlwaysOnlineNetworkChecker implements NetworkChecker {
  const AlwaysOnlineNetworkChecker();

  @override
  Future<bool> get isConnected async => true;
}
