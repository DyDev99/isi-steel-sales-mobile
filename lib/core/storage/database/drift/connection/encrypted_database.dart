import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/storage/secure/app_database_key_provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

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
