import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/config/env.dart';

/// Sends a request through the **platform's own TLS stack** instead of Dart's.
///
/// ## Why this exists
///
/// The SAP façade asks the client to renegotiate the TLS session mid-connection
/// (TLS 1.2 only, almost certainly optional client-certificate negotiation on
/// the HTTPS binding). Dart's BoringSSL refuses this unconditionally —
/// `NO_RENEGOTIATION`, boringssl `ssl_lib.cc:1635` — and exposes no option to
/// permit it. Verified against every request shape: `GET /swagger`,
/// `POST /api/Auth/Login`, and with `Connection: close`. TLS 1.3, where
/// renegotiation does not exist, is not supported by the server.
///
/// So no Dart-side transport can reach this host. `cronet_http` is not an
/// escape either: Cronet is Chromium, which also builds on BoringSSL, and it
/// additionally fails to build here because its `cronet-api` and `cronet-shared`
/// artifacts share the `org.chromium.net` namespace, which AGP 9 rejects.
///
/// Android's `HttpsURLConnection` (Conscrypt) is part of the OS, adds no
/// dependency, and is the remaining candidate.
///
/// ## Security posture
///
/// This is **not** a trust-all bypass. The native side pins the server
/// certificate to [Env.sapCertSha256] — the same value, the same base64
/// SHA-256-of-DER comparison, and the same fail-closed behaviour as
/// `DioFactory._applyTls`. Hostname verification is skipped only because the
/// certificate is a valid CA-issued wildcard for `*.isigroup.com.kh` while the
/// app dials a raw IP absent from the SAN list; the pin is what authenticates
/// the server.
abstract final class SapNativeTransport {
  const SapNativeTransport._();

  /// Must match `MainActivity.CHANNEL`.
  static const MethodChannel _channel =
      MethodChannel('isi/sap_native_transport');

  /// Whether this platform has a native transport implementation.
  static bool get isSupported => Platform.isAndroid;

  /// POSTs [body] to [url] and returns the raw status and body.
  ///
  /// Throws [SapNativeTransportException] when the platform stack itself
  /// failed — which, if the message names renegotiation, means Conscrypt
  /// refuses it too and no client-side transport on Android can reach this
  /// server.
  static Future<SapNativeResponse> post({
    required String url,
    required String body,
  }) async {
    if (!isSupported) {
      throw const SapNativeTransportException(
        'No native transport on this platform.',
      );
    }
    if (Env.sapCertSha256.isEmpty) {
      // Same fail-closed rule as the Dart client: an unpinned raw-IP host
      // cannot be authenticated at all, and accepting any certificate would
      // expose customer data to a trivial MITM (`docs/SECURITY.md` §6).
      throw const SapNativeTransportException(
        'SAP_CERT_SHA256 is empty — refusing to connect unpinned.',
      );
    }

    final Map<Object?, Object?>? raw = await _channel.invokeMapMethod<
        Object?, Object?>('post', <String, Object?>{
      'url': url,
      'body': body,
      'pin': Env.sapCertSha256,
    });

    if (raw == null) {
      throw const SapNativeTransportException('Native transport returned null.');
    }

    final error = raw['error'] as String?;
    if (error != null) {
      if (kDebugMode) debugPrint('[native-tls] failed: $error');
      throw SapNativeTransportException(error);
    }

    final statusCode = raw['statusCode'] as int?;
    if (statusCode == null) {
      throw const SapNativeTransportException('Native transport gave no status.');
    }

    if (kDebugMode) debugPrint('[native-tls] HTTP $statusCode');
    return SapNativeResponse(
      statusCode: statusCode,
      body: raw['body'] as String? ?? '',
    );
  }
}

class SapNativeResponse {
  const SapNativeResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class SapNativeTransportException implements Exception {
  const SapNativeTransportException(this.message);

  final String message;

  @override
  String toString() => 'SapNativeTransportException: $message';
}
