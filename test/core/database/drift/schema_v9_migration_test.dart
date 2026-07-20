import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/migrations/schema_migrations.dart';

/// Schema v9 — the SAP customer integration relaxed the six `customers` columns
/// the business-partner payload cannot populate (`territory`, `latitude`,
/// `longitude`, `status`, `assigned_rep_id`, `assigned_rep_name`).
///
/// SQLite cannot drop a NOT NULL constraint in place, so the migration recreates
/// the table via `alterTable`. Table recreation is the riskiest kind of
/// migration — it copies every row — so `DATABASE_GUIDE.md` §5 requires proof
/// that nothing is lost or rewritten. That is what this file asserts.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insertCustomer({
    required String id,
    String? territory,
    double? latitude,
    double? longitude,
    String? status,
    String? repId,
    String? repName,
  }) {
    return db.into(db.customers).insert(
          CustomersCompanion.insert(
            id: id,
            sapCustomerId: 'SAP-$id',
            customerCode: 'C-$id',
            shopName: 'Shop $id',
            ownerName: 'Owner',
            phone: '012',
            address: 'Addr',
            province: 'PP',
            district: 'TK',
            creditLimit: 1000,
            updatedAt: DateTime.utc(2026, 7, 20),
            territory: Value(territory),
            latitude: Value(latitude),
            longitude: Value(longitude),
            status: Value(status),
            assignedRepId: Value(repId),
            assignedRepName: Value(repName),
          ),
        );
  }

  test('schema version is 9', () {
    expect(db.schemaVersion, 9);
    expect(kCurrentSchemaVersion, 9);
  });

  test('the six SAP-unavailable columns accept null', () async {
    // The whole point of v9: a customer synced from SAP has none of these.
    await insertCustomer(id: 'sap-only');

    final row = await (db.select(db.customers)
          ..where((t) => t.id.equals('sap-only')))
        .getSingle();

    expect(row.territory, isNull);
    expect(row.latitude, isNull);
    expect(row.longitude, isNull);
    expect(row.status, isNull);
    expect(row.assignedRepId, isNull);
    expect(row.assignedRepName, isNull);
  });

  test('pre-v9 rows keep their values — the change is widening only', () async {
    // A row written before v9 had all six populated. Relaxing a constraint must
    // not rewrite or drop any of them.
    await insertCustomer(
      id: 'legacy',
      territory: 'Phnom Penh',
      latitude: 11.55,
      longitude: 104.91,
      status: 'active',
      repId: 'rep-1',
      repName: 'Sok Dara',
    );

    final row = await (db.select(db.customers)
          ..where((t) => t.id.equals('legacy')))
        .getSingle();

    expect(row.territory, 'Phnom Penh');
    expect(row.latitude, 11.55);
    expect(row.longitude, 104.91);
    expect(row.status, 'active');
    expect(row.assignedRepId, 'rep-1');
    expect(row.assignedRepName, 'Sok Dara');

    // Columns outside the v9 change must be untouched by the recreation.
    expect(row.shopName, 'Shop legacy');
    expect(row.creditLimit, 1000);
    expect(row.deleted, isFalse);
  });

  test('populated and null rows coexist after the relaxation', () async {
    // The realistic post-migration state: legacy mock-seeded rows alongside
    // freshly SAP-synced ones.
    await insertCustomer(id: 'legacy', territory: 'PP', latitude: 11.5);
    await insertCustomer(id: 'from-sap');

    final rows = await db.select(db.customers).get();
    expect(rows, hasLength(2));
    expect(rows.where((r) => r.territory != null), hasLength(1));
    expect(rows.where((r) => r.territory == null), hasLength(1));
  });

  test('indexed nullable columns remain queryable', () async {
    // territory/status/assigned_rep_id all carry indexes. A nullable indexed
    // column still filters correctly, and NULLs are excluded by `equals`.
    await insertCustomer(id: 'a', territory: 'PP', status: 'active');
    await insertCustomer(id: 'b');

    final matched = await (db.select(db.customers)
          ..where((t) => t.territory.equals('PP')))
        .get();

    expect(matched.map((r) => r.id), ['a']);
  });
}
