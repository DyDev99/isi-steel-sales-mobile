import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/migrations/schema_migrations.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// v20 → v21: `customer_sync_meta.synced_language`.
///
/// The column records which `Accept-Language` the cached customer book was
/// fetched under. `shopName` is localised **server-side** and the list summary
/// carries no language-independent name, so a book pulled under `km-KH` holds
/// Khmer names — and a delta cannot repair that, because `modifiedSince`
/// returns what the *server* changed and switching language on the phone
/// changes nothing there.
///
/// Additive and nullable, so the migration must preserve the existing watermark
/// untouched: an upgrade that lost it would trigger a needless full re-page of
/// every customer on every installed device.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isi_v21_migration');
    dbFile = File(p.join(tempDir.path, 'app.db'));
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// Builds a v20 database from the current schema by dropping exactly what v21
  /// adds, then rewinding `user_version`. The base tables are Drift's own DDL,
  /// so the fixture cannot drift from what ships.
  Future<void> createV20Fixture({String? watermark}) async {
    final setup = AppDatabase(NativeDatabase(dbFile));
    await setup.customStatement('SELECT 1;');
    await setup.close();

    final raw = sqlite.sqlite3.open(dbFile.path);
    raw.execute('DROP TABLE customer_sync_meta;');
    raw.execute('CREATE TABLE customer_sync_meta ('
        'entity TEXT NOT NULL, last_synced_at TEXT NULL, '
        'PRIMARY KEY (entity));');
    if (watermark != null) {
      raw.execute(
        "INSERT INTO customer_sync_meta (entity, last_synced_at) "
        "VALUES ('customers', ?)",
        [watermark],
      );
    }
    raw.execute('PRAGMA user_version = 20;');
    raw.dispose();
  }

  test('the upgrade runs and lands on v21', () async {
    await createV20Fixture();

    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version;').getSingle();
    expect(version.data['user_version'], 21);
  });

  test('an existing watermark survives, with the language left unknown',
      () async {
    await createV20Fixture(watermark: '2026-08-28T08:31:52.000Z');

    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    final row = await db
        .customSelect("SELECT last_synced_at, synced_language "
            "FROM customer_sync_meta WHERE entity = 'customers'")
        .getSingle();

    expect(row.data['last_synced_at'], '2026-08-28T08:31:52.000Z',
        reason: 'losing the watermark would force every installed device '
            'through a full re-page of every customer');
    expect(row.data['synced_language'], isNull,
        reason: 'null reads as "unknown", which the sync repository treats as '
            'a match rather than forcing a gratuitous resync on upgrade');
  });

  test('the upgraded table accepts a language', () async {
    await createV20Fixture(watermark: '2026-08-28T08:31:52.000Z');

    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    await db.customerDao.setLastSyncedAt(
      'customers',
      DateTime.utc(2026, 8, 28, 9),
      language: 'km-KH',
    );

    expect(await db.customerDao.getSyncedLanguage('customers'), 'km-KH');
  });

  test('a fresh install lands on v21 with the column present', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.customerDao.setLastSyncedAt(
      'customers',
      DateTime.utc(2026, 8, 28),
      language: 'en-US',
    );

    expect(await db.customerDao.getSyncedLanguage('customers'), 'en-US');
  });

  test('the migration step is registered for the current version', () {
    // The pin, handed on from `geo_v19_to_v20_migration_test.dart`.
    //
    // `kCurrentSchemaVersion` and the step map are edited in two places, and
    // bumping one without the other silently skips the migration for every
    // existing installation. Move this pin — and add the step — together, with
    // the next schema change.
    expect(kCurrentSchemaVersion, 21);
  });
}
