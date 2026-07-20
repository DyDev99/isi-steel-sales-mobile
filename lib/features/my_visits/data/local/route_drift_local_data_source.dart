import 'package:isi_steel_sales_mobile/core/database/drift/daos/route_dao.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_drift_mappers.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_plan_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

/// [RouteLocalDataSource] backed by the single encrypted Drift database
/// (T1.5 cutover). Replaces the plaintext `routes.db` implementation.
///
/// The interface is unchanged, so the repository, usecases and blocs above are
/// untouched by the storage swap (ADR-003 seam, `docs/ARCHITECTURE.md` §5).
class RouteDriftLocalDataSource implements RouteLocalDataSource {
  const RouteDriftLocalDataSource(this._dao, this._logger);

  final RouteDao _dao;
  final AppLogger _logger;

  @override
  Future<List<RoutePlanModel>> fetchTodayRoutes() async {
    try {
      final routes = await _dao.fetchRoutesForDay(DateTime.now().toUtc());
      // Sequential rather than concurrent: a rep has a handful of routes per
      // day, and serialising keeps the read off a connection-contention path.
      final plans = <RoutePlanModel>[];
      for (final route in routes) {
        plans.add(route.toModel(await _stopsFor(route.id)));
      }
      return plans;
    } catch (e) {
      throw CacheException(message: 'Failed to load today\'s routes: $e');
    }
  }

  @override
  Future<List<RoutePlanModel>> fetchAllRoutes() async {
    try {
      final routes = await _dao.fetchAllRoutes();
      final plans = <RoutePlanModel>[];
      for (final route in routes) {
        plans.add(route.toModel(await _stopsFor(route.id)));
      }
      return plans;
    } catch (e) {
      throw CacheException(message: 'Failed to load all routes: $e');
    }
  }

  @override
  Future<RoutePlanModel?> getRoute(String routeId) async {
    try {
      final route = await _dao.getRoute(routeId);
      if (route == null) return null;
      return route.toModel(await _stopsFor(routeId));
    } catch (e) {
      throw CacheException(message: 'Failed to load route: $e');
    }
  }

  Future<List<RouteStop>> _stopsFor(String routeId) async {
    final joined = await _dao.fetchStopsWithCustomers(routeId);
    return joined.map((row) => row.toModel()).toList();
  }

  @override
  Future<void> updateRouteStatus(String routeId, RouteStatus status) async {
    try {
      await _dao.updateRouteStatus(routeId, status.name);
    } catch (e) {
      throw CacheException(message: 'Failed to update route status: $e');
    }
  }

  @override
  Future<void> updateStopStatus(
    String stopId, {
    required VisitStatus status,
    DateTime? actualArrival,
    DateTime? actualDeparture,
  }) async {
    try {
      await _dao.updateStopStatus(
        stopId,
        status: status.name,
        actualArrival: actualArrival,
        actualDeparture: actualDeparture,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to update stop status: $e');
    }
  }

  /// Applies route-execution attributes to customers the directory already has.
  ///
  /// **Behaviour change, made deliberately (T1.5).** The legacy implementation
  /// inserted these rows into `routes.db`'s own `customers` table, so route sync
  /// could invent a customer. It can no longer: `customers` in the encrypted
  /// database is SAP-controlled and owned by the customer directory sync
  /// (ADR-001, single source of truth), and `route_stops.customer_id` is a real
  /// FK to it.
  ///
  /// The consequence is an ordering dependency — customer sync must run before
  /// route sync — which is exactly the direction `docs/ARCHITECTURE.md` §4's
  /// dependency graph already mandates (Customer sits above Route). An unknown
  /// customer is logged and skipped rather than invented; the next customer sync
  /// pulls it, and the following route sync attaches its stops.
  @override
  Future<void> upsertCustomers(List<CustomerStopInfoModel> customers) async {
    try {
      var unknown = 0;
      for (final customer in customers) {
        final updated = await _dao.upsertRouteAttributesOnCustomer(
          customer.id,
          territoryType: customer.territoryType.name,
          geofenceRadiusOverride: customer.geofenceRadiusOverride,
        );
        if (updated == 0) unknown++;
      }
      if (unknown > 0) {
        // §10: a count, never an identifier.
        _logger.warning('route_sync.customers_not_in_directory',
            fields: {'count': unknown});
      }
    } catch (e) {
      throw CacheException(message: 'Failed to upsert route customers: $e');
    }
  }

  @override
  Future<void> upsertRoutes(List<RoutePlanModel> routes) async {
    try {
      await _dao.upsertRoutesWithStops(
        routes
            .map((r) => RouteWithStops(r.toCompanion(), r.toStopCompanions()))
            .toList(),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to upsert routes: $e');
    }
  }

  @override
  Future<DateTime?> getLastSyncedAt(String entity) async {
    try {
      return await _dao.getLastSyncedAt(entity);
    } catch (e) {
      throw CacheException(message: 'Failed to read sync cursor: $e');
    }
  }

  @override
  Future<void> setLastSyncedAt(String entity, DateTime at) async {
    try {
      await _dao.setLastSyncedAt(entity, at);
    } catch (e) {
      throw CacheException(message: 'Failed to write sync cursor: $e');
    }
  }
}
