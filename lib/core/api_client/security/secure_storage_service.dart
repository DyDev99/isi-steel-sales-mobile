import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// One API surface over the platform Keychain/Keystore.
///
/// Only three classes of value may be stored here, per `docs/SECURITY.md` §3:
/// bearer tokens, the credentials needed to mint them, and the database
/// encryption device key. Business data belongs in the encrypted Drift database;
/// non-sensitive preferences belong in Hive. Secure storage is small, slow and
/// backed by hardware — using it as a general cache both degrades it and hides
/// business data from the migration and backup rules that govern the database.
///
/// **Consolidation note.** `core/database/secure/secure_storage.dart` is a
/// deliberately-empty stub reserving this same responsibility
/// (`docs/MIGRATION_PLAN.md` §8, P1). This class now fills that role for the
/// networking layer. The two should become one when that task is picked up —
/// having two façades over the same store is the fragmentation the stub exists
/// to prevent, so the duplication is called out here rather than left to be
/// discovered.
abstract interface class SecureStorageService {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<Map<String, dynamic>?> readJson(String key);
  Future<void> writeJson(String key, Map<String, dynamic> value);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> contains(String key);
}

class FlutterSecureStorageService implements SecureStorageService {
  const FlutterSecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await read(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      // A corrupt entry must not wedge the app permanently. Drop it and let the
      // caller treat it as absent — which for a token means re-authenticating,
      // a recoverable state, rather than throwing on every launch.
      await delete(key);
      return null;
    }
  }

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) =>
      write(key, jsonEncode(value));

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();

  @override
  Future<bool> contains(String key) => _storage.containsKey(key: key);
}

/// Storage keys, centralised so two subsystems cannot silently pick the same
/// string and overwrite one another.
abstract final class SecureStorageKeys {
  const SecureStorageKeys._();

  static const String sapSession = 'sap_session';
  static const String sapCredentials = 'sap_credentials';
  static const String isiSession = 'isi_session';
}
