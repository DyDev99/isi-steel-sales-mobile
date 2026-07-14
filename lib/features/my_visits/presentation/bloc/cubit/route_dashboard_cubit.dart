import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_dashboard_summary.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/watch_today_routes.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/route_dashboard_state.dart';

/// Drives the dashboard off a live [WatchTodayRoutes] stream: emits
/// [RouteDashboardLoading] (→ skeletons) until the first snapshot arrives, then
/// [RouteDashboardLoaded] on every update, and [RouteDashboardError] on a
/// stream error. Check-in/out anywhere in the app pushes through here live.
class RouteDashboardCubit extends Cubit<RouteDashboardState> {
  RouteDashboardCubit({required WatchTodayRoutes watchTodayRoutes})
      : _watchTodayRoutes = watchTodayRoutes,
        super(const RouteDashboardLoading()) {
    _subscribe();
  }

  final WatchTodayRoutes _watchTodayRoutes;
  StreamSubscription<List<RoutePlan>>? _subscription;

  void _subscribe() {
    // Only flash skeletons when we don't already have data on screen.
    if (state is! RouteDashboardLoaded) emit(const RouteDashboardLoading());
    _subscription?.cancel();
    _subscription = _watchTodayRoutes(const NoParams()).listen(
      (routes) => emit(
          RouteDashboardLoaded(routes: routes, summary: _summarize(routes))),
      onError: (Object e) => emit(RouteDashboardError(e.toString())),
    );
  }

  /// Re-attach the stream (re-reads the local cache) — used by pull-to-refresh
  /// after a sync. Keeps the current list visible instead of flashing skeletons.
  Future<void> load() async => _subscribe();

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  RouteDashboardSummary _summarize(List<RoutePlan> routes) {
    final allStops = routes.expand((r) => r.stops).toList();
    final completed =
        allStops.where((s) => s.status == VisitStatus.checkedOut).length;
    final missed = allStops.where((s) => s.status == VisitStatus.missed).length;

    var distanceKm = 0.0;
    var visitMinutes = 0;
    for (final route in routes) {
      for (var i = 0; i < route.stops.length; i++) {
        final stop = route.stops[i];
        if (stop.actualArrival != null && stop.actualDeparture != null) {
          visitMinutes +=
              stop.actualDeparture!.difference(stop.actualArrival!).inMinutes;
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
