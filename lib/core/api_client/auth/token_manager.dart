import 'dart:async';

import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_exception.dart';
import 'package:isi_steel_sales_mobile/core/api_client/auth/auth_session.dart';
import 'package:isi_steel_sales_mobile/core/api_client/endpoints/sap_endpoints.dart';
import 'package:isi_steel_sales_mobile/core/api_client/security/secure_storage_service.dart';

/// Owns the session for one backend.
///
/// The feature layer never touches a JWT: it calls a datasource, which calls
/// `ApiService`, whose auth interceptor asks the manager for a token. Login and
/// logout are the only operations a feature invokes, and even those go through a
/// usecase.
abstract interface class TokenManager {
  /// Current session, renewed if expired. Null when none can be obtained
  /// without user interaction.
  Future<AuthSession?> currentSession();

  /// Authenticates and persists the session.
  Future<AuthSession> login(AuthCredentials credentials);

  /// Persists a session obtained elsewhere.
  ///
  /// The user-facing sign-in is performed by the authentication feature's
  /// remote datasource — that is where a network call belongs under Clean
  /// Architecture. But storage must have exactly one owner, or the interceptor
  /// and the feature end up reading different copies of the token (which is
  /// precisely the drift this method exists to prevent). So the datasource makes
  /// the call and hands the result here.
  ///
  /// [credentials] are retained for silent renewal — see the class docs on why.
  Future<void> adoptSession({
    required AuthSession session,
    required AuthCredentials credentials,
  });

  /// The signed-in session if one is stored and unexpired, else null.
  /// Performs no network call.
  Future<AuthSession?> peekSession();

  /// Forces renewal. Throws [UnauthorizedException] when impossible.
  Future<AuthSession> renew();

  /// Clears the session and anything needed to renew it.
  Future<void> signOut();

  /// Emits when the session is lost and the user must sign in again.
  ///
  /// The interceptor cannot navigate, and a repository should not: this lets the
  /// shell react once, in one place, instead of each screen guessing.
  Stream<void> get onSessionExpired;
}

/// SAP session manager.
///
/// **Why credentials are retained.** SAP issues a ~60-minute token and exposes
/// no refresh endpoint (technical document §3.2) — the only way to get a new one
/// is to POST the username and password again. A field rep works offline for
/// hours, so the choice is between holding the credential in hardware-backed
/// storage and renewing silently, or interrupting the rep with a login prompt
/// every hour, mid-visit.
///
/// The former is chosen deliberately. The credential sits in the
/// Keychain/Keystore beside the database key, never in `SharedPreferences`,
/// Hive, logs, or the Drift database, and is erased on sign-out. If the backend
/// ever adds refresh-token rotation, this should be deleted in favour of it —
/// that is strictly better and removes the need to hold a password at all.
class SapTokenManager implements TokenManager {
  SapTokenManager({
    required Dio loginDio,
    required SecureStorageService storage,
  })  : _dio = loginDio,
        _storage = storage;

  /// A Dio **without** the auth interceptor. A 401 during renewal must not
  /// trigger another renewal, which would recurse until the stack overflows.
  final Dio _dio;
  final SecureStorageService _storage;

  final _sessionExpired = StreamController<void>.broadcast();

  @override
  Stream<void> get onSessionExpired => _sessionExpired.stream;

  /// De-duplicates concurrent renewals.
  ///
  /// A sync pass fires many parallel requests. Against an expired token, each
  /// would otherwise launch its own login — hammering the auth endpoint and
  /// racing to overwrite the stored session. All callers await the same future.
  Future<AuthSession>? _inFlight;

  @override
  Future<AuthSession?> currentSession() async {
    final stored = await _readSession();
    if (stored != null && stored.isValid) return stored;
    try {
      return await renew();
    } on UnauthorizedException {
      return null;
    }
  }

  @override
  Future<AuthSession> login(AuthCredentials credentials) async {
    final session = await _authenticate(credentials);
    await _storage.writeJson(
      SecureStorageKeys.sapCredentials,
      credentials.toJson(),
    );
    return session;
  }

  @override
  Future<void> adoptSession({
    required AuthSession session,
    required AuthCredentials credentials,
  }) async {
    await _storage.writeJson(SecureStorageKeys.sapSession, session.toJson());
    await _storage.writeJson(
      SecureStorageKeys.sapCredentials,
      credentials.toJson(),
    );
  }

  @override
  Future<AuthSession?> peekSession() async {
    final session = await _readSession();
    return (session != null && session.isValid) ? session : null;
  }

  @override
  Future<AuthSession> renew() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _renew();
    _inFlight = future;
    // Cleared in `whenComplete` rather than after an await so a failed renewal
    // does not leave a poisoned future cached for every later caller.
    return future.whenComplete(() => _inFlight = null);
  }

  Future<AuthSession> _renew() async {
    final json = await _storage.readJson(SecureStorageKeys.sapCredentials);
    if (json == null) {
      _sessionExpired.add(null);
      throw const UnauthorizedException(
        message: 'No stored SAP credentials — sign in again.',
      );
    }
    try {
      return await _authenticate(AuthCredentials.fromJson(json));
    } on UnauthorizedException {
      // Stored credentials exist but SAP rejected them: the password changed or
      // the account was disabled. Clear them so the app stops retrying a
      // credential that can never succeed, and tell the shell to sign out.
      await signOut();
      _sessionExpired.add(null);
      rethrow;
    }
  }

  Future<AuthSession> _authenticate(AuthCredentials credentials) async {
    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        SapEndpoints.login,
        data: credentials.toJson(),
        options: Options(validateStatus: (_) => true),
      );
    } on DioException {
      // Never echo the request or response of a login — it is
      // credential-bearing by definition.
      throw const NetworkException(
        message: 'Could not reach SAP to sign in.',
        endpoint: SapEndpoints.login,
      );
    }

    final status = response.statusCode ?? 0;
    if (status == 401 || status == 400) {
      throw const UnauthorizedException(
        message: 'Incorrect SAP username or password.',
        endpoint: SapEndpoints.login,
      );
    }
    if (status != 200) {
      throw ServerException(
        message: 'SAP sign-in failed.',
        statusCode: status,
        endpoint: SapEndpoints.login,
      );
    }

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const ServerException(
        message: 'SAP returned an unexpected sign-in response.',
        endpoint: SapEndpoints.login,
      );
    }

    try {
      final session = AuthSession.fromSapLogin(body);
      await _storage.writeJson(
        SecureStorageKeys.sapSession,
        session.toJson(),
      );
      return session;
    } on FormatException {
      throw const ServerException(
        message: 'SAP returned a malformed sign-in response.',
        endpoint: SapEndpoints.login,
      );
    }
  }

  Future<AuthSession?> _readSession() async {
    final json = await _storage.readJson(SecureStorageKeys.sapSession);
    return json == null ? null : AuthSession.fromJson(json);
  }

  @override
  Future<void> signOut() async {
    await _storage.delete(SecureStorageKeys.sapSession);
    await _storage.delete(SecureStorageKeys.sapCredentials);
  }

  /// Releases the expiry stream. Call from DI teardown.
  Future<void> dispose() => _sessionExpired.close();
}
