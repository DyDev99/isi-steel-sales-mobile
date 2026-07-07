import 'dart:async';

import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/route_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  RouteRepositoryImpl(this._local);
  final RouteLocalDataSource _local;

  /// Broadcast hub for live route updates. Mutations push a fresh local
  /// snapshot here so any active [watchTodayRoutes] listener updates instantly.
  final StreamController<List<RoutePlan>> _routesController =
      StreamController<List<RoutePlan>>.broadcast();

  @override
  ResultFuture<List<RoutePlan>> fetchTodayRoutes() async {
    try {
      return Success(await _local.fetchTodayRoutes());
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  Stream<List<RoutePlan>> watchTodayRoutes() async* {
    // Immediate local snapshot (may throw CacheException → surfaces as a stream
    // error the cubit maps to RouteDashboardError), then live updates.
    yield await _local.fetchTodayRoutes();
    yield* _routesController.stream;
  }

  /// Re-read the local cache and broadcast it to listeners. Called after any
  /// mutation so open screens (e.g. the dashboard) reflect the change live.
  Future<void> _broadcastTodayRoutes() async {
    if (!_routesController.hasListener) return;
    try {
      _routesController.add(await _local.fetchTodayRoutes());
    } on CacheException {
      // Keep the last good snapshot on a transient read error.
    }
  }

  @override
  ResultFuture<RoutePlan> getRoute(String routeId) async {
    try {
      final route = await _local.getRoute(routeId);
      if (route == null) return const Failed(CacheFailure(message: 'Route not found.'));
      return Success(route);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> updateRouteStatus(String routeId, RouteStatus status) async {
    try {
      await _local.updateRouteStatus(routeId, status);
      unawaited(_broadcastTodayRoutes());
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> updateStopStatus(
    String stopId, {
    required VisitStatus status,
    DateTime? actualArrival,
    DateTime? actualDeparture,
  }) async {
    try {
      await _local.updateStopStatus(
        stopId,
        status: status,
        actualArrival: actualArrival,
        actualDeparture: actualDeparture,
      );
      unawaited(_broadcastTodayRoutes());
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }
}
