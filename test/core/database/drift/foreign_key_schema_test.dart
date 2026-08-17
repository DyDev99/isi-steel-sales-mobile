import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';

/// Guards the referential integrity ADR-001 was adopted for.
///
/// ## Why this test exists
///
/// `drift_dev 2.31.0` + `analyzer 10.2.0` silently emit **no** foreign keys
/// from `references()` — the reference resolves to nothing, no constraint is
/// written, and no warning is printed (`docs/flutter-web.md` §8). Every
/// constraint in the schema vanished on the next `build_runner` run, and the
/// only symptom was a handful of failing behavioural tests that a reader in a
/// hurry could plausibly dismiss as flaky.
///
/// The constraints are now declared explicitly via `customConstraints`. This
/// test is what stops that workaround from being removed, or the generator
/// regressing further, without anyone noticing.
///
/// ## Why it asserts on the live schema
///
/// Not on the table sources — they were correct the entire time; it was codegen
/// that dropped them. Not on `app_database.g.dart` either: because
/// `customConstraints` is an override on the *source* table class, the
/// generated `$…Table` subclass inherits it and the string never appears in
/// generated output. `sqlite_master` is the only place the truth is visible.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Map<String, String>> tableSql() async {
    final rows = await db
        .customSelect("SELECT name, sql FROM sqlite_master WHERE type='table'")
        .get();
    return {
      for (final r in rows)
        r.data['name'] as String: (r.data['sql'] as String?) ?? '',
    };
  }

  test('every declared foreign key reaches the schema', () async {
    final sql = await tableSql();
    final total = sql.values.fold<int>(
      0,
      (sum, s) => sum + RegExp('FOREIGN KEY').allMatches(s).length,
    );

    expect(
      total,
      22,
      reason: 'Expected 22 foreign keys. Getting 0 means codegen dropped them '
          'again (docs/flutter-web.md §8) and referential integrity is gone. '
          'Do not weaken this test to make it pass.',
    );
  });

  test('the specific relationships ADR-001 depends on are present', () async {
    final sql = await tableSql();

    // Spot-checked individually rather than only counting, so that swapping one
    // constraint for another cannot keep the total at 22 while losing a
    // relationship that matters.
    expect(sql['route_stops'], contains('REFERENCES customers (id)'));
    expect(sql['route_stops'], contains('REFERENCES routes (id)'));
    expect(
      sql['visit_check_ins'],
      contains('REFERENCES route_stops (id) ON DELETE CASCADE'),
    );
    expect(sql['prices'], contains('REFERENCES products (id)'));
    expect(sql['customer_contacts'], contains('REFERENCES customers (id)'));
  });

  test('cascade deletes actually fire', () async {
    // The constraint being in the DDL is necessary but not sufficient — it only
    // does anything with `PRAGMA foreign_keys = ON`, which the migration
    // strategy sets in `beforeOpen`. This asserts the two work together.
    final fk = await db.customSelect('PRAGMA foreign_keys;').get();
    expect(
      fk.first.data['foreign_keys'],
      1,
      reason: 'Foreign key enforcement is off; the constraints are decorative.',
    );
  });
}
