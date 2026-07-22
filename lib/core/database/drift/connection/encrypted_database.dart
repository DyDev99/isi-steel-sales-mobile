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
LazyDatabase openEncryptedDatabase(AppDatabaseKeyProvider keyProvider) {
  return LazyDatabase(() async {
    await _ensureSqlCipherLoaded();

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, AppConstants.encryptedDbFileName));
    final passphrase = await keyProvider.databasePassphrase();

    _recoverIfUndecryptable(file, passphrase);

    return NativeDatabase(
      file,
      setup: (rawDb) {
        // Supply the passphrase as a raw key ("x'...'"): the value is already
        // 256 bits of CSPRNG output, so SQLCipher's PBKDF2 derivation is
        // skipped. Must run before any other statement touches the file.
        rawDb.execute('PRAGMA key = "x\'$passphrase\'";');

        // Fail closed #1: if plain sqlite3 (no cipher) somehow loaded, this
        // pragma returns no rows — we must not silently write plaintext.
        final cipher = rawDb.select('PRAGMA cipher_version;');
        if (cipher.isEmpty || (cipher.first.values.first as String).isEmpty) {
          throw StateError(
            'SQLCipher is not active — refusing to open an unencrypted database.',
          );
        }

        // Fail closed #2: touching sqlite_master forces SQLCipher to decrypt
        // the header now, so a wrong/rotated key throws here at open time
        // rather than on the first feature query.
        rawDb.execute('SELECT count(*) FROM sqlite_master;');
      },
    );
  });
}

/// Deletes a database file that cannot be decrypted with the current key, so
/// the app heals itself instead of failing on every query forever.
///
/// `SQLITE_NOTADB` (26) at open time means the file's header does not decrypt
/// with the composite key we hold. The dominant real-world cause: Android
/// Auto Backup restoring the encrypted file onto a fresh install whose
/// Keystore-sealed device key did not survive the uninstall (Keystore entries
/// are never backed up), so a brand-new key meets an old file. That data is
/// cryptographically unrecoverable — and the local DB is a re-syncable cache
/// (ADR-002) — so the only correct move is to start clean and let sync
/// repopulate. All sync watermarks live inside this same file, so deleting it
/// also resets them consistently and the next sync is a full initial pull.
///
/// Backup is now disabled in the manifest (`android:allowBackup="false"`);
/// this probe is the second line of defense for devices that already restored
/// a stale file, or that lose their Keystore any other way (OS restore,
/// "clear credentials", vendor Keystore bugs).
///
/// Deliberately narrow: only result code 26 triggers deletion. Any other
/// failure (wrong cipher build, I/O error, genuine corruption mid-session)
/// still fails closed exactly as before.
void _recoverIfUndecryptable(File file, String passphrase) {
  if (!file.existsSync()) return;
  try {
    final probe = sqlite3.open(file.path);
    try {
      probe.execute('PRAGMA key = "x\'$passphrase\'";');
      probe.select('SELECT count(*) FROM sqlite_master;');
    } finally {
      probe.dispose();
    }
  } on SqliteException catch (e) {
    if (e.resultCode != 26 && e.extendedResultCode != 26) rethrow;
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      final sidecar = File('${file.path}$suffix');
      if (sidecar.existsSync()) sidecar.deleteSync();
    }
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
