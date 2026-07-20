import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:isi_steel_sales_mobile/core/api_client/auth/token_manager.dart';
import 'package:isi_steel_sales_mobile/core/api_client/config/api_config.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_client.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_interceptors.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_options.dart';
import 'package:isi_steel_sales_mobile/core/api_client/network/network_checker.dart';

/// Builds a configured [DioClient] per backend.
///
/// Adding a service is one method here plus one [ApiConfig] constant — no
/// interceptor, `DioClient` or `ApiService` change. That is the property the
/// whole layer exists to preserve as notifications, uploads, analytics and
/// reporting arrive.
abstract final class DioFactory {
  const DioFactory._();

  /// SAP S/4HANA via the `SapAPI` façade.
  static DioClient createSapClient({
    required NetworkChecker networkChecker,
    required TokenManager Function() tokenManager,
  }) =>
      create(
        config: ApiConfig.sap,
        networkChecker: networkChecker,
        tokenManager: tokenManager,
      );

  /// ISI Steel Sales backend.
  static DioClient createIsiClient({
    required NetworkChecker networkChecker,
    TokenManager Function()? tokenManager,
  }) =>
      create(
        config: ApiConfig.isi,
        networkChecker: networkChecker,
        tokenManager: tokenManager,
      );

  /// Generic builder — the extension point for future services.
  ///
  /// ```dart
  /// final reporting = DioFactory.create(
  ///   config: ApiConfig.reporting,
  ///   networkChecker: checker,
  ///   tokenManager: () => isiTokenManager,
  /// );
  /// ```
  static DioClient create({
    required ApiConfig config,
    required NetworkChecker networkChecker,
    TokenManager Function()? tokenManager,
  }) {
    final dio = Dio(DioOptionsBuilder.base(config));
    _applyTls(dio, config);

    dio.interceptors.addAll(
      DioInterceptors.build(
        config: config,
        networkChecker: networkChecker,
        // Self-reference for replay: both the auth and retry interceptors need
        // to re-issue a request through this same client. A closure defers the
        // lookup until after construction completes.
        dio: () => dio,
        tokenManager: tokenManager,
      ),
    );

    return DioClient(dio: dio, config: config);
  }

  /// Interceptor-free client used only to obtain a token.
  ///
  /// Must not carry the auth interceptor: a 401 while logging in would ask the
  /// token manager to log in again, recursing indefinitely.
  static Dio createLoginDio({
    required ApiConfig config,
    required NetworkChecker networkChecker,
  }) {
    final dio = Dio(DioOptionsBuilder.base(config));
    _applyTls(dio, config);
    dio.interceptors.addAll(
      DioInterceptors.forLogin(config: config, networkChecker: networkChecker),
    );
    return dio;
  }

  /// Installs certificate pinning where the backend needs it.
  ///
  /// Only hosts that cannot be validated normally get a custom trust callback.
  /// A CA-signed host keeps the platform trust store untouched — replacing it
  /// with a pin there would be a downgrade, and would break silently at every
  /// certificate renewal.
  static void _applyTls(Dio dio, ApiConfig config) {
    if (!config.requiresCertificatePin && !config.hasCertificatePin) return;

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback = (cert, host, port) {
          // No pin configured for a host that requires one: refuse. Accepting
          // any certificate here would leave the customer master — PII — open
          // to a trivial man-in-the-middle on the office LAN.
          if (!config.hasCertificatePin) {
            if (kDebugMode) {
              debugPrint(
                '[${config.name}] TLS refused for $host:$port — no pin '
                'configured. Presented certificate SHA-256: '
                '${fingerprintOf(cert)}',
              );
            }
            return false;
          }

          final matches = fingerprintOf(cert) == config.certificateSha256;
          if (!matches && kDebugMode) {
            // Host, port and the computed fingerprint only — never the
            // certificate subject, which can name internal infrastructure. A
            // hash of a public key is safe to print, and is exactly what an
            // operator needs to repair the pin after a renewal.
            debugPrint(
              '[${config.name}] TLS pin mismatch for $host:$port. '
              'Presented certificate SHA-256: ${fingerprintOf(cert)}',
            );
          }
          return matches;
        },
    );
  }

  /// Base64 SHA-256 of a certificate's DER encoding — the value
  /// `SAP_CERT_SHA256` holds.
  ///
  /// Pins the whole certificate rather than its SubjectPublicKeyInfo: Dart
  /// exposes the DER directly, whereas isolating the SPKI would mean
  /// hand-parsing ASN.1 — the bespoke crypto plumbing `docs/SECURITY.md` §4
  /// forbids. The trade-off is that the pin must be refreshed on renewal.
  static String fingerprintOf(X509Certificate certificate) =>
      base64.encode(sha256.convert(certificate.der).bytes);
}
