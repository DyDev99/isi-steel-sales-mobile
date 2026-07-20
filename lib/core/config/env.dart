import 'package:envied/envied.dart';

part 'env.g.dart';

/// Raw, Envied-generated configuration — the only place `.env` values enter the
/// app. Prefer the typed [SapConfig] / [IsiConfig] / [AppConfig] views in
/// `app_config.dart`, which validate and interpret these raw values, over
/// reading [Env] directly.
///
/// **Obfuscation is not encryption.** Every value here is recoverable from a
/// shipped binary by a motivated attacker. Per-user credentials and bearer
/// tokens therefore live in `flutter_secure_storage`, never here
/// (`docs/SECURITY.md` §3).
@Envied(path: '.env', obfuscate: true)
abstract class Env {
  // ── SAP backend ────────────────────────────────────────────────────────
  @EnviedField(varName: 'SAP_BASE_URL_PRIMARY', obfuscate: true)
  static final String sapBaseUrlPrimary = _Env.sapBaseUrlPrimary;

  @EnviedField(varName: 'SAP_BASE_URL_FALLBACK', obfuscate: true)
  static final String sapBaseUrlFallback = _Env.sapBaseUrlFallback;

  /// SAP connection id (`DEV` / `QAS` / `PRD`) — a required path segment on
  /// every Customer and CustHelper call.
  @EnviedField(varName: 'SAP_CON_ID', obfuscate: true)
  static final String sapConId = _Env.sapConId;

  @EnviedField(varName: 'SAP_TIMEOUT_MS', obfuscate: true, defaultValue: 30000)
  static final int sapTimeoutMs = _Env.sapTimeoutMs;

  @EnviedField(varName: 'SAP_PAGE_SIZE', obfuscate: true, defaultValue: 50)
  static final int sapPageSize = _Env.sapPageSize;

  /// Base64 SHA-256 of the SAP server certificate in DER form. Empty means
  /// "no pin configured", which [SapConfig] treats as fail-closed.
  ///
  /// This pins the whole certificate rather than its SubjectPublicKeyInfo:
  /// Dart's `X509Certificate` exposes the DER bytes directly, whereas isolating
  /// the SPKI would mean hand-parsing ASN.1 — precisely the kind of bespoke
  /// crypto plumbing `docs/SECURITY.md` §4 forbids. The trade-off is that the
  /// pin must be refreshed when the certificate is renewed.
  @EnviedField(varName: 'SAP_CERT_SHA256', obfuscate: true, defaultValue: '')
  static final String sapCertSha256 = _Env.sapCertSha256;

  // ── ISI Steel Sales backend ────────────────────────────────────────────
  @EnviedField(varName: 'ISI_API_URL', obfuscate: true)
  static final String isiApiUrl = _Env.isiApiUrl;

  @EnviedField(varName: 'ISI_TIMEOUT_MS', obfuscate: true, defaultValue: 30000)
  static final int isiTimeoutMs = _Env.isiTimeoutMs;

  @EnviedField(varName: 'ISI_API_VERSION', obfuscate: true, defaultValue: 'v1')
  static final String isiApiVersion = _Env.isiApiVersion;

  // ── General ────────────────────────────────────────────────────────────
  @EnviedField(varName: 'APP_ENV', obfuscate: true, defaultValue: 'development')
  static final String appEnv = _Env.appEnv;

  @EnviedField(varName: 'ENABLE_MOCK', obfuscate: true, defaultValue: true)
  static final bool enableMock = _Env.enableMock;

  @EnviedField(varName: 'ENABLE_SYNC', obfuscate: true, defaultValue: true)
  static final bool enableSync = _Env.enableSync;

  @EnviedField(varName: 'LOG_NETWORK', obfuscate: true, defaultValue: false)
  static final bool logNetwork = _Env.logNetwork;

  // ── Database ───────────────────────────────────────────────────────────
  /// Salt half of the composite SQLCipher key (`DATABASE_GUIDE.md` §2.1).
  /// Changing this value makes every existing encrypted database unreadable.
  @EnviedField(varName: 'DB_SALT', obfuscate: true)
  static final String dbSalt = _Env.dbSalt;
}
