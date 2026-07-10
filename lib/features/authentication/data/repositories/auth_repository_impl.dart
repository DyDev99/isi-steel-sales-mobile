import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_remote_data_source.dart';
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

  @override
  ResultFuture<void> logout() async {
    try {
      if (await _network.isConnected) {
        await _remote.logout();
      }
    } catch (_) {
      // Best-effort server revocation; clearing local state is what counts.
    }
    await _local.clear();
    return const Success(null);
  }
}
