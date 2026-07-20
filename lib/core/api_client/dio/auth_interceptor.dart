import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_exception.dart';
import 'package:isi_steel_sales_mobile/core/api_client/auth/token_manager.dart';

/// Attaches the bearer token and recovers from a single 401.
///
/// The feature layer never sees a JWT: it is read here, from the
/// [TokenManager], and injected into the outgoing request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenManager Function() tokenManager,
    required Dio Function() retryDio,
  })  : _tokenManager = tokenManager,
        _retryDio = retryDio;

  /// Resolved lazily: the token manager and the Dio it is attached to are
  /// mutually dependent at construction time.
  final TokenManager Function() _tokenManager;

  /// A Dio used solely to replay a request after renewal. Separate so the replay
  /// does not run this interceptor again.
  final Dio Function() _retryDio;

  static const _retriedFlag = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // The login route mints the token; sending one to it is meaningless and
    // would recurse through the manager.
    if (options.extra[skipAuthFlag] == true) return handler.next(options);

    try {
      final session = await _tokenManager().currentSession();
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      // A null session is *not* rejected here. Some endpoints tolerate anonymous
      // access — the SAP Customer controller currently does, its `[Authorize]`
      // attribute being commented out server-side — and pre-emptively failing
      // would break them. Let the server decide; a real 401 is handled below.
      handler.next(options);
    } on UnauthorizedException catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          error: e,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 401,
          ),
        ),
        true,
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;
    final skipsAuth = err.requestOptions.extra[skipAuthFlag] == true;

    if (!isUnauthorized || alreadyRetried || skipsAuth) {
      return handler.next(err);
    }

    // Renew once, then replay. A second 401 after a fresh token means the
    // credentials themselves are rejected, not that the token was stale —
    // retrying again would loop against the auth endpoint.
    //
    // Note this renews rather than signing the user out immediately. An
    // offline-first rep would otherwise be logged out roughly hourly, mid-visit,
    // every time the ~60-minute SAP token lapsed. `TokenManager` emits
    // `onSessionExpired` when renewal genuinely fails, and the shell signs out
    // in response — so sign-out happens on real credential failure, not on
    // ordinary expiry.
    try {
      final session = await _tokenManager().renew();
      final options = err.requestOptions
        ..headers['Authorization'] = 'Bearer ${session.accessToken}'
        ..extra[_retriedFlag] = true;

      final response = await _retryDio().fetch<dynamic>(options);
      return handler.resolve(response);
    } on Object {
      // Surface the original 401. The renewal failure adds no detail the caller
      // can act on, and replacing the error would obscure which request failed.
      return handler.next(err);
    }
  }
}

/// Marks a request that must not carry a bearer token — the login call itself.
const String skipAuthFlag = 'skip_auth';
