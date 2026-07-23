import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/database/secure/app_database_key_provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

/// Builds the encrypted [LazyDatabase] executor backing the single application
/// database. The connection is opened against SQLCipher (never plain SQLite),
/// keyed with the composite passphrase from [AppDatabaseKeyProvider]
/// (`SHA256(dbSalt + deviceKey)`), and refuses to open at all if encryption is
/// not active or the key is wrong.
///
/// ## One open path, self-healing
///
/// Earlier revisions probed the file with a throwaway connection and then let
/// drift's `NativeDatabase(setup: …)` open it a second time. That left a gap:
/// any divergence between the two opens (probe passes, real open throws
/// `SQLITE_NOTADB`) surfaced as a permanent, per-query
/// "file is not a database (code 26)" that the recovery logic never saw.
/// Now there is exactly **one** open: the raw connection is opened, keyed, and
/// verified here, then handed to drift via [NativeDatabase.opened] — so a
/// wrong-key file is always detected at the same place it is healed.
LazyDatabase openEncryptedDatabase(AppDatabaseKeyProvider keyProvider) {
  return LazyDatabase(() async {
    await _ensureSqlCipherLoaded();

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, AppConstants.encryptedDbFileName));
    final passphrase = await keyProvider.databasePassphrase();

    Database raw;
    try {
      raw = _openAndVerify(file, passphrase);
    } on SqliteException catch (e) {
      // `SQLITE_NOTADB` (26) means the file's header does not decrypt with the
      // composite key we hold. The dominant real-world cause: a backup/restore
      // or reinstall that kept the encrypted file but lost the Keystore-sealed
      // device key (Keystore entries are never backed up), so a brand-new key
      // meets an old file. That data is cryptographically unrecoverable — and
      // the local DB is a re-syncable cache (ADR-002) — so the only correct
      // move is to start clean and let sync repopulate. All sync watermarks
      // live inside this same file, so deleting it also resets them
      // consistently and the next sync is a full initial pull.
      //
      // Deliberately narrow: only result code 26 triggers deletion. Any other
      // failure (wrong cipher build, I/O error, genuine corruption mid-session)
      // still fails closed exactly as before.
      if (e.resultCode != 26 && e.extendedResultCode != 26) rethrow;
      _deleteDatabaseFiles(file);
      // Fresh file — this open creates it and must succeed; if it throws,
      // something other than a stale key is wrong and we fail closed.
      raw = _openAndVerify(file, passphrase);
    }

    return NativeDatabase.opened(raw);
  });
}

/// Opens [file], applies the SQLCipher key, and runs both fail-closed checks.
/// Throws (closing the handle first) if encryption is not active or the key
/// does not decrypt the file.
Database _openAndVerify(File file, String passphrase) {
  final db = sqlite3.open(file.path);
  try {
    // Supply the passphrase as a raw key ("x'...'"): the value is already
    // 256 bits of CSPRNG output, so SQLCipher's PBKDF2 derivation is skipped.
    // Must run before any other statement touches the file.
    db.execute('PRAGMA key = "x\'$passphrase\'";');

    // Fail closed #1: if plain sqlite3 (no cipher) somehow loaded, this
    // pragma returns no rows — we must not silently write plaintext.
    final cipher = db.select('PRAGMA cipher_version;');
    if (cipher.isEmpty || (cipher.first.values.first as String).isEmpty) {
      throw StateError(
        'SQLCipher is not active — refusing to open an unencrypted database.',
      );
    }

    // Fail closed #2: touching sqlite_master forces SQLCipher to decrypt the
    // header now, so a wrong/rotated key throws here at open time rather than
    // on the first feature query.
    db.select('SELECT count(*) FROM sqlite_master;');
    return db;
  } catch (_) {
    db.dispose();
    rethrow;
  }
}

/// Removes the database file and every SQLite sidecar so the next open starts
/// from a clean slate.
void _deleteDatabaseFiles(File file) {
  for (final suffix in const ['', '-wal', '-shm', '-journal']) {
    final sidecar = File('${file.path}$suffix');
    if (sidecar.existsSync()) sidecar.deleteSync();
  }
}

/// Ensures the sqlite3 symbols resolve to the bundled SQLCipher build on every
/// supported platform. Idempotent — safe to call on each open.
Future<void> _ensureSqlCipherLoaded() async {
  // Some old Android versions need SQLCipher's libraries opened up front.
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

  // On iOS/macOS SQLCipher is statically linked into the process, so its
  // symbols are found via the running process image.
  if (Platform.isIOS) {
    open.overrideFor(OperatingSystem.iOS, DynamicLibrary.process);
  } else if (Platform.isMacOS) {
    open.overrideFor(OperatingSystem.macOS, DynamicLibrary.process);
  }
}
