import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/location_tracking_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/watch_today_routes.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/stop_dashboard_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/today_stop.dart';

/// Drives the Stop Dashboard: flattens today's routes ([WatchTodayRoutes]) into
/// per-stop view models, sorts them **nearest-first** by live GPS distance, and
/// keeps the order fresh as the rep moves — re-sorting only past a movement
/// threshold to avoid churn and battery drain.
///
/// Offline-first: stops come from the local Drift stream; distance/sort/search
/// are all computed locally, so the screen works with zero connectivity.
class StopDashboardCubit extends Cubit<StopDashboardState> {
  StopDashboardCubit({
    required WatchTodayRoutes watchTodayRoutes,
    required LocationTrackingService locationService,
  })  : _watchTodayRoutes = watchTodayRoutes,
        _locationService = locationService,
        super(const StopDashboardLoading());

  final WatchTodayRoutes _watchTodayRoutes;
  final LocationTrackingService _locationService;

  StreamSubscription<List<RoutePlan>>? _routesSub;
  StreamSubscription<LocationSample>? _positionSub;

  /// Only re-sort when the rep has moved at least this far since the last sort —
  /// keeps the list stable and avoids recomputing 500+ distances on every fix.
  static const double _resortThresholdMeters = 50;

  List<RoutePlan> _routes = const [];
  List<TodayStop> _sorted = const [];
  LocationSample? _position;
  LocationSample? _lastSortPosition;
  StopFilter _filter = StopFilter.all;
  String _query = '';
  bool _locating = true;
  bool _locationDenied = false;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _routesSub = _watchTodayRoutes(const NoParams()).listen(
      _onRoutes,
      onError: (Object e) => emit(StopDashboardError(e.toString())),
    );

    final granted = await _locationService.ensurePermission();
    if (!granted) {
      _locationDenied = true;
      _locating = false;
      _emitLoaded();
      return;
    }
    _positionSub = _locationService
        .observe(distanceFilterMeters: 25)
        .listen(_onPosition, onError: (Object _) {});
  }

  void _onRoutes(List<RoutePlan> routes) {
    _routes = routes;
    _sorted = _flatten();
    _emitLoaded();
  }

  void _onPosition(LocationSample sample) {
    final movedEnough = _lastSortPosition == null ||
        GeofenceService.distanceMeters(
              _lastSortPosition!.latitude,
              _lastSortPosition!.longitude,
              sample.latitude,
              sample.longitude,
            ) >=
            _resortThresholdMeters;

    _position = sample;
    _locating = false;

    if (movedEnough) {
      _lastSortPosition = sample;
      _sorted = _flatten(); // recompute distances + nearest-first order
    }
    _emitLoaded();
  }

  /// Flattens today's routes to [TodayStop]s, stamping each with live distance
  /// and sorting nearest-first (falls back to route/sequence order with no fix).
  List<TodayStop> _flatten() {
    final pos = _position;
    final list = <TodayStop>[];
    for (final route in _routes) {
      for (final stop in route.stops) {
        final distance = pos == null
            ? null
            : GeofenceService.distanceMeters(pos.latitude, pos.longitude,
                stop.customer.latitude, stop.customer.longitude);
        list.add(TodayStop(
          stop: stop,
          routeId: route.id,
          routeName: route.name,
          distanceMeters: distance,
        ));
      }
    }
    if (pos == null) {
      list.sort((a, b) {
        final byRoute = a.routeName.compareTo(b.routeName);
        return byRoute != 0
            ? byRoute
            : a.stop.sequence.compareTo(b.stop.sequence);
      });
    } else {
      list.sort((a, b) => (a.distanceMeters ?? double.infinity)
          .compareTo(b.distanceMeters ?? double.infinity));
    }
    return list;
  }

  StopDashboardSummary _summarize() {
    final total = _sorted.length;
    var completed = 0;
    var remaining = 0;
    for (final s in _sorted) {
      if (s.stop.status == VisitStatus.checkedOut) {
        completed++;
      } else if (s.stop.status != VisitStatus.missed) {
        remaining++;
      }
    }

    // Nearest actionable stop (skip done/skipped); falls back to the first.
    TodayStop? nearest;
    for (final s in _sorted) {
      if (s.stop.status != VisitStatus.checkedOut &&
          s.stop.status != VisitStatus.missed) {
        nearest = s;
        break;
      }
    }
    nearest ??= _sorted.isEmpty ? null : _sorted.first;

    // Total distance along the visiting order (user → nearest → …), km.
    var totalKm = 0.0;
    final pos = _position;
    if (pos != null && _sorted.isNotEmpty) {
      var prevLat = pos.latitude;
      var prevLng = pos.longitude;
      for (final s in _sorted) {
        totalKm += GeofenceService.distanceMeters(prevLat, prevLng,
                s.stop.customer.latitude, s.stop.customer.longitude) /
            1000;
        prevLat = s.stop.customer.latitude;
        prevLng = s.stop.customer.longitude;
      }
    }

    return StopDashboardSummary(
      total: total,
      completed: completed,
      remaining: remaining,
      nearestName: nearest?.stop.customer.name,
      nearestDistanceMeters: nearest?.distanceMeters,
      totalDistanceKm: totalKm,
      totalTravelMinutes: totalKm <= 0 ? 0 : (totalKm / 25 * 60).round(),
    );
  }

  void _emitLoaded() {
    emit(StopDashboardLoaded(
      stops: _sorted,
      summary: _summarize(),
      filter: _filter,
      query: _query,
      position: _position,
      locating: _locating,
      locationDenied: _locationDenied,
    ));
  }

  void setFilter(StopFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    if (state is StopDashboardLoaded) _emitLoaded();
  }

  void setQuery(String query) {
    if (_query == query) return;
    _query = query;
    if (state is StopDashboardLoaded) _emitLoaded();
  }

  @override
  Future<void> close() {
    _routesSub?.cancel();
    _positionSub?.cancel();
    _locationService.stopObserving();
    return super.close();
  }
}
