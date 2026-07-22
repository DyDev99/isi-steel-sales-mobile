import 'package:flutter/foundation.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_exception.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/sap_api_service.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/sap_native_transport.dart';
import 'package:isi_steel_sales_mobile/core/api_client/endpoints/sap_endpoints.dart';
import 'package:isi_steel_sales_mobile/core/config/app_config.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/sap_auth_response_model.dart';

abstract interface class AuthRemoteDataSource {
  /// `POST /api/Auth/Login` — the only SAP endpoint that takes no bearer token.
  Future<SapAuthResponseModel> login({
    required String username,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._api);

  final SapApiService _api;

  @override
  Future<SapAuthResponseModel> login({
    required String username,
    required String password,
  }) async {
    // Mirrors the Thunder Client request that is known to work against this
    // endpoint. `Content-Type` is already the SAP client default and Dio would
    // set it anyway for a Map body, so it is restated here only to keep this
    // call byte-comparable with the reference request. `Accept: */*` is the
    // meaningful one: it overrides a narrower default so a non-JSON error page
    // from the façade still reaches the error mapper instead of being rejected
    // by content negotiation.
    const headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': '*/*',
    };

    _traceRequest(headers: headers, username: username, password: password);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        SapEndpoints.login,
        data: {'username': username, 'password': password},
        headers: headers,
        // Login mints the token, so it must not carry one. Without this the auth
        // interceptor would ask the token manager for a session, which would try
        // to log in — recursing into this very call.
        skipAuth: true,
        // Login requires internet by definition (`docs/OFFLINE_FIRST.md` §4),
        // so the offline fast-path has nothing to offer it: there is no cached
        // credential to fall back on and the user is actively waiting. Consult
        // the socket, not a cached verdict that can be stale or simply wrong —
        // which is precisely what produced an unexplained
        // "No internet connection." on a device with a working network.
        skipConnectivityCheck: true,
        decoder: (body) =>
            body is Map<String, dynamic> ? body : const <String, dynamic>{},
      );

      _traceResponse(statusCode: response.statusCode, body: response.data);

      return SapAuthResponseModel.fromJson(response.data);
    } on ApiException catch (e) {
      _traceFailure(e);
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TODO(release-gate): debug-only login tracing.
//
// Every function below is a no-op unless `kDebugMode`, so none of it can reach
// a release build (`docs/SECURITY.md` §11). It exists because login is the one
// call where a silent failure is hardest to diagnose — it runs before any
// session exists, so there is no other signal to correlate against.
//
// **The password and the JWT are never printed.** `docs/SECURITY.md` §10 names
// both explicitly, and a log sink is exactly where a credential outlives the
// process that used it. What is printed instead is everything needed to debug
// the failure without carrying the secret:
//   * the password's **length**, which catches the realistic input bugs — a
//     trailing space, a truncated paste, an empty field — without revealing it;
//   * the token's **prefix and length**, enough to confirm a JWT actually
//     arrived and is well-formed (`eyJ…` is the base64 of `{"alg"`), which is
//     the only thing the caller needs to know at this point.
// ─────────────────────────────────────────────────────────────────────────────

void _traceRequest({
  required Map<String, dynamic> headers,
  required String username,
  required String password,
}) {
  if (!kDebugMode) return;

  final url = '${SapConfig.primaryBaseUrl}${SapEndpoints.login}';
  debugPrint('[AUTH] ┌─ REQUEST ────────────────────────────────');
  debugPrint('[AUTH] │ POST $url');
  // Transport first: when the failure is a handshake, everything below this
  // line is irrelevant and this line is the answer. Must reflect the transport
  // actually used, or a green log hides a red connection.
  debugPrint(
    '[AUTH] │ transport: ${SapNativeTransport.isSupported ? 'native platform TLS (Conscrypt) — tolerates renegotiation' : 'dart BoringSSL — renegotiating server WILL fail'}',
  );
  for (final entry in headers.entries) {
    debugPrint('[AUTH] │ ${entry.key}: ${entry.value}');
  }
  debugPrint('[AUTH] │ body: {');
  debugPrint('[AUTH] │   "username": "$username",');
  debugPrint(
    '[AUTH] │   "password": "<masked, ${password.length} chars'
    '${password.trim().length != password.length ? ', HAS LEADING/TRAILING '
        'WHITESPACE' : ''}>"',
  );
  debugPrint('[AUTH] │ }');
  debugPrint('[AUTH] └──────────────────────────────────────────');
}

void _traceResponse({
  required int statusCode,
  required Map<String, dynamic> body,
}) {
  if (!kDebugMode) return;

  debugPrint('[AUTH] ┌─ RESPONSE ───────────────────────────────');
  debugPrint('[AUTH] │ status: $statusCode');
  // Key names in full: a PascalCase/camelCase mismatch is the likeliest silent
  // failure here, and the key list makes it obvious at a glance.
  debugPrint('[AUTH] │ keys: ${body.keys.toList()..sort()}');
  for (final entry in body.entries) {
    debugPrint('[AUTH] │ ${entry.key}: ${_maskValue(entry.key, entry.value)}');
  }
  debugPrint('[AUTH] └──────────────────────────────────────────');
}

void _traceFailure(ApiException e) {
  if (!kDebugMode) return;

  debugPrint('[AUTH] ┌─ FAILED ─────────────────────────────────');
  debugPrint('[AUTH] │ type: ${e.runtimeType}');
  debugPrint('[AUTH] │ status: ${e.statusCode ?? '(no HTTP response)'}');
  debugPrint('[AUTH] │ endpoint: ${e.endpoint ?? '-'}');
  // `message` is server-supplied and could echo submitted content, so it is
  // length-capped rather than printed unbounded.
  final message = e.message;
  debugPrint(
    '[AUTH] │ message: '
    '${message.length > 200 ? '${message.substring(0, 200)}…' : message}',
  );
  if (e is NoInternetException) {
    debugPrint('[AUTH] │ NOTE: rejected by ConnectivityInterceptor before send.');
    debugPrint('[AUTH] │ See the connectivity.probe_* lines above.');
  }
  _traceTlsHint(message);
  debugPrint('[AUTH] └──────────────────────────────────────────');
}

/// Turns the three TLS failures that actually occur against this façade into a
/// named cause and a next action.
///
/// Without this, all three arrive as an untyped `HandshakeException` wrapped in
/// a `DioException` wrapped in an `ApiException`, and they are routinely
/// misread as each other — the renegotiation abort in particular gets treated
/// as a certificate-trust problem and answered with a `badCertificateCallback`
/// that cannot possibly help.
void _traceTlsHint(String message) {
  final lower = message.toLowerCase();

  if (lower.contains('no_renegotiation') || lower.contains('renegotiation')) {
    debugPrint('[AUTH] │ CAUSE: server-initiated TLS renegotiation.');
    debugPrint('[AUTH] │ Dart BoringSSL aborts this below any Dart callback,');
    debugPrint('[AUTH] │ so badCertificateCallback cannot help.');
    debugPrint('[AUTH] │ FIX: SAP_TRANSPORT=native, or =cleartext for dev.');
    return;
  }

  if (lower.contains('certificate') ||
      lower.contains('handshake') ||
      lower.contains('cert_authority') ||
      lower.contains('unknown_ca')) {
    debugPrint('[AUTH] │ CAUSE: certificate rejected, not renegotiation.');
    debugPrint('[AUTH] │ Cronet ignores network_security_config.xml, so a');
    debugPrint('[AUTH] │ user-installed CA will not satisfy it. Use a');
    debugPrint('[AUTH] │ system-level CA, or SAP_TRANSPORT=cleartext.');
    return;
  }

  if (lower.contains('cleartext') || lower.contains('not permitted')) {
    debugPrint('[AUTH] │ CAUSE: platform blocked an http:// request.');
    debugPrint('[AUTH] │ FIX: usesCleartextTraffic (Android) / ATS (iOS).');
  }
}

/// Masks the two §10-forbidden values; everything else prints verbatim.
String _maskValue(String key, Object? value) {
  final text = value?.toString() ?? 'null';
  if (key.toLowerCase() != 'token') return text;
  if (text.isEmpty) return '<EMPTY>';
  // Prefix only. `eyJ` confirms a JWT without exposing a usable credential.
  return '<masked JWT, ${text.length} chars, starts "${text.substring(0, text.length < 6 ? text.length : 6)}…">';
}