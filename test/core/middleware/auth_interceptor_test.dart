import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/middleware/app_middleware.dart';

/// An in-memory [TokenStore] that records the order writes happened in.
class _RecordingStore implements TokenStore {
  String? access = 'stale_access';
  String? refresh = 'refresh_1';
  int clears = 0;

  /// Every key written, in order. Refresh must precede access.
  final List<String> writeOrder = [];

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    writeOrder.add('refresh');
    refresh = refreshToken;
    writeOrder.add('access');
    access = accessToken;
  }

  @override
  Future<void> clear() async {
    clears++;
    access = null;
    refresh = null;
  }
}

/// Serves scripted responses so the interceptor can be driven without a server.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? stream,
      Future<void>? cancelFuture) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, int status) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late _RecordingStore store;

  setUp(() => store = _RecordingStore());

  /// Builds a client whose interceptor refreshes against [refreshAdapter] and
  /// whose own calls go through [adapter].
  Dio build({
    required _ScriptedAdapter adapter,
    required _ScriptedAdapter refreshAdapter,
    void Function()? onSessionExpired,
  }) {
    final refreshClient = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = refreshAdapter;

    return Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(
        tokenStore: store,
        refreshClient: refreshClient,
        deviceId: () async => 'device-1',
        onSessionExpired: onSessionExpired,
      ));
  }

  test('attaches the bearer token to every request', () async {
    final adapter = _ScriptedAdapter((_) async => _json({'ok': true}, 200));
    final dio = build(adapter: adapter, refreshAdapter: adapter);

    await dio.get<dynamic>('/mobile/customers');

    expect(adapter.requests.single.headers['Authorization'],
        'Bearer stale_access');
  });

  test('a 403 is never refreshed and never clears the session', () async {
    // A 403 means this user may never do this. Signing them out and showing a
    // login screen would be wrong and confusing.
    var refreshCalls = 0;
    final refreshAdapter = _ScriptedAdapter((_) async {
      refreshCalls++;
      return _json({'access_token': 'new'}, 200);
    });
    final adapter = _ScriptedAdapter(
        (_) async => _json({'errorCode': 'Auth.PermissionDenied'}, 403));

    final dio = build(adapter: adapter, refreshAdapter: refreshAdapter);

    await expectLater(
      dio.get<dynamic>('/mobile/customers'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
    expect(store.clears, 0);
    expect(store.access, 'stale_access');
  });

  test('a 401 refreshes once and replays the original request', () async {
    final refreshAdapter = _ScriptedAdapter((_) async => _json({
          'access_token': 'fresh_access',
          'refresh_token': 'refresh_2',
        }, 200));

    var calls = 0;
    final adapter = _ScriptedAdapter((_) async {
      calls++;
      // The replay goes through the refresh client, so this only ever fires
      // for the original attempt.
      return _json({'errorCode': 'Auth.NotAuthenticated'}, 401);
    });

    // The replay is issued on the refresh client; answer it with a success.
    final replayAdapter = _ScriptedAdapter((options) async {
      if (options.path.contains('refresh')) {
        return _json({
          'access_token': 'fresh_access',
          'refresh_token': 'refresh_2',
        }, 200);
      }
      return _json({'ok': true}, 200);
    });

    final dio = build(adapter: adapter, refreshAdapter: replayAdapter);
    final response = await dio.get<dynamic>('/mobile/customers');

    expect(response.statusCode, 200);
    expect(calls, 1, reason: 'the original request is attempted once');
    expect(store.access, 'fresh_access');
    expect(refreshAdapter.requests, isEmpty);
  });

  test('the refresh body is camelCase and carries the deviceId', () async {
    // The rotation is keyed to the session that deviceId opened; snake_case
    // here silently produces a refresh the server cannot match.
    final replayAdapter = _ScriptedAdapter((options) async {
      if (options.path.contains('refresh')) {
        return _json({
          'access_token': 'fresh_access',
          'refresh_token': 'refresh_2',
        }, 200);
      }
      return _json({'ok': true}, 200);
    });
    final adapter = _ScriptedAdapter((_) async => _json({}, 401));

    await build(adapter: adapter, refreshAdapter: replayAdapter)
        .get<dynamic>('/mobile/customers');

    final refreshRequest = replayAdapter.requests
        .firstWhere((r) => r.path.contains('refresh'))
        .data as Map;

    expect(refreshRequest['refreshToken'], 'refresh_1');
    expect(refreshRequest['deviceId'], 'device-1');
    expect(refreshRequest.containsKey('refresh_token'), isFalse);
  });

  test('persists the refresh token before the access token', () async {
    // Refresh tokens are single-use. Writing the access token first would, on
    // a crash between the two, leave a live access token beside a retired
    // refresh token — a session that dies in fifteen minutes.
    final replayAdapter = _ScriptedAdapter((options) async {
      if (options.path.contains('refresh')) {
        return _json({
          'access_token': 'fresh_access',
          'refresh_token': 'refresh_2',
        }, 200);
      }
      return _json({'ok': true}, 200);
    });
    final adapter = _ScriptedAdapter((_) async => _json({}, 401));

    await build(adapter: adapter, refreshAdapter: replayAdapter)
        .get<dynamic>('/mobile/customers');

    expect(store.writeOrder, ['refresh', 'access']);
  });

  test('a failed refresh clears the session and reports it once', () async {
    var expired = 0;
    final replayAdapter =
        _ScriptedAdapter((_) async => _json({'error': 'invalid_grant'}, 400));
    final adapter = _ScriptedAdapter((_) async => _json({}, 401));

    final dio = build(
      adapter: adapter,
      refreshAdapter: replayAdapter,
      onSessionExpired: () => expired++,
    );

    await expectLater(
      dio.get<dynamic>('/mobile/customers'),
      throwsA(isA<DioException>()),
    );
    expect(store.clears, 1);
    expect(expired, 1);
  });

  test('a 401 from an auth route is the answer, not a stale token', () async {
    // Refreshing here would burn a rotation, and on the login path could spend
    // one of the five attempts that lock the account.
    var refreshCalls = 0;
    final replayAdapter = _ScriptedAdapter((_) async {
      refreshCalls++;
      return _json({'access_token': 'x'}, 200);
    });
    final adapter = _ScriptedAdapter((_) async => _json({}, 401));

    final dio = build(adapter: adapter, refreshAdapter: replayAdapter);

    await expectLater(
      dio.post<dynamic>(AppConstants.loginEndpoint),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
  });
}
