import 'dart:async';

import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';

/// The subset of token operations the interceptor needs. Implemented by the
/// auth local data source — declared here as an interface to avoid a
/// circular dependency between the network layer and the auth feature.
abstract interface class TokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clear();
}

/// Attaches the bearer token to every request and transparently refreshes
/// it exactly once on a 401, then replays the original request.
///
/// [QueuedInterceptor] serialises handler execution, and [_refreshCompleter]
/// coalesces concurrent 401s into a single refresh call — so a burst of
/// parallel requests never triggers N refreshes or a token stampede.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required Dio refreshClient,
  })  : _store = tokenStore,
        _refreshClient = refreshClient;

  final TokenStore _store;

  /// A bare Dio WITHOUT this interceptor — used for the refresh call and
  /// for replaying the original request, so we never recurse.
  final Dio _refreshClient;

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
    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;

    if (!is401 || alreadyRetried) {
      return handler.next(err);
    }

    final newToken = await _refreshToken();
    if (newToken == null) {
      await _store.clear();
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

    final res = await _refreshClient.post<Map<String, dynamic>>(
      AppConstants.refreshEndpoint,
      data: {'refresh_token': refresh},
    );
    final data = res.data ?? const {};
    final access = data['access_token'] as String?;
    if (access == null) return null;

    final newRefresh = (data['refresh_token'] as String?) ?? refresh;
    await _store.saveTokens(accessToken: access, refreshToken: newRefresh);
    return access;
  }
}
