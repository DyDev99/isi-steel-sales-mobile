import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/migrations/schema_migrations.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/syncable_table.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Covers the T1.5 schema landing (v7/v8): the route + visit-capture tables
/// ported off the plaintext `routes.db` into the single encrypted database
/// (ADR-001).
///
/// `docs/DATABASE_GUIDE.md` §5 requires every migration step to ship with a test
/// that runs the upgrade against a fixture of the *previous* schema version and
/// asserts data survives intact — migrations are proven before merge, not
/// discovered broken in the field. That is the `v6 → v8 upgrade` group below.
///
/// Runs on an in-memory/temp-file `NativeDatabase` (no SQLCipher) so it works on
/// host CI; the cipher wrapper is covered on-device separately.
void main() {
  group('v8 schema — route + visit tables exist after onCreate', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    // Deliberately a literal, not `kCurrentSchemaVersion` on both sides: this
    // assertion exists to make a version bump a conscious act. Bumped to 9 by
    // the SAP customer integration, which relaxed the six `customers` columns
    // the business-partner payload cannot populate.
    test('schema version is 9', () async {
      expect(db.schemaVersion, 9);
      expect(kCurrentSchemaVersion, 9);
    });

    test('every ported table is created', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table';")
          .get();
      final tables = rows.map((r) => r.data['name'] as String).toSet();

      expect(
        tables,
        containsAll([
          // v7 — route domain
          'routes', 'route_stops', 'location_samples', 'fraud_flags',
          'route_sync_meta',
          // v8 — visit captures
          'visit_check_ins', 'visit_check_outs', 'visit_order_lines',
          'visit_stock_updates', 'visit_returns', 'visit_collections',
          'visit_notes', 'visit_photos',
        ]),
      );
    });

    test('customers absorbs the two route-execution columns', () async {
      final rows = await db.customSelect('PRAGMA table_info(customers);').get();
      final columns = rows.map((r) => r.data['name'] as String).toSet();

      expect(
          columns, containsAll(['territory_type', 'geofence_radius_override']));
    });
  });

  group('referential integrity — the win ADR-001 was adopted for', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> insertRoute(String id) => db.into(db.routes).insert(
          RoutesCompanion.insert(
            id: id,
            name: 'R1',
            repId: 'rep-1',
            repName: 'Rep',
            territory: 'T1',
            visitDate: DateTime.utc(2026, 7, 15),
            plannedStart: DateTime.utc(2026, 7, 15, 8),
            plannedEnd: DateTime.utc(2026, 7, 15, 17),
            status: 'planned',
          ),
        );

    test('a stop referencing an unknown customer is rejected', () async {
      await insertRoute('route-1');

      // Impossible to enforce under the old three-plaintext-database split:
      // stops and customers lived in different files. The T1.5 import must
      // therefore reconcile orphans rather than blind-copy.
      expect(
        () => db.into(db.routeStops).insert(
              RouteStopsCompanion.insert(
                id: 'stop-1',
                routeId: 'route-1',
                customerId: 'ghost-customer',
                sequence: 1,
                plannedArrival: DateTime.utc(2026, 7, 15, 9),
                plannedDeparture: DateTime.utc(2026, 7, 15, 10),
                status: 'pending',
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('a stop referencing an unknown route is rejected', () async {
      expect(
        () => db.into(db.routeStops).insert(
              RouteStopsCompanion.insert(
                id: 'stop-1',
                routeId: 'ghost-route',
                customerId: 'ghost-customer',
                sequence: 1,
                plannedArrival: DateTime.utc(2026, 7, 15, 9),
                plannedDeparture: DateTime.utc(2026, 7, 15, 10),
                status: 'pending',
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting a route cascades to its GPS trail', () async {
      await insertRoute('route-1');
      await db.into(db.locationSamples).insert(
            LocationSamplesCompanion.insert(
              id: 'sample-1',
              routeId: 'route-1',
              latitude: 11.55,
              longitude: 104.91,
              accuracy: 5,
              speed: 0,
              heading: 0,
              altitude: 12,
              timestamp: DateTime.utc(2026, 7, 15, 9),
            ),
          );

      await (db.delete(db.routes)..where((t) => t.id.equals('route-1'))).go();

      expect(await db.select(db.locationSamples).get(), isEmpty);
    });
  });

  group('syncable columns (DATABASE_GUIDE §3.1)', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('a locally-created row defaults to dirty and not-yet-synced',
        () async {
      await db.into(db.routes).insert(
            RoutesCompanion.insert(
              id: 'route-1',
              name: 'R1',
              repId: 'rep-1',
              repName: 'Rep',
              territory: 'T1',
              visitDate: DateTime.utc(2026, 7, 15),
              plannedStart: DateTime.utc(2026, 7, 15, 8),
              plannedEnd: DateTime.utc(2026, 7, 15, 17),
              status: 'planned',
            ),
          );

      final row = await db.select(db.routes).getSingle();

      // A row written locally has by definition not reached SAP yet.
      expect(row.syncState, SyncStates.dirty);
      expect(row.dirty, isTrue);
      expect(row.deleted, isFalse);
      expect(row.serverRevision, isNull);
      expect(row.updatedAt, isNotNull);
    });

    test('the schema default literal still matches SyncStates.dirty', () {
      // Guards the deliberate literal in SyncableTable.syncState: Drift copies
      // that expression into app_database.g.dart, which cannot import
      // SyncStates. If someone renames the constant, this fails instead of the
      // schema silently defaulting to a stale value.
      expect(SyncStates.dirty, 'dirty');
    });
  });

  group('legacy sync_status mapping (T1.5 import)', () {
    test("'pending' maps to dirty", () {
      expect(SyncStates.fromLegacy('pending'), SyncStates.dirty);
    });

    test('null maps to dirty rather than assuming synced', () {
      expect(SyncStates.fromLegacy(null), SyncStates.dirty);
    });

    test('an unknown value maps to dirty — re-push is safe, data loss is not',
        () {
      expect(SyncStates.fromLegacy('weird'), SyncStates.dirty);
    });

    test('known canonical values round-trip', () {
      expect(SyncStates.fromLegacy('synced'), SyncStates.synced);
      expect(SyncStates.fromLegacy('syncing'), SyncStates.syncing);
      expect(SyncStates.fromLegacy('conflict'), SyncStates.conflict);
    });
  });

  group('v6 → v8 upgrade preserves data (DATABASE_GUIDE §5)', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isi_migration_test');
      dbFile = File(p.join(tempDir.path, 'app.db'));
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    /// Fabricates a v6 database on disk.
    ///
    /// No historical v6 snapshot exists (schema dumps were never captured), so
    /// v6 is reconstructed from the current schema by removing exactly what v7
    /// and v8 add, then rewinding `user_version`. This keeps the fixture honest
    /// — the base tables are Drift's own DDL, not a hand-written approximation
    /// that could drift from reality.
    Future<void> createV6Fixture() async {
      final setup = AppDatabase(NativeDatabase(dbFile));
      await setup.customStatement('SELECT 1;'); // force open → onCreate (v8)
      await setup.close();

      final raw = sqlite.sqlite3.open(dbFile.path);
      for (final table in [
        'visit_photos',
        'visit_notes',
        'visit_collections',
        'visit_returns',
        'visit_stock_updates',
        'visit_order_lines',
        'visit_check_outs',
        'visit_check_ins',
        'fraud_flags',
        'location_samples',
        'route_stops',
        'route_sync_meta',
        'routes',
      ]) {
        raw.execute('DROP TABLE IF EXISTS $table;');
      }
      raw.execute('ALTER TABLE customers DROP COLUMN territory_type;');
      raw.execute(
          'ALTER TABLE customers DROP COLUMN geofence_radius_override;');
      raw.execute('PRAGMA user_version = 6;');
      raw.dispose();
    }

    test('an existing customer survives the upgrade with new columns null',
        () async {
      await createV6Fixture();

      // Seed a v6 customer, as a real device would have.
      final raw = sqlite.sqlite3.open(dbFile.path);
      raw.execute('''
        INSERT INTO customers (
          id, sap_customer_id, customer_code, shop_name, owner_name, phone,
          address, province, district, territory, latitude, longitude,
          credit_limit, status, assigned_rep_id, assigned_rep_name, updated_at
        ) VALUES (
          'cust-1', 'SAP-1', 'C-001', 'ISI Hardware', 'Sok Dara', '012345678',
          'St 271', 'Phnom Penh', 'Toul Kork', 'T1', 11.55, 104.91,
          5000.0, 'active', 'rep-1', 'Rep One', '2026-07-15T00:00:00.000Z'
        );
      ''');
      raw.dispose();

      // Re-open through Drift → triggers onUpgrade 6 → 8.
      final db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(db.close);

      final customer = await db.select(db.customers).getSingle();

      // The upgrade must not lose the row or any of its data.
      expect(customer.id, 'cust-1');
      expect(customer.shopName, 'ISI Hardware');
      expect(customer.creditLimit, 5000.0);
      // Newly-added columns are null for pre-existing rows, by design.
      expect(customer.territoryType, isNull);
      expect(customer.geofenceRadiusOverride, isNull);
    });

    test('upgrade creates the route/visit tables and records the registry',
        () async {
      await createV6Fixture();

      final db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(db.close);

      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table';")
          .get();
      final tables = rows.map((r) => r.data['name'] as String).toSet();

      expect(tables, containsAll(['routes', 'route_stops', 'visit_check_ins']));
      expect(
        await db.appMetadataDao.getValue(SchemaMetadataKeys.schemaVersion),
        '9',
      );
      expect(
        await db.appMetadataDao.getValue(SchemaMetadataKeys.lastMigratedFrom),
        '6',
      );
    });

    test('the upgraded database still accepts writes to the new tables',
        () async {
      await createV6Fixture();

      final db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(db.close);

      await db.into(db.routes).insert(
            RoutesCompanion.insert(
              id: 'route-1',
              name: 'R1',
              repId: 'rep-1',
              repName: 'Rep',
              territory: 'T1',
              visitDate: DateTime.utc(2026, 7, 15),
              plannedStart: DateTime.utc(2026, 7, 15, 8),
              plannedEnd: DateTime.utc(2026, 7, 15, 17),
              status: 'planned',
            ),
          );

      expect(await db.select(db.routes).get(), hasLength(1));
    });
  });
}
