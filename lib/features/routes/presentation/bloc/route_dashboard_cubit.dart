import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_dashboard_summary.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/services/geofence_service.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/fetch_today_routes.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/route_dashboard_state.dart';

class RouteDashboardCubit extends Cubit<RouteDashboardState> {
  RouteDashboardCubit({required FetchTodayRoutes fetchTodayRoutes})
      : _fetchTodayRoutes = fetchTodayRoutes,
        super(const RouteDashboardLoading());

  final FetchTodayRoutes _fetchTodayRoutes;

  Future<void> load() async {
    emit(const RouteDashboardLoading());
    final result = await _fetchTodayRoutes(const NoParams());
    result.when(
      success: (routes) => emit(RouteDashboardLoaded(routes: routes, summary: _summarize(routes))),
      failure: (f) => emit(RouteDashboardError(f.message)),
    );
  }

  RouteDashboardSummary _summarize(List<RoutePlan> routes) {
    final allStops = routes.expand((r) => r.stops).toList();
    final completed = allStops.where((s) => s.status == VisitStatus.checkedOut).length;
    final missed = allStops.where((s) => s.status == VisitStatus.missed).length;

    var distanceKm = 0.0;
    var visitMinutes = 0;
    for (final route in routes) {
      for (var i = 0; i < route.stops.length; i++) {
        final stop = route.stops[i];
        if (stop.actualArrival != null && stop.actualDeparture != null) {
          visitMinutes += stop.actualDeparture!.difference(stop.actualArrival!).inMinutes;
        }
        if (i > 0) {
          final prev = route.stops[i - 1].customer;
          distanceKm += GeofenceService.distanceMeters(
                prev.latitude,
                prev.longitude,
                stop.customer.latitude,
                stop.customer.longitude,
              ) /
              1000;
        }
      }
    }

    return RouteDashboardSummary(
      stopsToday: allStops.length,
      completed: completed,
      remaining: allStops.length - completed - missed,
      missed: missed,
      progress: allStops.isEmpty ? 0 : completed / allStops.length,
      totalDistanceKm: distanceKm,
      drivingTimeMinutes: 0,
      visitTimeMinutes: visitMinutes,
      totalCollections: 0,
      totalOrders: 0,
      totalSalesValue: 0,
      successRate: allStops.isEmpty ? 0 : completed / allStops.length,
    );
  }
}
