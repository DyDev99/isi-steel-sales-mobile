import 'dart:async';

import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/auth_token_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';

/// Coordinates remote + local sources and translates exceptions into
/// [Failure]s. This is the only place that knows about both worlds.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _local = local,
        _network = networkInfo;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final NetworkInfo _network;

  @override
  ResultFuture<User> login({
    required String email,
    required String password,
  }) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final res = await _remote.login(email: email, password: password);
      await _local.cacheSession(token: res.token, user: res.user);
      return Success(res.user);
    } on AuthenticationException catch (e) {
      return Failed(
          AuthenticationFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failed(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Failed(
          ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<User> getCurrentUser() async {
    // Offline-first: a cached user + token pair is enough to boot straight
    // into the app. The interceptor validates/refreshes on the first call.
    final cached = await _local.readUser();
    final token = await _local.readToken();
    if (cached != null && token != null) {
      return Success(cached);
    }
    return const Failed(AuthenticationFailure(message: 'No active session.'));
  }

  /// Signing out is a **local** operation (ADR-002). Dropping the token store
  /// is what ends the session; server-side revocation is best-effort and is
  /// deliberately not awaited.
  ///
  /// This used to `await _remote.logout()` *before* clearing anything. That is
  /// what made sign-out feel broken: [NetworkInfo.isConnected] only reports
  /// that a network interface is up, not that the gateway answers, so on any
  /// build without a reachable backend the POST still went out and burned the
  /// full 15s `connectTimeout`. Everything behind that await — clearing
  /// tokens, the session-scoped stores, and the app restart that discards the
  /// authenticated screen stack — was stuck waiting on it, leaving the user
  /// sitting on the screen they had just signed out of.
  @override
  ResultFuture<void> logout() async {
    // Read the outgoing credential before it is destroyed, so the revocation
    // below can still authenticate itself.
    final token = await _readTokenQuietly();

    // The sign-out proper. Nothing here touches the network.
    await _local.clear();

    final accessToken = token?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      unawaited(_revokeQuietly(accessToken));
    }
    return const Success(null);
  }

  Future<AuthTokenModel?> _readTokenQuietly() async {
    try {
      return await _local.readToken();
    } catch (_) {
      // A token we cannot read is a token we cannot revoke. Not a reason to
      // fail the sign-out.
      return null;
    }
  }

  /// Fire-and-forget server revocation. Bounded so a hung socket cannot keep
  /// the request (and its Dio resources) alive indefinitely, and silent
  /// because the user is already signed out — there is no outcome here they
  /// could act on.
  Future<void> _revokeQuietly(String accessToken) async {
    try {
      if (!await _network.isConnected) return;
      await _remote.logout(accessToken: accessToken).timeout(_revokeTimeout);
    } catch (_) {
      // Intentionally swallowed, including TimeoutException.
    }
  }

  static const Duration _revokeTimeout = Duration(seconds: 10);
}
