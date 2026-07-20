import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_exception.dart'
    as net;
import 'package:isi_steel_sales_mobile/core/api_client/auth/auth_session.dart';
import 'package:isi_steel_sales_mobile/core/api_client/auth/token_manager.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/sap_auth_response_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';

/// Coordinates SAP sign-in, token storage and the cached profile, translating
/// transport errors into domain [Failure]s.
///
/// The only place that knows about both the network and local storage. Nothing
/// above it sees an `ApiException`, and nothing below it constructs a `Failure`.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required TokenManager tokenManager,
    required AppLogger logger,
  })  : _remote = remote,
        _local = local,
        _tokens = tokenManager,
        _logger = logger;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final TokenManager _tokens;
  final AppLogger _logger;

  @override
  ResultFuture<User> login({
    required String email,
    required String password,
  }) async {
    // No pre-flight connectivity check: the connectivity interceptor already
    // rejects an offline request immediately with `NoInternetException`, and
    // duplicating the check here would let the two disagree.
    try {
      final response = await _remote.login(username: email, password: password);
      final user = response.toUser();

      // Token first. If the profile write fails afterwards the user is still
      // authenticated and the profile re-reads on next launch; the reverse order
      // would leave a cached profile with no token — an apparently signed-in
      // user whose every request 401s.
      await _tokens.adoptSession(
        session: AuthSession(
          accessToken: response.token,
          expiresAt: response.expiresAt,
          username: response.username,
          role: response.role,
        ),
        credentials: AuthCredentials(username: email, password: password),
      );
      await _local.cacheUser(user);

      return Success(user);
    } on net.UnauthorizedException catch (e) {
      return Failed(
        AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on net.ForbiddenException catch (e) {
      return Failed(
        SapForbiddenFailure(message: e.message),
      );
    } on net.NoInternetException catch (e) {
      return Failed(NetworkFailure(message: e.message));
    } on net.ApiTimeoutException catch (e) {
      return Failed(TimeoutFailure(message: e.message));
    } on net.SslException catch (e) {
      // Surfaced distinctly: a pin mismatch is an operational fault needing a
      // config change, not a wrong password. Reporting it as bad credentials
      // would send an operator hunting the wrong problem entirely.
      return Failed(SapCertificatePinFailure(message: e.message));
    } on net.ValidationException catch (e) {
      return Failed(ValidationFailure(message: e.message));
    } on net.ApiException catch (e) {
      return Failed(
        ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } on FormatException {
      // Never echo a login response body — it is credential-adjacent.
      return const Failed(
        ServerFailure(message: 'SAP returned an unreadable sign-in response.'),
      );
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<User> getCurrentUser() async {
    // Offline-first: a stored, unexpired token plus a cached profile is enough
    // to boot straight into the app with no network call
    // (`docs/OFFLINE_FIRST.md` §2.1 — boot must not require connectivity).
    final session = await _tokens.peekSession();
    if (session == null) {
      return const Failed(AuthenticationFailure(message: 'No active session.'));
    }

    final cached = await _local.readUser();
    if (cached == null) {
      return const Failed(
        AuthenticationFailure(message: 'No cached profile for this session.'),
      );
    }

    return Success(cached);
  }

  @override
  ResultFuture<void> logout() async {
    // SAP exposes no logout/revocation endpoint (technical document §3), so
    // signing out is purely local: drop the token, the credentials and the
    // profile. The token simply lapses server-side at `expiresAt`.
    try {
      await _tokens.signOut();
      await _local.clear();
      return const Success(null);
    } on Object catch (e, stackTrace) {
      // The previous implementation swallowed this with a bare `catch (_) {}`,
      // which the playbook (§12) names as an anti-pattern: a sign-out that
      // silently fails leaves a valid token on the device while the UI reports
      // the user as signed out. Log it and report failure.
      _logger.error(
        'Sign-out failed to clear local credentials',
        error: e,
        stackTrace: stackTrace,
      );
      return const Failed(
        CacheFailure(message: 'Could not fully clear the session.'),
      );
    }
  }
}
