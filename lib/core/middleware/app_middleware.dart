import 'dart:async';

import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/localization/active_language.dart';
import 'package:isi_steel_sales_mobile/core/utils/uuid.dart';

/// The subset of token operations the interceptor needs. Implemented by the
/// auth local data source — declared here as an interface to avoid a
/// circular dependency between the network layer and the auth feature.
abstract interface class TokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();

  /// Persists a rotated pair.
  ///
  /// Implementations **must write the refresh token before the access token**.
  /// Refresh tokens are single-use: the moment the new access token is in
  /// play the old refresh token is dead, so a crash between the two writes
  /// with the order reversed loses the session entirely.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clear();
}

/// Supplies the per-installation `deviceId` that must accompany a refresh so
/// the rotation stays attached to the session opened at sign-in.
typedef DeviceIdReader = Future<String> Function();

/// Attaches headers every request must carry.
///
/// Both are cheap and both are load-bearing:
///
///  * `Accept-Language` is what makes the server return `shopName`,
///    `statusDisplay` and every `message` already translated — the client
///    never picks between language columns.
///  * `X-Correlation-Id` makes a request traceable end to end. Quote the id
///    from a bug report and support can find the exact call in the logs.
class ApiHeadersInterceptor extends Interceptor {
  const ApiHeadersInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Read live rather than at construction: the language can change mid
    // session and the next request must follow it.
    options.headers['Accept-Language'] = ActiveLanguage.acceptLanguageTag;
    options.headers['X-Correlation-Id'] = Uuid.v4();
    handler.next(options);
  }
}

/// Attaches the bearer token to every request and transparently refreshes it
/// exactly once on a 401, then replays the original request.
///
/// Three rules this encodes, each of which is a bug if broken:
///
///  * **Refresh reactively, on 401 — never on a timer.** A timer keeps waking
///    a phone asleep in a pocket and drifts against the server clock.
///  * **Retry exactly once.** A second 401 after a successful refresh means
///    the problem is authorisation, not expiry, and retrying again just loops.
///  * **403 is not 401.** A 403 means this user may never do this; signing
///    them out and showing a login screen would be wrong and confusing. Only
///    a 401 is handled here at all.
///
/// [QueuedInterceptor] serialises handler execution, and [_refreshCompleter]
/// coalesces concurrent 401s into a single refresh call. Without that, two
/// screens hitting 401 at once would both refresh, the second would present an
/// already-rotated token, and the server's reuse detection would read that as
/// token theft and revoke the whole session.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required Dio refreshClient,
    required DeviceIdReader deviceId,
    this.onSessionExpired,
  })  : _store = tokenStore,
        _refreshClient = refreshClient,
        _deviceId = deviceId;

  final TokenStore _store;

  /// A bare Dio WITHOUT this interceptor — used for the refresh call and
  /// for replaying the original request, so we never recurse.
  final Dio _refreshClient;

  final DeviceIdReader _deviceId;

  /// Invoked once when the refresh token is gone or rejected and the session
  /// is unrecoverable. The app uses this to drop to the login screen; without
  /// it the user would sit on an authenticated screen that silently fails.
  final void Function()? onSessionExpired;

  Completer<String?>? _refreshCompleter;

  static const _retriedFlag = '__auth_retried__';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _store.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRefresh(err)) return handler.next(err);

    final newToken = await _refreshToken();
    if (newToken == null) {
      await _store.clear();
      onSessionExpired?.call();
      return handler.next(err);
    }

    final options = err.requestOptions
      ..headers['Authorization'] = 'Bearer $newToken'
      ..extra[_retriedFlag] = true;

    try {
      final response = await _refreshClient.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRefresh(DioException err) {
    // Only a 401 says "your token is stale". A 403 is a permission verdict and
    // a 400 from an OAuth endpoint is a rejected grant — refreshing on either
    // would burn a rotation and, on the 400 path, could spend one of the five
    // login attempts that lock the account.
    if (err.response?.statusCode != 401) return false;
    if (err.requestOptions.extra[_retriedFlag] == true) return false;

    // A 401 from /auth/login or /auth/refresh is the answer, not a symptom.
    final path = err.requestOptions.path;
    return !AppConstants.authRoutes.any(path.endsWith);
  }

  Future<String?> _refreshToken() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    _performRefresh()
        .then(completer.complete)
        .catchError((_) => completer.complete(null))
        .whenComplete(() => _refreshCompleter = null);

    return completer.future;
  }

  Future<String?> _performRefresh() async {
    final refresh = await _store.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;

    // camelCase body and the same deviceId supplied at sign-in — the server
    // keys the rotation to the session that id opened.
    final res = await _refreshClient.post<Map<String, dynamic>>(
      AppConstants.refreshEndpoint,
      data: {'refreshToken': refresh, 'deviceId': await _deviceId()},
    );

    // The token endpoints answer with the raw OAuth response — snake_case and
    // no `data` envelope. This is the one place in the app that reads it.
    final data = res.data ?? const {};
    final access = data['access_token'] as String?;
    if (access == null) return null;

    // saveTokens persists the refresh half first; see [TokenStore].
    final newRefresh = (data['refresh_token'] as String?) ?? refresh;
    await _store.saveTokens(accessToken: access, refreshToken: newRefresh);
    return access;
  }
}
