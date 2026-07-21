/// Centralised, compile-time app constants. No logic here — just values.
class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────────────
  // NOTE: there is deliberately no `baseUrl` constant here. Host and timeouts
  // are environment-specific and come from `Env` (see the typed `SapConfig` /
  // `IsiConfig` views in `core/config/app_config.dart`). A hardcoded literal
  // previously lived here and pinned every build — including QA and staging —
  // to the production host.
  static const String apiPrefix = '/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // ── Endpoints ──────────────────────────────────────────────────────
  static const String loginEndpoint = '$apiPrefix/auth/login';
  static const String refreshEndpoint = '$apiPrefix/auth/refresh';
  static const String logoutEndpoint = '$apiPrefix/auth/logout';
  static const String currentUserEndpoint = '$apiPrefix/auth/me';

  // ── Secure storage keys ────────────────────────────────────────────
  static const String kAccessToken = 'isi.access_token';
  static const String kRefreshToken = 'isi.refresh_token';
  static const String kCachedUser = 'isi.cached_user';

  // ── Encrypted database (Blueprint §3) ──────────────────────────────
  /// Secure-storage key holding the hardware-sealed 256-bit device key. This
  /// is the dynamic half of the composite SQLCipher passphrase — never the
  /// final key, which is derived at runtime and never persisted.
  static const String kDbDeviceKey = 'isi.db_device_key';

  /// Secure-storage key holding the device-key version (for rotation).
  static const String kDbDeviceKeyVersion = 'isi.db_device_key_version';

  /// On-disk file name of the single encrypted application database.
  static const String encryptedDbFileName = 'isi_secure.db';
}
