import 'package:isi_steel_sales_mobile/core/config/app_config.dart';

/// Everything that distinguishes one backend from another.
///
/// Adding a service — notifications, uploads, analytics, reporting — is a new
/// `ApiConfig` constant plus a `DioFactory` line. No interceptor, no
/// `DioClient`, and no `ApiService` code changes, which is the property this
/// layer exists to provide.
class ApiConfig {
  const ApiConfig({
    required this.name,
    required this.baseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    this.sendTimeout,
    this.requiresAuth = true,
    this.certificateSha256 = '',
    this.maxRetries = 2,
    this.defaultHeaders = const {'Content-Type': 'application/json'},
  });

  /// Short identifier used in log lines to tell backends apart.
  final String name;

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration? sendTimeout;

  /// Whether the auth interceptor should attach a bearer token.
  ///
  /// False for services that are public or use another scheme — attaching a SAP
  /// token to an unrelated host would leak the credential to a third party.
  final bool requiresAuth;

  /// Base64 SHA-256 of the server certificate (DER). Empty means "no pin".
  ///
  /// A pin is only *required* where ordinary CA validation cannot work — see
  /// [requiresCertificatePin].
  final String certificateSha256;

  final int maxRetries;
  final Map<String, String> defaultHeaders;

  bool get hasCertificatePin => certificateSha256.isNotEmpty;

  /// True when this backend can only be authenticated by a pin.
  ///
  /// The SAP host serves HTTPS from a raw IP with a self-signed certificate, so
  /// there is no hostname to match and no CA to trust. For such a host an
  /// absent pin means the server cannot be authenticated at all, and the client
  /// fails closed rather than accepting any certificate.
  ///
  /// A normal CA-signed host (the ISI backend) needs no pin — the platform
  /// trust store does the work.
  bool get requiresCertificatePin => _isRawIpHost(baseUrl);

  static bool _isRawIpHost(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
  }

  ApiConfig copyWith({String? baseUrl, String? certificateSha256}) => ApiConfig(
        name: name,
        baseUrl: baseUrl ?? this.baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        requiresAuth: requiresAuth,
        certificateSha256: certificateSha256 ?? this.certificateSha256,
        maxRetries: maxRetries,
        defaultHeaders: defaultHeaders,
      );

  // ── Registered backends ──────────────────────────────────────────────

  /// SAP S/4HANA via the `SapAPI` ASP.NET façade.
  static ApiConfig get sap => ApiConfig(
        name: 'SAP',
        baseUrl: SapConfig.primaryBaseUrl,
        connectTimeout: SapConfig.timeout,
        receiveTimeout: SapConfig.timeout,
        sendTimeout: SapConfig.timeout,
        certificateSha256: SapConfig.certSha256,
      );

  /// ISI Steel Sales backend — auth, profile, notifications, config, analytics.
  static ApiConfig get isi => ApiConfig(
        name: 'ISI',
        baseUrl: IsiConfig.baseUrl,
        connectTimeout: IsiConfig.timeout,
        receiveTimeout: IsiConfig.timeout,
        sendTimeout: IsiConfig.timeout,
      );

  /// Failover target for SAP — the public address, used when the LAN host is
  /// unreachable. Same pin: it is the same server on a different route.
  static ApiConfig get sapFallback =>
      sap.copyWith(baseUrl: SapConfig.fallbackBaseUrl);
}
