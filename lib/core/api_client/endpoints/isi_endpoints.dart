import 'package:isi_steel_sales_mobile/core/config/app_config.dart';

/// ISI Steel Sales backend paths — authentication, user profile, notifications,
/// app configuration, feature flags, preferences and analytics.
///
/// **Provisional.** No ISI technical document has been supplied; the only spec
/// available covers SAP. The paths below follow this backend's evident
/// conventions but are **not confirmed against a live service**, so they are
/// grouped and commented rather than presented as settled fact. Confirm each
/// before wiring a datasource to it.
///
/// Nothing SAP-shaped belongs here. Business partners, customer master,
/// quotations, sales orders, products, inventory, territory and depot are the
/// ERP's, and live in `SapEndpoints`.
abstract final class IsiEndpoints {
  const IsiEndpoints._();

  /// Version prefix, e.g. `/api/v1`.
  static String get _base => '/api/${IsiConfig.apiVersion}';

  // ── Authentication ───────────────────────────────────────────────────
  static String get login => '$_base/auth/login';
  static String get logout => '$_base/auth/logout';
  static String get refresh => '$_base/auth/refresh';
  static String get forgotPassword => '$_base/auth/forgot-password';
  static String get resetPassword => '$_base/auth/reset-password';
  static String get verifyOtp => '$_base/auth/verify-otp';

  // ── User profile ─────────────────────────────────────────────────────
  static String get me => '$_base/users/me';
  static String get updateProfile => '$_base/users/me';
  static String get preferences => '$_base/users/me/preferences';

  // ── Notifications ────────────────────────────────────────────────────
  static String get notifications => '$_base/notifications';
  static String markNotificationRead(String id) =>
      '$_base/notifications/$id/read';
  static String get registerDevice => '$_base/notifications/devices';

  // ── App configuration & feature flags ────────────────────────────────
  static String get appConfig => '$_base/config';
  static String get featureFlags => '$_base/config/features';

  // ── Analytics ────────────────────────────────────────────────────────
  static String get trackEvents => '$_base/analytics/events';

  // ── Customer-adjacent app data (ISI-owned, not SAP) ───────────────────
  //
  // Notes a rep types and the activity timeline are app-native: SAP has no
  // concept of them. See
  // `features/customers/data/datasource/remote/isi/customer_remote_datasource.dart`
  // for why their push is not implemented yet.
  static String customerNotes(String customerId) =>
      '$_base/customers/$customerId/notes';
  static String customerActivities(String customerId) =>
      '$_base/customers/$customerId/activities';
}
