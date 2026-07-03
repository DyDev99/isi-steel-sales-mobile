import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/route_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  const RouteRepositoryImpl(this._local);
  final RouteLocalDataSource _local;

  @override
  ResultFuture<List<RoutePlan>> fetchTodayRoutes() async {
    try {
      return Success(await _local.fetchTodayRoutes());
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
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
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }
}
