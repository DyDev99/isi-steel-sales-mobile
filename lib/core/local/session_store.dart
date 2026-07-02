import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';

/// Persists the signed-in user in the encrypted Hive box. Self-contained
/// (de)serialisation — depends only on the domain [User], so it stays valid
/// regardless of how your data-layer models look.
abstract interface class SessionStore {
  /// Synchronous — Hive holds the open box in memory, so guards can read
  /// the restored user without awaiting.
  User? readUser();
  Future<void> writeUser(User user);
  Future<void> clear();
}

class HiveSessionStore implements SessionStore {
  const HiveSessionStore(this._box);
  final Box<dynamic> _box;

  static const String _kUser = 'session.user';

  @override
  User? readUser() {
    final raw = _box.get(_kUser);
    if (raw is! String || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return User(
        id: map['id'] as String? ?? '',
        email: map['email'] as String? ?? '',
        fullName: map['fullName'] as String? ?? '',
        roles: ((map['roles']) as List<dynamic>?)
                ?.map((e) => UserRole.values.byName(e as String))
                .toSet() ??
            {},
        company: map['company'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
      );
    } catch (_) {
      // Corrupt payload — drop it rather than crash on launch.
      _box.delete(_kUser);
      return null;
    }
  }

  @override
  Future<void> writeUser(User user) => _box.put(
        _kUser,
        jsonEncode({
          'id': user.id,
          'email': user.email,
          'fullName': user.fullName,
          'roles': user.roles.map((e) => e.name).toList(), // Fixed syntax error here
          'company': user.company,
          'avatarUrl': user.avatarUrl,
        }),
      );

  @override
  Future<void> clear() => _box.delete(_kUser);
}