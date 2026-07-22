import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/migrations/schema_migrations.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Covers schema v9: the SAP sales-area and commercial columns added to
/// `customers` so the directory can be filtered by Sales Organization and
/// Division, and so the mock datasource can later be swapped for a real SAP one
/// without another schema change (ADR-009).
///
/// `docs/DATABASE_GUIDE.md` §5 requires every migration step to ship with a test
/// that upgrades a fixture of the *previous* version and proves data survives.
/// That is the `v8 → v9` group below.
///
/// Runs on a plain `NativeDatabase` (no SQLCipher) so it works on host CI.
void main() {
  group('v9 schema — SAP columns exist after onCreate', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('registry constant is 9', () {
      expect(kCurrentSchemaVersion, 9);
    });

    test('customers carries every new SAP column', () async {
      final rows = await db.customSelect('PRAGMA table_info(customers);').get();
      final columns = rows.map((r) => r.data['name'] as String).toSet();

      expect(
        columns,
        containsAll([
          'sales_org',
          'division',
          'distribution_channel',
          'customer_group',
          'price_group',
          'en_name',
          'kh_name',
          'credit_balance',
          'currency',
          'tax_number',
          'total_orders',
          'created_at',
          'sync_state',
        ]),
      );
    });

    test('the sales-area filter indexes exist', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='index';")
          .get();
      final indexes = rows.map((r) => r.data['name'] as String).toSet();

      // Without these, filtering a large directory by sales area degrades to a
      // full table scan (DATABASE_GUIDE.md §3).
      expect(indexes,
          containsAll(['idx_customers_sales_org', 'idx_customers_division']));
    });

    test('defaults are sane for a row that supplies none of them', () async {
      await db.into(db.customers).insert(
            CustomersCompanion.insert(
              id: 'c1',
              sapCustomerId: 'SAP-1',
              customerCode: 'C-001',
              shopName: 'Shop',
              ownerName: 'Owner',
              phone: '012',
              address: 'St 1',
              province: 'Phnom Penh',
              district: 'Chamkarmon',
              // These six became nullable in the SAP cutover (SAP does not
              // always supply them), so `insert` now takes Value<T?> rather
              // than a bare T.
              territory: const Value('PP'),
              latitude: const Value(11.5),
              longitude: const Value(104.9),
              creditLimit: 0,
              status: const Value('active'),
              assignedRepId: const Value('r1'),
              assignedRepName: const Value('Rep'),
              updatedAt: DateTime.utc(2026, 7, 21),
            ),
          );

      final row = await db.select(db.customers).getSingle();

      expect(row.creditBalance, 0);
      expect(row.currency, 'USD');
      expect(row.totalOrders, 0);
      expect(row.syncState, 'synced');
      // Sales area is genuinely unknown until SAP supplies it — null, not ''.
      expect(row.salesOrg, isNull);
      expect(row.division, isNull);
    });
  });

  group('v8 → v9 upgrade preserves data (DATABASE_GUIDE §5)', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isi_v9_migration_test');
      dbFile = File(p.join(tempDir.path, 'app.db'));
    });

    tearDown(() async {
      // Windows keeps a lock on the file briefly after close; a failed cleanup
      // of a temp directory must not mask the assertion that actually ran.
      try {
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      } on FileSystemException {
        // Best-effort — the OS reclaims the temp dir.
      }
    });

    /// Fabricates a v8 database on disk.
    ///
    /// Same approach as the v6 fixture in `route_visit_schema_migration_test`:
    /// build the current schema with Drift's own DDL, then remove exactly what
    /// v9 adds and rewind `user_version`. Keeps the fixture honest rather than
    /// hand-writing DDL that could drift from reality.
    Future<void> createV8Fixture() async {
      final setup = AppDatabase(NativeDatabase(dbFile));
      await setup.customStatement('SELECT 1;'); // force open → onCreate (v9)
      await setup.close();

      final raw = sqlite.sqlite3.open(dbFile.path);
      // Indexes must go first: SQLite refuses to drop a column that an index
      // still references ("error in index ... after drop column").
      raw.execute('DROP INDEX IF EXISTS idx_customers_sales_org;');
      raw.execute('DROP INDEX IF EXISTS idx_customers_division;');
      for (final column in [
        'sales_org',
        'division',
        'distribution_channel',
        'customer_group',
        'price_group',
        'payment_terms',
        'en_name',
        'kh_name',
        'credit_balance',
        'currency',
        'tax_number',
        'total_orders',
        'created_at',
        'sync_state',
      ]) {
        raw.execute('ALTER TABLE customers DROP COLUMN $column;');
      }
      raw.execute('PRAGMA user_version = 8;');
      raw.dispose();
    }

    /// Seeds a customer exactly as a v8 device would hold it.
    void seedV8Customer() {
      final raw = sqlite.sqlite3.open(dbFile.path);
      raw.execute('''
        INSERT INTO customers (
          id, sap_customer_id, customer_code, shop_name, owner_name, phone,
          address, province, district, territory, latitude, longitude,
          credit_limit, status, assigned_rep_id, assigned_rep_name, updated_at,
          lifetime_value
        ) VALUES (
          'cust-1', 'SAP-1', 'C-001', 'ISI Hardware', 'Sok Dara', '012345678',
          'St 271', 'Phnom Penh', 'Toul Kork', 'T1', 11.55, 104.91,
          5000.0, 'active', 'rep-1', 'Rep One', '2026-07-15T00:00:00.000Z',
          12345.67
        );
      ''');
      raw.dispose();
    }

    test('an existing customer survives with all v8 data intact', () async {
      await createV8Fixture();
      seedV8Customer();

      // Re-open through Drift → triggers onUpgrade 8 → 9.
      final db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(db.close);

      final customer = await db.select(db.customers).getSingle();

      // Nothing the user already had may be lost or altered.
      expect(customer.id, 'cust-1');
      expect(customer.sapCustomerId, 'SAP-1');
      expect(customer.shopName, 'ISI Hardware');
      expect(customer.ownerName, 'Sok Dara');
      expect(customer.creditLimit, 5000.0);
      expect(customer.lifetimeValue, 12345.67);
      expect(customer.province, 'Phnom Penh');
    });

    test('new SAP columns come back null/defaulted for pre-existing rows',
        () async {
      await createV8Fixture();
      seedV8Customer();

      final db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(db.close);

      final customer = await db.select(db.customers).getSingle();

      // A v8 row has no sales area — it must read as unknown, not as a
      // misleading empty string that would match a filter.
      expect(customer.salesOrg, isNull);
      expect(customer.division, isNull);
      expect(customer.distributionChannel, isNull);
      expect(customer.enName, isNull);
      expect(customer.taxNumber, isNull);
      // Defaulted columns take their declared default.
      expect(customer.creditBalance, 0);
      expect(customer.currency, 'USD');
      expect(customer.totalOrders, 0);
      expect(customer.syncState, 'synced');
    });

    test('the upgrade records the version registry', () async {
      await createV8Fixture();

      final db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(db.close);

      expect(
        await db.appMetadataDao.getValue(SchemaMetadataKeys.schemaVersion),
        '9',
      );
      expect(
        await db.appMetadataDao.getValue(SchemaMetadataKeys.lastMigratedFrom),
        '8',
      );
    });

    test('the upgraded database accepts writes to the new columns', () async {
      await createV8Fixture();
      seedV8Customer();

      final db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(db.close);

      await (db.update(db.customers)..where((t) => t.id.equals('cust-1')))
          .write(
        const CustomersCompanion(
          salesOrg: Value('PRD'),
          division: Value('STEEL'),
        ),
      );

      final customer = await db.select(db.customers).getSingle();
      expect(customer.salesOrg, 'PRD');
      expect(customer.division, 'STEEL');
    });

    test('the sales-area indexes are created by the upgrade, not just onCreate',
        () async {
      await createV8Fixture();

      final db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(db.close);

      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='index';")
          .get();
      final indexes = rows.map((r) => r.data['name'] as String).toSet();

      expect(indexes,
          containsAll(['idx_customers_sales_org', 'idx_customers_division']));
    });
  });
}
