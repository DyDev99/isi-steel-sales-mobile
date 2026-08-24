import 'dart:async';

import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/auth_token_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_profile.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/otp_challenge.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_session.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';

/// Coordinates remote + local sources and translates exceptions into
/// [Failure]s. This is the only place that knows about both worlds.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required NetworkInfo networkInfo,
    required AppLogger logger,
  })  : _remote = remote,
        _local = local,
        _network = networkInfo,
        _logger = logger;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final NetworkInfo _network;
  final AppLogger _logger;

  /// Signing in is two calls, in this order:
  ///
  ///  1. `POST /auth/login` returns the token pair and nothing else — it is a
  ///     raw OAuth token endpoint, so there is no user object in the response.
  ///  2. `GET /auth/me` returns the profile, including the permissions and
  ///     feature flags that decide what the rep can see.
  ///
  /// The tokens are persisted between the two so step 2 authenticates
  /// normally through the interceptor.
  @override
  ResultFuture<AuthProfile> login({
    required String identifier,
    required String password,
    String? pushToken,
    bool rememberDevice = true,
  }) async {
    if (!await _network.isConnected) {
      _logger.warning('auth.login.offline');
      return const Failed(NetworkFailure());
    }

    // Note what is absent: the identifier and the password. An employee ID is
    // personal data and a password is a live credential; neither belongs in a
    // log that outlives the session. `identifierKind` gives the one fact that
    // is actually diagnostic — which of the three accepted forms was typed,
    // which is what you want when sign-in works for e-mail but not for a badge
    // number.
    _logger.info('auth.login.start', fields: {
      'identifierKind': _identifierKind(identifier),
      'rememberDevice': rememberDevice,
      // Named to survive redaction: any key containing "token" is masked, so
      // `hasPushToken` printed ***REDACTED*** — hiding a plain boolean and
      // telling nobody anything. The value is whether one exists, never its
      // contents.
      'pushRegistered': pushToken != null && pushToken.isNotEmpty,
    });

    try {
      final token = await _remote.login(
        identifier: identifier,
        password: password,
        pushToken: pushToken,
        rememberDevice: rememberDevice,
      );
      _logger.debug('auth.login.token', fields: {
        'expiresIn': token.expiresIn,
        'tokenType': token.tokenType,
      });

      // Persist before the profile call so the interceptor can authorise it.
      await _local.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      final profile = await _remote.getProfile();

      // Counts and codes, never the profile itself. A permission set that
      // comes back empty is the usual cause of "the buttons are all missing",
      // and this is where that shows up.
      _logger.info('auth.login.success', fields: {
        'permissions': profile.permissions.length,
        'roles': profile.roles.map((r) => r.name).toList(),
        'territory': profile.territoryCode,
        'depot': profile.depotCode,
        'flags': profile.featureFlags.length,
        'passwordExpiresSoon':
            profile.passwordExpiringWithin(const Duration(days: 7)),
      });

      await _local.cacheSession(token: token, profile: profile);
      return Success(profile);
    } on ApiException catch (e) {
      // Both stages land here, so record which one failed: a failure after the
      // token call means the credentials were fine and `/auth/me` is the
      // problem — a completely different investigation.
      _logger.error('auth.login.failed', fields: {
        'errorCode': e.error.code,
        'status': e.error.statusCode,
        'correlationId': e.error.correlationId,
      });

      // A failed profile fetch leaves a half-open session: tokens on disk with
      // nothing to render. Drop them so the next launch shows the login screen
      // rather than an empty shell.
      await _clearQuietly();

      return Failed(_failure(e.error));
    } on CacheException catch (e) {
      _logger.error('auth.login.cacheFailed', fields: {'reason': e.message});
      return Failed(CacheFailure(message: e.message));
    }
  }

  // ── Phone sign-in with OTP ─────────────────────────────────────────

  @override
  ResultFuture<OtpChallenge> sendOtp({
    required String phoneNumber,
    required String password,
  }) async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());

    // The number itself is never logged — it identifies a person.
    _logger.info('auth.otp.send');
    try {
      final challenge =
          await _remote.sendOtp(phoneNumber: phoneNumber, password: password);

      // Never the verificationId or the mockOtp: one is a bearer of the
      // attempt, the other is a code.
      _logger.debug('auth.otp.sent', fields: {
        'otpLength': challenge.otpLength,
        'expiresIn': challenge.expiresIn,
      });
      return Success(challenge);
    } on ApiException catch (e) {
      _logger.warning('auth.otp.send.failed', fields: {
        'errorCode': e.error.code,
        'correlationId': e.error.correlationId,
      });
      return Failed(_failure(e.error));
    }
  }

  @override
  ResultFuture<void> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      await _remote.verifyOtp(verificationId: verificationId, otp: otp);
      return const Success(null);
    } on ApiException catch (e) {
      // Five wrong codes kill the attempt permanently — the caller has to
      // distinguish that from a plain wrong code, which is why the code is
      // carried through rather than flattened to a message.
      _logger.warning('auth.otp.verify.failed',
          fields: {'errorCode': e.error.code});
      return Failed(_failure(e.error));
    }
  }

  @override
  ResultFuture<AuthProfile> completePhoneLogin({
    required String verificationId,
  }) async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      final token = await _remote.phoneLogin(verificationId: verificationId);

      // Persist before the profile call so the interceptor can authorise it —
      // identical to password sign-in from here on.
      await _local.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      final profile = await _remote.getProfile();
      _logger.info('auth.otp.login.success', fields: {
        'permissions': profile.permissions.length,
        'canReadCustomers': profile.canReadCustomers,
      });

      await _local.cacheSession(token: token, profile: profile);
      return Success(profile);
    } on ApiException catch (e) {
      // A half-open session is worse than none: tokens on disk with nothing to
      // render would boot into an empty shell next launch.
      await _clearQuietly();
      _logger.error('auth.otp.login.failed', fields: {
        'errorCode': e.error.code,
        'correlationId': e.error.correlationId,
      });
      return Failed(_failure(e.error));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<OtpChallenge> resendOtp({
    required String verificationId,
  }) async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      final challenge = await _remote.resendOtp(verificationId: verificationId);
      _logger.info('auth.otp.resent');
      return Success(challenge);
    } on ApiException catch (e) {
      _logger.warning('auth.otp.resend.failed',
          fields: {'errorCode': e.error.code});
      return Failed(_failure(e.error));
    }
  }

  /// Which of the three accepted identifier forms this looks like. Used for
  /// diagnostics only — the server decides what is valid, and this never gates
  /// the request.
  String _identifierKind(String identifier) {
    if (identifier.contains('@')) return 'email';
    if (RegExp(r'^\+?[\d\s-]+$').hasMatch(identifier)) return 'phone';
    return 'employeeId';
  }

  @override
  ResultFuture<AuthProfile> getCurrentUser() async {
    // Offline-first: a cached profile plus a token pair is enough to boot
    // straight into the app. The interceptor validates and refreshes on the
    // first real call — blocking the splash screen on a network round trip
    // would leave a rep with no signal staring at a spinner.
    //
    // The full profile, not just the user: it carries the permission set, and
    // a restored session without it knows who the user is but not what they
    // may do — so every permission-gated feature would have to guess.
    final cached = await _local.readProfile();
    final token = await _local.readToken();

    if (cached != null && token != null) {
      // The startup line worth having: it says whether the app came up signed
      // in, and with which grants. A rep reporting "the customer tab is empty"
      // is answered by `permissions` here without reproducing anything.
      _logger.info('auth.session.restored', fields: {
        'permissions': cached.permissions.length,
        'roles': cached.roles.map((r) => r.name).toList(),
        'territory': cached.territoryCode,
        'canReadCustomers': cached.can(Permissions.customersRead),
      });
      return Success(cached);
    }

    // Not an error — a guest is a first-class state. Logged at info so the
    // absence of `auth.session.restored` is never ambiguous: silence used to
    // mean either "no session" or "this code never ran", and those need very
    // different investigations.
    _logger.info('auth.session.none', fields: {
      'hasProfile': cached != null,
      // `restorable`, not `hasToken`: [LogRedactor] masks any key containing
      // "token", so the obvious name printed ***REDACTED*** over a plain
      // boolean and told nobody anything. It also reads better — the question
      // at boot is whether the session *could* be restored, and both halves
      // are needed for that.
      'restorable': cached != null && token != null,
    });
    return const Failed(AuthenticationFailure(message: 'No active session.'));
  }

  @override
  ResultFuture<AuthProfile> refreshProfile() async {
    if (!await _network.isConnected) {
      final cached = await _local.readProfile();
      return cached != null ? Success(cached) : const Failed(NetworkFailure());
    }
    try {
      final profile = await _remote.getProfile();
      await _local.cacheProfile(profile);
      return Success(profile);
    } on ApiException catch (e) {
      final cached = await _local.readProfile();
      return cached != null ? Success(cached) : Failed(_failure(e.error));
    }
  }

  @override
  ResultFuture<AuthProfile?> cachedProfile() async =>
      Success(await _local.readProfile());

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
  ///
  /// Secure storage is cleared even when the call fails: a token discarded
  /// locally is unusable regardless of whether the server was told.
  @override
  ResultFuture<void> logout({bool allDevices = false}) async {
    _logger.info('auth.logout', fields: {'allDevices': allDevices});

    // Read the outgoing credential before it is destroyed, so the revocation
    // below can still identify the session it is ending.
    final token = await _readTokenQuietly();

    // The sign-out proper. Nothing here touches the network.
    await _local.clear();

    final refreshToken = token?.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      unawaited(_revokeQuietly(refreshToken, allDevices));
    }
    return const Success(null);
  }

  @override
  ResultFuture<List<AuthSession>> listSessions() async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      return Success(await _remote.listSessions());
    } on ApiException catch (e) {
      return Failed(_failure(e.error));
    }
  }

  @override
  ResultFuture<void> revokeSession(String sessionId) async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      await _remote.revokeSession(sessionId);
      return const Success(null);
    } on ApiException catch (e) {
      return Failed(_failure(e.error));
    }
  }

  /// After a successful change the caller should sign out of every device and
  /// sign in again — the old password may have been observed.
  @override
  ResultFuture<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _guard(() => _remote.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          ));

  @override
  ResultFuture<void> forgotPassword(String email) =>
      _guard(() => _remote.forgotPassword(email));

  @override
  ResultFuture<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) =>
      _guard(() => _remote.resetPassword(
            email: email,
            token: token,
            newPassword: newPassword,
          ));

  @override
  ResultFuture<void> verifyEmail({
    required String userId,
    required String token,
  }) =>
      _guard(() => _remote.verifyEmail(userId: userId, token: token));

  @override
  ResultFuture<void> resendVerification(String email) =>
      _guard(() => _remote.resendVerification(email));

  // ── Internals ──────────────────────────────────────────────────────

  Future<Result<void>> _guard(Future<void> Function() action) async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      await action();
      return const Success(null);
    } on ApiException catch (e) {
      return Failed(_failure(e.error));
    }
  }

  /// Maps a server error onto the domain failure type.
  ///
  /// Note what is **not** here: a 403 never becomes an [AuthenticationFailure].
  /// A 403 means this user may never perform this action, and treating it as a
  /// stale session would sign them out and drop them on a login screen for no
  /// reason. Only a genuine authentication problem does that.
  Failure _failure(ApiError error) {
    // A transport error *here* means the gateway did not answer — not that the
    // device is offline.
    //
    // Every method that calls this checks `_network.isConnected` before making
    // the request, so a genuinely offline device has already returned
    // [NetworkFailure] and never reaches this point. Reporting "no internet"
    // from here therefore always lied: it sent a rep standing on office WiFi
    // to check their signal when the real cause was a dead tunnel, a wrong
    // API_BASE_URL, or a backend that was not running.
    if (error.code == ApiErrorCodes.network) {
      return const ServerUnreachableFailure();
    }
    // Checked **before** the permission branch on purpose. Two verification
    // codes are 403s — `Auth.VerificationBlocked` (five wrong codes) and
    // `Auth.ResendLimitReached` — so an `isPermissionDenied` test first would
    // swallow them as "you do not have access", and the code screen would
    // never learn the attempt was dead. Branch on the code, not the status.
    if (_isCredentialFailure(error.code) || error.isUnauthenticated) {
      return AuthenticationFailure(
        message: error.message ?? 'Your ID or password is incorrect.',
        statusCode: error.statusCode,
        // Carried so the OTP screen can tell a retryable wrong code from an
        // attempt that must restart at step 1.
        code: error.code,
      );
    }
    if (error.isPermissionDenied) {
      return ServerFailure(
        message: error.message ?? 'You do not have access to this action.',
        statusCode: error.statusCode ?? 403,
      );
    }
    return ServerFailure(
      message: error.message ?? 'Something went wrong. Please try again.',
      statusCode: error.statusCode,
    );
  }

  static bool _isCredentialFailure(String code) => const {
        ApiErrorCodes.invalidCredentials,
        ApiErrorCodes.accountLocked,
        ApiErrorCodes.accountInactive,
        ApiErrorCodes.passwordExpired,
        // RFC 6749's own token for a rejected grant, in case a deployment
        // omits the `error_uri` this maps codes from.
        'invalid_grant',
      }.contains(code);

  Future<AuthTokenModel?> _readTokenQuietly() async {
    try {
      return await _local.readToken();
    } catch (_) {
      // A token we cannot read is a token we cannot revoke. Not a reason to
      // fail the sign-out.
      return null;
    }
  }

  Future<void> _clearQuietly() async {
    try {
      await _local.clear();
    } catch (_) {
      // Best effort.
    }
  }

  /// Fire-and-forget server revocation. Bounded so a hung socket cannot keep
  /// the request (and its Dio resources) alive indefinitely, and silent
  /// because the user is already signed out — there is no outcome here they
  /// could act on.
  Future<void> _revokeQuietly(String refreshToken, bool allDevices) async {
    try {
      if (!await _network.isConnected) return;
      await _remote
          .logout(refreshToken: refreshToken, allDevices: allDevices)
          .timeout(_revokeTimeout);
    } catch (_) {
      // Intentionally swallowed, including TimeoutException.
    }
  }

  static const Duration _revokeTimeout = Duration(seconds: 10);
}
