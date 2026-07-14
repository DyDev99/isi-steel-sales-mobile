import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/middleware/app_middleware.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/auth_token_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/user_model.dart';

abstract interface class AuthLocalDataSource {
  Future<void> cacheSession({
    required AuthTokenModel token,
    required UserModel user,
  });
  Future<UserModel?> readUser();
  Future<AuthTokenModel?> readToken();
  Future<void> clear();
}

/// Backed by encrypted secure storage. Also implements [TokenStore] so the
/// same instance can serve the network interceptor — one source of truth
/// for tokens, no duplication or drift.
class AuthLocalDataSourceImpl implements AuthLocalDataSource, TokenStore {
  const AuthLocalDataSourceImpl(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> cacheSession({
    required AuthTokenModel token,
    required UserModel user,
  }) async {
    try {
      await Future.wait([
        _storage.write(
            key: AppConstants.kAccessToken, value: token.accessToken),
        _storage.write(
            key: AppConstants.kRefreshToken, value: token.refreshToken),
        _storage.write(
            key: AppConstants.kCachedUser, value: jsonEncode(user.toMap())),
      ]);
    } catch (_) {
      throw const CacheException(message: 'Failed to persist session.');
    }
  }

  @override
  Future<UserModel?> readUser() async {
    try {
      final raw = await _storage.read(key: AppConstants.kCachedUser);
      if (raw == null) return null;
      return UserModel.fromMap(jsonDecode(raw) as DataMap);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthTokenModel?> readToken() async {
    final access = await _storage.read(key: AppConstants.kAccessToken);
    final refresh = await _storage.read(key: AppConstants.kRefreshToken);
    if (access == null || refresh == null) return null;
    return AuthTokenModel(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> clear() => Future.wait([
        _storage.delete(key: AppConstants.kAccessToken),
        _storage.delete(key: AppConstants.kRefreshToken),
        _storage.delete(key: AppConstants.kCachedUser),
      ]);

  // ── TokenStore (consumed by AuthInterceptor) ────────────────────────
  @override
  Future<String?> readAccessToken() =>
      _storage.read(key: AppConstants.kAccessToken);

  @override
  Future<String?> readRefreshToken() =>
      _storage.read(key: AppConstants.kRefreshToken);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      Future.wait([
        _storage.write(key: AppConstants.kAccessToken, value: accessToken),
        _storage.write(key: AppConstants.kRefreshToken, value: refreshToken),
      ]);
}
