import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/route_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/route_telemetry_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/visit_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/syncable_table.dart';

/// DAO query + constraint tests for the route/visit aggregates (T1.5a step 2).
///
/// `docs/ENGINEERING_STANDARD.md` §10 requires new DAOs to ship with query and
/// constraint tests; in-memory Drift keeps them fast on host CI
/// (`docs/DATABASE_GUIDE.md` §8).
void main() {
  late AppDatabase db;
  late RouteDao routeDao;
  late RouteTelemetryDao telemetryDao;
  late VisitDao visitDao;

  final day = DateTime.utc(2026, 7, 15);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    routeDao = db.routeDao;
    telemetryDao = db.routeTelemetryDao;
    visitDao = db.visitDao;
  });

  tearDown(() => db.close());

  Future<void> seedCustomer(String id) => db.into(db.customers).insert(
        CustomersCompanion.insert(
          id: id,
          sapCustomerId: 'SAP-$id',
          customerCode: 'C-$id',
          shopName: 'Shop $id',
          ownerName: 'Owner',
          phone: '012000000',
          address: 'St 271',
          province: 'PP',
          district: 'TK',
          territory: const Value('T1'),
          latitude: const Value(11.55),
          longitude: const Value(104.91),
          creditLimit: 1000,
          status: const Value('active'),
          assignedRepId: const Value('rep-1'),
          assignedRepName: const Value('Rep One'),
          updatedAt: day,
        ),
      );

  RoutesCompanion routeRow(String id, {DateTime? visitDate}) =>
      RoutesCompanion.insert(
        id: id,
        name: 'Route $id',
        repId: 'rep-1',
        repName: 'Rep One',
        territory: 'T1',
        visitDate: visitDate ?? day,
        plannedStart: (visitDate ?? day).add(const Duration(hours: 8)),
        plannedEnd: (visitDate ?? day).add(const Duration(hours: 17)),
        status: 'planned',
      );

  RouteStopsCompanion stopRow(String id, String routeId, String customerId,
          {int sequence = 1}) =>
      RouteStopsCompanion.insert(
        id: id,
        routeId: routeId,
        customerId: customerId,
        sequence: sequence,
        plannedArrival: day.add(const Duration(hours: 9)),
        plannedDeparture: day.add(const Duration(hours: 10)),
        status: 'pending',
      );

  group('RouteDao — day filtering', () {
    test('fetchRoutesForDay returns only that calendar day, ordered by start',
        () async {
      await routeDao.upsertRoutesWithStops([
        RouteWithStops(routeRow('r-today-late', visitDate: day), const []),
        RouteWithStops(
          routeRow('r-tomorrow', visitDate: day.add(const Duration(days: 1))),
          const [],
        ),
      ]);
      // Insert an earlier-starting route to prove ordering, not insertion order.
      await db.into(db.routes).insert(
            routeRow('r-today-early').copyWith(
              plannedStart: Value(day.add(const Duration(hours: 6))),
            ),
          );

      final result = await routeDao.fetchRoutesForDay(day);

      expect(result.map((r) => r.id), ['r-today-early', 'r-today-late']);
    });

    test('a route on the following day is excluded at the boundary', () async {
      await db.into(db.routes).insert(
          routeRow('r-next', visitDate: day.add(const Duration(days: 1))));

      expect(await routeDao.fetchRoutesForDay(day), isEmpty);
    });

    test('soft-deleted routes are hidden from reads', () async {
      await db.into(db.routes).insert(routeRow('r-1'));
      await (db.update(db.routes)..where((t) => t.id.equals('r-1')))
          .write(const RoutesCompanion(deleted: Value(true)));

      expect(await routeDao.fetchRoutesForDay(day), isEmpty);
      expect(await routeDao.getRoute('r-1'), isNull);
    });
  });

  group('RouteDao — sync upsert', () {
    test('stops are replaced wholesale, not merged', () async {
      await seedCustomer('cust-1');
      await routeDao.upsertRoutesWithStops([
        RouteWithStops(routeRow('r-1'), [
          stopRow('s-1', 'r-1', 'cust-1', sequence: 1),
          stopRow('s-2', 'r-1', 'cust-1', sequence: 2),
        ]),
      ]);

      // SAP re-sends the plan with s-2 removed.
      await routeDao.upsertRoutesWithStops([
        RouteWithStops(routeRow('r-1'), [
          stopRow('s-1', 'r-1', 'cust-1', sequence: 1),
        ]),
      ]);

      final stops = await routeDao.fetchStops('r-1');
      expect(
        stops.map((s) => s.id),
        ['s-1'],
        reason: 'a stop the server no longer sends was removed from the plan',
      );
    });

    test('stops come back in visit order', () async {
      await seedCustomer('cust-1');
      await routeDao.upsertRoutesWithStops([
        RouteWithStops(routeRow('r-1'), [
          stopRow('s-2', 'r-1', 'cust-1', sequence: 2),
          stopRow('s-1', 'r-1', 'cust-1', sequence: 1),
        ]),
      ]);

      final stops = await routeDao.fetchStops('r-1');
      expect(stops.map((s) => s.id), ['s-1', 's-2']);
    });
  });

  group('RouteDao — customer reconciliation (T1.5)', () {
    test('route attributes apply to an existing customer only', () async {
      await seedCustomer('cust-1');

      final updated = await routeDao.upsertRouteAttributesOnCustomer(
        'cust-1',
        territoryType: 'urban',
        geofenceRadiusOverride: 150,
      );

      expect(updated, 1);
      final customer = await db.select(db.customers).getSingle();
      expect(customer.territoryType, 'urban');
      expect(customer.geofenceRadiusOverride, 150);
      // The SAP-controlled columns must be untouched by route sync.
      expect(customer.shopName, 'Shop cust-1');
      expect(customer.creditLimit, 1000);
    });

    test(
        'an unknown customer updates nothing and reports 0 rather than throwing',
        () async {
      final updated = await routeDao.upsertRouteAttributesOnCustomer(
        'ghost',
        territoryType: 'rural',
      );

      // Caller treats 0 as "customer directory hasn't synced this yet — skip
      // the stop", not as an error. Route sync may never invent a customer.
      expect(updated, 0);
      expect(await routeDao.customerExists('ghost'), isFalse);
    });

    test('customerExists distinguishes seeded from unknown', () async {
      await seedCustomer('cust-1');

      expect(await routeDao.customerExists('cust-1'), isTrue);
      expect(await routeDao.customerExists('nope'), isFalse);
    });
  });

  group('RouteDao — local mutations mark dirty', () {
    test('updateStopStatus omitting a timestamp leaves the stored value alone',
        () async {
      await seedCustomer('cust-1');
      await routeDao.upsertRoutesWithStops([
        RouteWithStops(routeRow('r-1'), [stopRow('s-1', 'r-1', 'cust-1')]),
      ]);

      final arrival = day.add(const Duration(hours: 9, minutes: 5));
      await routeDao.updateStopStatus('s-1',
          status: 'inProgress', actualArrival: arrival);
      // A later update that only changes status must not wipe the arrival.
      await routeDao.updateStopStatus('s-1', status: 'completed');

      final stop = (await routeDao.fetchStops('r-1')).single;
      expect(stop.status, 'completed');
      expect(stop.actualArrival, arrival);
      expect(stop.dirty, isTrue);
      expect(stop.syncState, SyncStates.dirty);
    });

    test('updateRouteStatus flags the row for push', () async {
      await db.into(db.routes).insert(routeRow('r-1'));

      await routeDao.updateRouteStatus('r-1', 'completed');

      final route = await routeDao.getRoute('r-1');
      expect(route!.status, 'completed');
      expect(route.dirty, isTrue);
    });
  });

  group('RouteDao — delta cursor', () {
    test('last-synced round-trips and upserts idempotently', () async {
      expect(await routeDao.getLastSyncedAt('routes'), isNull);

      await routeDao.setLastSyncedAt('routes', day);
      await routeDao.setLastSyncedAt(
          'routes', day.add(const Duration(days: 1)));

      expect(
        await routeDao.getLastSyncedAt('routes'),
        day.add(const Duration(days: 1)),
      );
    });
  });

  group('RouteTelemetryDao', () {
    LocationSamplesCompanion sample(String id, DateTime at) =>
        LocationSamplesCompanion.insert(
          id: id,
          routeId: 'r-1',
          latitude: 11.55,
          longitude: 104.91,
          accuracy: 5,
          speed: 0,
          heading: 0,
          altitude: 12,
          timestamp: at,
        );

    setUp(() => db.into(db.routes).insert(routeRow('r-1')));

    test('batch insert stores every sample, ordered by time', () async {
      await telemetryDao.insertSamples([
        sample('s-2', day.add(const Duration(hours: 10))),
        sample('s-1', day.add(const Duration(hours: 9))),
      ]);

      final samples = await telemetryDao.fetchSamples('r-1');
      expect(samples.map((s) => s.id), ['s-1', 's-2']);
    });

    test('purge removes synced samples but never unsynced ones', () async {
      await telemetryDao.insertSamples([
        sample('old-synced', day.add(const Duration(hours: 1))),
        sample('old-pending', day.add(const Duration(hours: 2))),
      ]);
      await telemetryDao.markSamplesSynced(['old-synced']);

      final purged = await telemetryDao
          .purgeSyncedSamplesBefore(day.add(const Duration(hours: 5)));

      expect(purged, 1);
      final remaining = await telemetryDao.fetchSamples('r-1');
      expect(
        remaining.map((s) => s.id),
        ['old-pending'],
        reason: 'an unsynced GPS point is unpushed data — never purge it',
      );
    });

    test('markSamplesSynced with an empty list is a no-op', () async {
      await telemetryDao.insertSamples([sample('s-1', day)]);

      await telemetryDao.markSamplesSynced([]);

      expect((await telemetryDao.fetchPendingSamples()), hasLength(1));
    });
  });

  group('VisitDao — captures', () {
    setUp(() async {
      await seedCustomer('cust-1');
      await routeDao.upsertRoutesWithStops([
        RouteWithStops(routeRow('r-1'), [stopRow('s-1', 'r-1', 'cust-1')]),
      ]);
    });

    test('check-in is unique per stop — a second one replaces the first',
        () async {
      await visitDao.upsertCheckIn(VisitCheckInsCompanion.insert(
        id: 'ci-1',
        stopId: 's-1',
        timestamp: day,
        latitude: 11.55,
        longitude: 104.91,
        accuracy: 5,
        distanceFromCustomer: 12,
      ));

      final stored = await visitDao.getCheckIn('s-1');
      expect(stored!.id, 'ci-1');
      expect(stored.syncState, SyncStates.dirty);
    });

    test('countPendingVisitRecords sums every capture table', () async {
      await visitDao.upsertCheckIn(VisitCheckInsCompanion.insert(
        id: 'ci-1',
        stopId: 's-1',
        timestamp: day,
        latitude: 11.55,
        longitude: 104.91,
        accuracy: 5,
        distanceFromCustomer: 12,
      ));
      await visitDao.insertOrderLine(VisitOrderLinesCompanion.insert(
        id: 'ol-1',
        stopId: 's-1',
        productId: 'p-1',
        productName: 'Rebar',
        quantity: 10,
        unit: 'pcs',
        unitPrice: 5,
      ));
      await visitDao.insertNote(VisitNotesCompanion.insert(
        id: 'n-1',
        stopId: 's-1',
        type: 'general',
        body: 'Shop closed early',
        createdAt: day,
      ));

      expect(await visitDao.countPendingVisitRecords(), 3);
    });

    test('markSynced clears only the targeted table', () async {
      await visitDao.insertOrderLine(VisitOrderLinesCompanion.insert(
        id: 'ol-1',
        stopId: 's-1',
        productId: 'p-1',
        productName: 'Rebar',
        quantity: 10,
        unit: 'pcs',
        unitPrice: 5,
      ));
      await visitDao.insertNote(VisitNotesCompanion.insert(
        id: 'n-1',
        stopId: 's-1',
        type: 'general',
        body: 'note',
        createdAt: day,
      ));

      await visitDao.markSynced(VisitCaptureTable.orderLines, ['ol-1']);

      expect(await visitDao.fetchPendingOrderLines(), isEmpty);
      expect(
        await visitDao.fetchPendingNotes(),
        hasLength(1),
        reason: 'marking one table must not touch another',
      );
      expect(await visitDao.countPendingVisitRecords(), 1);
    });

    test('captures cascade away when their stop is deleted', () async {
      await visitDao.insertCollection(VisitCollectionsCompanion.insert(
        id: 'col-1',
        stopId: 's-1',
        amount: 250,
        method: 'cash',
      ));

      await (db.delete(db.routeStops)..where((t) => t.id.equals('s-1'))).go();

      expect(await visitDao.fetchCollections('s-1'), isEmpty);
    });

    test('a capture for an unknown stop is rejected', () async {
      expect(
        () => visitDao.insertReturn(VisitReturnsCompanion.insert(
          id: 'ret-1',
          stopId: 'ghost-stop',
          productId: 'p-1',
          productName: 'Rebar',
          quantity: 1,
          reason: 'damaged',
        )),
        throwsA(isA<Exception>()),
      );
    });
  });
}
