import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_drift_mappers.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_plan_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_stop_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/territory_type.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

/// Parity tests for the T1.5 route cutover.
///
/// Asserts the **interface contract**, not the implementation: swapping
/// plaintext sqflite for the encrypted Drift database must be invisible above
/// the datasource (ADR-003 seam). An expectation that had to bend to fit Drift
/// would mean the refactor changed behaviour (`playbook` §8).
void main() {
  late AppDatabase db;
  late RouteDriftLocalDataSource dataSource;

  const logger = ConsoleAppLogger(verbose: false);
  final today = DateTime.now().toUtc();
  final todayMidnight = DateTime.utc(today.year, today.month, today.day);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = RouteDriftLocalDataSource(db.routeDao, logger);
  });

  tearDown(() => db.close());

  Future<void> seedCustomer(
    String id, {
    String? territoryType,
    double? geofence,
  }) =>
      db.into(db.customers).insert(
            CustomersCompanion.insert(
              id: id,
              sapCustomerId: Value('SAP-$id'),
              customerCode: 'C-$id',
              shopName: 'ISI Hardware',
              ownerName: 'Sok Dara',
              phone: '012345678',
              address: 'St 271',
              province: 'PP',
              district: 'TK',
              territory: 'T1',
              latitude: 11.55,
              longitude: 104.91,
              creditLimit: 5000,
              status: 'active',
              assignedRepId: 'rep-1',
              assignedRepName: 'Rep One',
              updatedAt: todayMidnight,
              territoryType: Value(territoryType),
              geofenceRadiusOverride: Value(geofence),
            ),
          );

  CustomerStopInfoModel stopCustomer(String id) => CustomerStopInfoModel(
        id: id,
        name: 'ISI Hardware',
        code: 'C-$id',
        contact: 'Sok Dara',
        phone: '012345678',
        address: 'St 271',
        territory: 'T1',
        territoryType: TerritoryType.industrial,
        latitude: 11.55,
        longitude: 104.91,
        geofenceRadiusOverride: 150,
      );

  RoutePlanModel plan(String id, {List<RouteStopModel> stops = const []}) =>
      RoutePlanModel(
        id: id,
        name: 'North loop',
        repId: 'rep-1',
        repName: 'Rep One',
        territory: 'T1',
        visitDate: todayMidnight,
        plannedStart: todayMidnight.add(const Duration(hours: 8)),
        plannedEnd: todayMidnight.add(const Duration(hours: 17)),
        status: RouteStatus.published,
        stops: stops,
      );

  RouteStopModel stop(String id, String routeId, String customerId) =>
      RouteStopModel(
        id: id,
        routeId: routeId,
        customer: stopCustomer(customerId),
        sequence: 1,
        plannedArrival: todayMidnight.add(const Duration(hours: 9)),
        plannedDeparture: todayMidnight.add(const Duration(hours: 10)),
        status: VisitStatus.pending,
      );

  group('round-trip', () {
    test('a route with a stop survives upsert → fetch with fields intact',
        () async {
      // The route feed carries its own customer rows (ADR-011); the customer
      // directory is deliberately left empty to prove the stop does not
      // depend on it having synced first.
      await dataSource.upsertCustomers([stopCustomer('cust-1')]);
      await dataSource.upsertRoutes([
        plan('r-1', stops: [stop('s-1', 'r-1', 'cust-1')]),
      ]);

      final routes = await dataSource.fetchTodayRoutes();

      expect(routes, hasLength(1));
      final route = routes.single;
      expect(route.id, 'r-1');
      expect(route.name, 'North loop');
      expect(route.status, RouteStatus.published);
      expect(route.stops, hasLength(1));

      // The stop carries the customer the route feed sent for it, joined
      // from `route_customers` rather than the customer directory.
      final s = route.stops.single;
      expect(s.id, 's-1');
      expect(s.customer.id, 'cust-1');
      expect(s.customer.name, 'ISI Hardware');
      expect(s.customer.contact, 'Sok Dara');
      expect(s.customer.territoryType, TerritoryType.industrial);
      expect(s.customer.geofenceRadiusOverride, 150);
    });

    test('getRoute returns null for an unknown id rather than throwing',
        () async {
      expect(await dataSource.getRoute('ghost'), isNull);
    });

    test('a route on another day is not in today\'s list', () async {
      await dataSource.upsertRoutes([
        RoutePlanModel(
          id: 'r-past',
          name: 'Yesterday',
          repId: 'rep-1',
          repName: 'Rep One',
          territory: 'T1',
          visitDate: todayMidnight.subtract(const Duration(days: 1)),
          plannedStart: todayMidnight.subtract(const Duration(days: 1)),
          plannedEnd: todayMidnight.subtract(const Duration(hours: 8)),
          status: RouteStatus.published,
          stops: const [],
        ),
      ]);

      expect(await dataSource.fetchTodayRoutes(), isEmpty);
    });
  });

  group('local mutations', () {
    setUp(() async {
      await dataSource.upsertCustomers([stopCustomer('cust-1')]);
      await dataSource.upsertRoutes([
        plan('r-1', stops: [stop('s-1', 'r-1', 'cust-1')]),
      ]);
    });

    test('updateRouteStatus persists and is readable back', () async {
      await dataSource.updateRouteStatus('r-1', RouteStatus.completed);

      expect((await dataSource.getRoute('r-1'))!.status, RouteStatus.completed);
    });

    test('updateStopStatus records arrival and keeps it on a later update',
        () async {
      final arrival = todayMidnight.add(const Duration(hours: 9, minutes: 5));

      await dataSource.updateStopStatus('s-1',
          status: VisitStatus.checkedIn, actualArrival: arrival);
      await dataSource.updateStopStatus('s-1', status: VisitStatus.checkedOut);

      final s = (await dataSource.getRoute('r-1'))!.stops.single;
      expect(s.status, VisitStatus.checkedOut);
      expect(
        s.actualArrival,
        arrival,
        reason: 'omitting a timestamp must not wipe a recorded arrival',
      );
    });
  });

  group('the route feed stores its own customers (ADR-011)', () {
    // Reverses the T1.5 behaviour this group used to assert. Route sync then
    // applied two attributes onto customers the directory already held and
    // *skipped* the rest, on the grounds that the directory is the single
    // source of truth. That held for ownership but not for availability: the
    // two feeds are separate endpoints with separate scopes, so "not in the
    // directory yet" is routine — and skipping meant the stop had no customer
    // to render.

    test('a customer the directory has never seen is stored and usable',
        () async {
      await dataSource.upsertCustomers([stopCustomer('ghost')]);

      final stored = await db.select(db.routeCustomers).getSingle();
      expect(stored.id, 'ghost');
      expect(stored.name, 'ISI Hardware');
      expect(stored.territoryType, 'industrial');
      expect(stored.geofenceRadiusOverride, 150);
    });

    test('the customer directory is left completely alone', () async {
      await seedCustomer('cust-1');

      await dataSource.upsertCustomers([stopCustomer('cust-1')]);

      // Route sync must never write the directory: different feed, different
      // owner, and CLAUDE.md §4 forbids reaching into another feature's data.
      final c = await db.select(db.customers).getSingle();
      expect(c.shopName, 'ISI Hardware');
      expect(c.creditLimit, 5000);
      expect(c.territoryType, isNull,
          reason: 'route sync no longer mutates the customer directory');
    });
  });

  group('geofence fallback — fails closed', () {
    test('a stop with no customer row at all falls back to the tightest radius',
        () async {
      // The feed sent the stop but not its customer — a contract violation the
      // device must survive. The stop is still rendered (ADR-011: never drop
      // it), and the unknown location fails closed rather than widening a
      // fraud control.
      await dataSource.upsertRoutes([
        plan('r-1', stops: [stop('s-1', 'r-1', 'cust-1')]),
      ]);

      final s = (await dataSource.fetchTodayRoutes()).single.stops.single;

      expect(s.customer.territoryType, kUnknownTerritoryFallback);
      expect(
        s.customer.territoryType.defaultGeofenceRadiusMeters,
        50,
        reason: 'unknown territory must not silently widen a fraud control',
      );
    });

    test('an unrecognised territory value also falls back', () async {
      // Written straight to the mirror table: a server that gains a new
      // territory type must not crash a build that has not shipped yet.
      await db.customStatement(
        'INSERT INTO route_customers (id, name, name_kh, code, contact, '
        'phone, address, territory, territory_type, latitude, longitude) '
        "VALUES ('cust-1','ISI Hardware','','C-cust-1','Sok Dara','012345678',"
        "'St 271','T1','atlantis',11.55,104.91)",
      );
      await dataSource.upsertRoutes([
        plan('r-1', stops: [stop('s-1', 'r-1', 'cust-1')]),
      ]);

      final s = (await dataSource.fetchTodayRoutes()).single.stops.single;
      expect(s.customer.territoryType, kUnknownTerritoryFallback);
    });
  });

  group('sync cursor', () {
    test('round-trips and overwrites', () async {
      expect(await dataSource.getLastSyncedAt('routes'), isNull);

      await dataSource.setLastSyncedAt('routes', todayMidnight);
      await dataSource.setLastSyncedAt(
          'routes', todayMidnight.add(const Duration(hours: 1)));

      expect(await dataSource.getLastSyncedAt('routes'),
          todayMidnight.add(const Duration(hours: 1)));
    });
  });
}
