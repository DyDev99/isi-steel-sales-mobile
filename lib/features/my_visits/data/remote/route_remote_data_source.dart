import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/route_sync_page.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_sync_scope.dart';

/// SAP/route-planner-shaped sync source. [MockRouteRemoteDataSource] is the
/// only implementation today, backed by generated `assets/mock/routes.json`
/// — a real implementation (route-planning backend, SAP, etc.) is a
/// drop-in replacement behind this interface.
abstract interface class RouteRemoteDataSource {
  Future<RouteSyncPage> fetchInitial({required RouteSyncScope scope, required int page, required int pageSize});

  /// The per-rep route set is small by design (a handful of routes/day),
  /// unlike the product catalog's 17k+ rows — so unlike
  /// `MockProductRemoteDataSource`'s randomized delta, this simply re-pulls
  /// the rep's current scoped route/customer set. Still guarded by the same
  /// `since`-driven sync-meta watermark at the repository layer.
  Future<RouteSyncPage> fetchDelta({required RouteSyncScope scope, required DateTime since});
}
