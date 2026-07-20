import 'package:isi_steel_sales_mobile/core/api_client/auth/auth_session.dart';
import 'package:isi_steel_sales_mobile/core/api_client/security/secure_storage_service.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';

/// Local persistence for the signed-in user.
///
/// **Tokens are deliberately not here.** The bearer token, its expiry and the
/// credentials needed to renew it are owned by `TokenManager`
/// (`core/api_client/auth/`), which is the single source of truth the auth
/// interceptor reads on every request. Storing a second copy in this feature is
/// how the two drift apart — the previous implementation did exactly that,
/// keeping its own `accessToken`/`refreshToken` keys alongside the interceptor's.
///
/// What remains here is the *profile* — who is signed in — which the session
/// manager and role guards need and the networking layer does not.
abstract interface class AuthLocalDataSource {
  Future<void> cacheUser(User user);
  Future<User?> readUser();
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._storage);

  final SecureStorageService _storage;

  /// The profile lives in secure storage rather than Hive because it carries a
  /// username and role — identity data, not a display preference
  /// (`docs/SECURITY.md` §3).
  static const _userKey = 'auth_user';

  @override
  Future<void> cacheUser(User user) async {
    try {
      await _storage.writeJson(_userKey, {
        'id': user.id,
        'email': user.email,
        'fullName': user.fullName,
        'roles': user.roles.map((r) => r.name).toList(),
        'company': user.company,
        'avatarUrl': user.avatarUrl,
      });
    } on Object {
      throw const CacheException(message: 'Failed to persist the session.');
    }
  }

  @override
  Future<User?> readUser() async {
    final json = await _storage.readJson(_userKey);
    if (json == null) return null;

    final id = json['id'] as String?;
    if (id == null || id.isEmpty) return null;

    final rawRoles = json['roles'];
    final roles = rawRoles is List
        ? rawRoles
            .whereType<String>()
            .map(_roleFromName)
            .whereType<UserRole>()
            .toSet()
        : <UserRole>{};

    return User(
      id: id,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? id,
      // An empty role set would make `primaryRole` fall back to guest, which is
      // the safe direction: a corrupted entry must not imply admin.
      roles: roles,
      company: json['company'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  @override
  Future<void> clear() => _storage.delete(_userKey);

  static UserRole? _roleFromName(String name) {
    for (final role in UserRole.values) {
      if (role.name == name) return role;
    }
    // An unknown persisted role is dropped rather than guessed — see
    // `SapRoleMapper` for the same reasoning at the network boundary.
    return null;
  }
}

/// Re-exported so the repository can talk about sessions without importing the
/// networking layer's path directly.
typedef AuthSessionSnapshot = AuthSession;
