import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/local/routes_database.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/models/route_plan_model.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/models/route_stop_model.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_status.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class RouteLocalDataSource {
  Future<List<RoutePlanModel>> fetchTodayRoutes();
  Future<RoutePlanModel?> getRoute(String routeId);
  Future<void> updateRouteStatus(String routeId, RouteStatus status);
  Future<void> updateStopStatus(
    String stopId, {
    required VisitStatus status,
    DateTime? actualArrival,
    DateTime? actualDeparture,
  });

  Future<void> upsertCustomers(List<CustomerStopInfoModel> customers);
  Future<void> upsertRoutes(List<RoutePlanModel> routes);

  Future<DateTime?> getLastSyncedAt(String entity);
  Future<void> setLastSyncedAt(String entity, DateTime at);
}

class RouteLocalDataSourceImpl implements RouteLocalDataSource {
  const RouteLocalDataSourceImpl(this._routesDb);
  final RoutesDatabase _routesDb;
  Database get _db => _routesDb.db;

  Future<RoutePlanModel> _composeRoute(DataMap routeRow) async {
    final stopRows = await _db.query('stops', where: 'route_id = ?', whereArgs: [routeRow['id']], orderBy: 'sequence ASC');
    if (stopRows.isEmpty) {
      return RoutePlanModel.fromRow(routeRow, stops: const []);
    }

    final customerIds = stopRows.map((s) => s['customer_id'] as String).toSet().toList();
    final placeholders = List.filled(customerIds.length, '?').join(',');
    final customerRows = await _db.query('customers', where: 'id IN ($placeholders)', whereArgs: customerIds);
    final customersById = {
      for (final row in customerRows) row['id'] as String: CustomerStopInfoModel.fromRow(row),
    };

    final stops = stopRows
        .where((row) => customersById.containsKey(row['customer_id']))
        .map((row) => RouteStopModel.fromRow(row, customer: customersById[row['customer_id']]!))
        .toList();

    return RoutePlanModel.fromRow(routeRow, stops: stops);
  }

  @override
  Future<List<RoutePlanModel>> fetchTodayRoutes() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final routeRows = await _db.query(
        'routes',
        where: 'substr(visit_date, 1, 10) = ?',
        whereArgs: [dateStr],
        orderBy: 'planned_start ASC',
      );
      final routes = <RoutePlanModel>[];
      for (final row in routeRows) {
        routes.add(await _composeRoute(row));
      }
      return routes;
    } catch (e) {
      throw CacheException(message: 'Failed to load routes: $e');
    }
  }

  @override
  Future<RoutePlanModel?> getRoute(String routeId) async {
    try {
      final rows = await _db.query('routes', where: 'id = ?', whereArgs: [routeId], limit: 1);
      if (rows.isEmpty) return null;
      return _composeRoute(rows.first);
    } catch (e) {
      throw CacheException(message: 'Failed to load route $routeId: $e');
    }
  }

  @override
  Future<void> updateRouteStatus(String routeId, RouteStatus status) async {
    try {
      await _db.update('routes', {'status': status.name}, where: 'id = ?', whereArgs: [routeId]);
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
      final values = <String, Object?>{'status': status.name};
      if (actualArrival != null) values['actual_arrival'] = actualArrival.toIso8601String();
      if (actualDeparture != null) values['actual_departure'] = actualDeparture.toIso8601String();
      await _db.update('stops', values, where: 'id = ?', whereArgs: [stopId]);
    } catch (e) {
      throw CacheException(message: 'Failed to update stop status: $e');
    }
  }

  @override
  Future<void> upsertCustomers(List<CustomerStopInfoModel> customers) async {
    try {
      final batch = _db.batch();
      for (final c in customers) {
        batch.insert('customers', c.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw CacheException(message: 'Failed to save customers: $e');
    }
  }

  @override
  Future<void> upsertRoutes(List<RoutePlanModel> routes) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();
        for (final route in routes) {
          batch.insert('routes', route.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
          for (final stop in route.stops) {
            batch.insert(
              'stops',
              (stop as RouteStopModel).toRow(),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw CacheException(message: 'Failed to save synced routes: $e');
    }
  }

  @override
  Future<DateTime?> getLastSyncedAt(String entity) async {
    try {
      final rows = await _db.query('sync_meta', where: 'entity = ?', whereArgs: [entity]);
      if (rows.isEmpty) return null;
      final raw = rows.first['last_synced_at'] as String?;
      return raw == null ? null : DateTime.parse(raw);
    } catch (e) {
      throw CacheException(message: 'Failed to read sync metadata: $e');
    }
  }

  @override
  Future<void> setLastSyncedAt(String entity, DateTime at) async {
    try {
      await _db.insert(
        'sync_meta',
        {'entity': entity, 'last_synced_at': at.toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to write sync metadata: $e');
    }
  }
}
