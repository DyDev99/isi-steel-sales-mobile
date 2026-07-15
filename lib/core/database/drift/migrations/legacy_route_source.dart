import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;

/// Read/erase access to the legacy **plaintext** `routes.db` (T1.5).
///
/// A seam, not indirection for its own sake: `sqflite` is platform-channel
/// based and cannot open a database on the host test VM, so without this the
/// import's mapping and reconciliation rules — the parts that can actually lose
/// a rep's data — would be untestable outside an integration run. Reading rows
/// out of SQLite is the thin part; deciding what happens to them is not.
///
/// This interface is deliberately raw-map-shaped rather than model-shaped: the
/// legacy schema is frozen history, and giving it typed models would imply it
/// still deserves maintenance. It gets deleted once the import is verified.
abstract interface class LegacyRouteSource {
  /// False on a fresh install that never ran the sqflite build — the import is
  /// then a no-op, not an error.
  Future<bool> exists();

  Future<List<Map<String, Object?>>> readTable(String table);

  /// Deletes every row of [table]. Used only after the import is verified
  /// (`docs/MIGRATION_PLAN.md` T1.5: "old plaintext files purged after verified
  /// import").
  Future<void> deleteAllRows(String table);

  Future<void> close();
}

/// The real source, backed by the legacy plaintext `routes.db` file.
class SqfliteLegacyRouteSource implements LegacyRouteSource {
  SqfliteLegacyRouteSource({this.fileName = 'routes.db'});

  final String fileName;
  sqflite.Database? _db;

  Future<String> _path() async =>
      p.join(await sqflite.getDatabasesPath(), fileName);

  @override
  Future<bool> exists() async => File(await _path()).exists();

  /// Opens **read-only-ish**: no `onCreate`/`onUpgrade` is supplied, so this can
  /// never resurrect or migrate the legacy schema. If the file is gone, opening
  /// would create an empty database — hence the [exists] guard in the importer.
  Future<sqflite.Database> _open() async =>
      _db ??= await sqflite.openDatabase(await _path());

  @override
  Future<List<Map<String, Object?>>> readTable(String table) async {
    final db = await _open();
    // The legacy database self-versioned independently, so a device on an older
    // build may genuinely lack a table. A missing table means "nothing to
    // import", not a failure — but any other error must surface.
    final present = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      [table],
    );
    if (present.isEmpty) return const [];
    return db.query(table);
  }

  @override
  Future<void> deleteAllRows(String table) async {
    final db = await _open();
    await db.delete(table);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
