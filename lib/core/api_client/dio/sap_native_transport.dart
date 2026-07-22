import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/config/env.dart';

/// Sends a request through the **platform's own TLS stack** instead of Dart's.
///
/// ## Why this exists
///
/// The SAP facade renegotiates the TLS session mid-connection (TLS 1.2 only).
/// Dart's BoringSSL aborts that with `NO_RENEGOTIATION` below any Dart callback,
/// and exposes no way to permit it — so no pure-Dart transport can reach this
/// host. `cronet_http` is not an escape (Cronet is also BoringSSL, and its
/// artifacts collide on the `org.chromium.net` namespace under AGP 9). Android's
/// `HttpsURLConnection` (Conscrypt) tolerates the renegotiation and ships with
/// the OS.
///
/// This is the low-level bridge; [SapNativeAdapter] wraps it as a Dio
/// `HttpClientAdapter` so every SAP call — not just login — flows through it
/// while keeping the interceptor stack, pinning policy and error mapping.
///
/// ## Security posture
///
/// The native side pins the server certificate to [Env.sapCertSha256] using the
/// same base64-SHA-256-of-DER comparison and the same fail-closed rule as
/// `DioFactory._applyTls`. This is not a trust-all bypass.
abstract final class SapNativeTransport {
  const SapNativeTransport._();

  /// Must match `MainActivity.CHANNEL`.
  static const MethodChannel _channel =
      MethodChannel('isi/sap_native_transport');

  /// Whether this platform has a native transport implementation.
  ///
  /// Android only for now. iOS needs the `NSURLSession` equivalent, which must
  /// be built and tested on a Mac; until then SAP on iOS stays on the Dart
  /// pinned path (which fails this specific renegotiating server with a clear,
  /// already-explained `NO_RENEGOTIATION`, not a silent error).
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Performs [method] against [url] through the platform stack.
  ///
  /// Throws [SapNativeTransportException] when the platform layer itself failed
  /// (the message names the underlying cause). A normal HTTP error status —
  /// 400, 401, 500 — is **not** an exception here; it is returned like any
  /// other response so the Dio error pipeline above can map it.
  static Future<SapNativeResponse> send({
    required String method,
    required String url,
    required Map<String, String> headers,
    String? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!isSupported) {
      throw const SapNativeTransportException(
        'No native SAP transport on this platform (Android only).',
      );
    }
    if (Env.sapCertSha256.isEmpty) {
      // Same fail-closed rule as the Dart client: an unpinned raw-IP host cannot
      // be authenticated, and accepting any certificate would expose customer
      // data to a trivial MITM (`docs/SECURITY.md` §6).
      throw const SapNativeTransportException(
        'SAP_CERT_SHA256 is empty — refusing to connect unpinned.',
      );
    }

    final Map<Object?, Object?>? raw =
        await _channel.invokeMapMethod<Object?, Object?>('send', {
      'method': method,
      'url': url,
      'headers': headers,
      'body': body,
      'pin': Env.sapCertSha256,
      'timeoutMs': timeout.inMilliseconds,
    });

    if (raw == null) {
      throw const SapNativeTransportException('Native transport returned null.');
    }

    final error = raw['error'] as String?;
    if (error != null) {
      throw SapNativeTransportException(error);
    }

    final statusCode = raw['statusCode'] as int?;
    if (statusCode == null) {
      throw const SapNativeTransportException(
        'Native transport returned no status code.',
      );
    }

    final rawHeaders = raw['headers'];
    final headersOut = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((k, v) {
        if (k != null) headersOut['$k'] = '$v';
      });
    }

    return SapNativeResponse(
      statusCode: statusCode,
      headers: headersOut,
      body: raw['body'] as String? ?? '',
    );
  }
}

class SapNativeResponse {
  const SapNativeResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final String body;
}

class SapNativeTransportException implements Exception {
  const SapNativeTransportException(this.message);

  final String message;

  @override
  String toString() => 'SapNativeTransportException: $message';
}
