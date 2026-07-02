/// Centralised, compile-time app constants. No logic here — just values.
class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://api.kicgroup.com';
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
}
