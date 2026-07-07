import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

/// Local-only reads, exactly like `order`'s `ProductRepository` — the sync
/// engine is the sole path data takes from remote into these tables.
abstract interface class RouteRepository {
  /// Not filtered by rep — the sync engine already scopes what lands
  /// locally to the signed-in rep's territory (`RouteSyncScope`), so every
  /// route that made it into the local DB is relevant to today's dashboard.
  ResultFuture<List<RoutePlan>> fetchTodayRoutes();

  /// Continuous stream of today's routes: emits the current local snapshot on
  /// listen, then re-emits whenever the routes change (a stop is checked
  /// in/out, a status update, or a background sync writes new data) — so the
  /// dashboard stays live without manual reloads.
  Stream<List<RoutePlan>> watchTodayRoutes();

  ResultFuture<RoutePlan> getRoute(String routeId);
  ResultFuture<void> updateRouteStatus(String routeId, RouteStatus status);
  ResultFuture<void> updateStopStatus(
    String stopId, {
    required VisitStatus status,
    DateTime? actualArrival,
    DateTime? actualDeparture,
  });
}
