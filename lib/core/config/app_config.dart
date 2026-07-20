// Typed, validated views over the raw `Env` values.
//
// Two backends serve this app and they are deliberately kept apart
// (`SapConfig` vs `IsiConfig`): different hosts, different auth schemes,
// different Dio clients, different interceptors. Nothing SAP-shaped may be read
// through `IsiConfig` and vice versa — mixing them is the exact coupling this
// split exists to prevent.

import 'package:isi_steel_sales_mobile/core/config/env.dart';

/// Configuration for the SAP backend — S/4HANA Private Cloud reached through
/// the `SapAPI` ASP.NET Core façade (`SapAPI_Technical_Document_v1_BP.docx`).
///
/// Endpoint shape is always `{baseUrl}/api/{Controller}/{Action}/{parameters}`.
abstract final class SapConfig {
  const SapConfig._();

  /// LAN address, tried first.
  static String get primaryBaseUrl => Env.sapBaseUrlPrimary;

  /// Public address, used when the LAN host is unreachable.
  static String get fallbackBaseUrl => Env.sapBaseUrlFallback;

  /// Ordered failover list. Both entries are real, reachable hosts — unlike the
  /// previous `SAP_API_URL_3/_4` placeholders, which pointed at
  /// `*.company.internal` names that do not resolve and so could only ever
  /// contribute a timeout to the failover chain.
  static List<String> get baseUrls => [primaryBaseUrl, fallbackBaseUrl];

  /// SAP connection id (`DEV` / `QAS` / `PRD`). A required path segment on every
  /// Customer and CustHelper call; an unknown or inactive value yields 404.
  static String get conId => Env.sapConId;

  static Duration get timeout => Duration(milliseconds: Env.sapTimeoutMs);

  /// The technical document (§6.4) advises keeping this at 50 or below.
  static int get pageSize => Env.sapPageSize;

  /// Base64 SHA-256 of the server certificate (DER). Empty when unset.
  static String get certSha256 => Env.sapCertSha256;

  /// Whether a certificate pin has been supplied.
  ///
  /// The SAP host serves HTTPS on a raw IP with a self-signed certificate, so
  /// ordinary CA validation can never succeed. Without a pin there is no safe
  /// way to authenticate the server, so `SapClient` refuses to issue requests
  /// rather than falling back to accepting any certificate — failing closed is
  /// the only option compatible with `docs/SECURITY.md` §6.
  static bool get isCertPinConfigured => certSha256.isNotEmpty;
}

/// Configuration for the ISI Steel Sales backend — authentication, user
/// profile, notifications, app config, feature flags, preferences, analytics.
///
/// Explicitly **not** a place for SAP business objects (business partner,
/// customer master, quotation, sales order, product, inventory, territory,
/// depot). Those belong to [SapConfig].
abstract final class IsiConfig {
  const IsiConfig._();

  static String get baseUrl => Env.isiApiUrl;

  static Duration get timeout => Duration(milliseconds: Env.isiTimeoutMs);

  static String get apiVersion => Env.isiApiVersion;
}

/// Cross-cutting application switches.
abstract final class AppConfig {
  const AppConfig._();

  static String get environment => Env.appEnv;

  static bool get isProduction => environment.toLowerCase() == 'production';

  /// Swaps remote datasources for in-memory mocks at DI time. The repository,
  /// bloc and UI are byte-identical either way — mock data never reaches a
  /// widget directly (`docs/AI_ENGINEERING_PLAYBOOK.md` §12).
  static bool get enableMock => Env.enableMock;

  /// Master kill-switch for background/opportunistic sync.
  static bool get enableSync => Env.enableSync;

  /// Enables the request logger. That logger records endpoint and status code
  /// only — never bodies, headers, or query values, which on the Customer
  /// endpoints would carry PII (`docs/SECURITY.md` §10).
  static bool get logNetwork => Env.logNetwork;
}
