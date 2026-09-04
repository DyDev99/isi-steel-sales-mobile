/// Centralised, compile-time app constants. No logic here — just values.
class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────────────
  // NOTE: there is deliberately no `baseUrl` constant here. The gateway host is
  // environment-specific and comes from `AppConfig.apiBaseUrl` (see
  // `AppNetwork`). A hardcoded literal previously lived here and pinned every
  // build — including QA and staging — to the production host.
  /// Every documented route is rooted at `https://<host>/api/v1`
  /// (`docs/Authentication-guild-integratemobile.md`, "Base URL"). Only the
  /// host varies per environment, and that half comes from
  /// `AppConfig.apiBaseUrl`.
  static const String apiPrefix = '/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // ── Auth endpoints ─────────────────────────────────────────────────
  // `login`, `refresh` and `token` are OAuth 2.0 endpoints: they answer with
  // `{error, error_description}` at HTTP 400, *not* with a problem document
  // and not with 401. Everything else answers RFC 9457. See `ApiError`.
  static const String loginEndpoint = '$apiPrefix/auth/login';

  // ── Phone sign-in with OTP (sales reps) ────────────────────────────
  //
  // Three requests in order: send-otp checks the password and returns a
  // `verificationId`; verify-otp confirms the code and issues **no token**;
  // mobileLogin exchanges the spent id for the token pair.
  //
  // Note the format split — steps 1, 2 and resend answer problem+json, but
  // `mobileLoginEndpoint` is an OAuth token endpoint and answers
  // `{error, error_description, error_uri}`. One flow, two parsers.
  static const String sendOtpEndpoint = '$apiPrefix/mobile/auth/send-otp';
  static const String verifyOtpEndpoint = '$apiPrefix/mobile/auth/verify-otp';
  static const String resendOtpEndpoint = '$apiPrefix/mobile/auth/resend-otp';
  static const String mobileLoginEndpoint = '$apiPrefix/mobile/auth/login';
  static const String refreshEndpoint = '$apiPrefix/auth/refresh';
  static const String tokenEndpoint = '$apiPrefix/auth/token';
  static const String logoutEndpoint = '$apiPrefix/auth/logout';
  static const String currentUserEndpoint = '$apiPrefix/auth/me';
  static const String sessionsEndpoint = '$apiPrefix/auth/sessions';
  static const String changePasswordEndpoint =
      '$apiPrefix/auth/change-password';
  static const String forgotPasswordEndpoint =
      '$apiPrefix/auth/forgot-password';
  static const String resetPasswordEndpoint = '$apiPrefix/auth/reset-password';
  static const String verifyEmailEndpoint = '$apiPrefix/auth/verify-email';
  static const String resendVerificationEndpoint =
      '$apiPrefix/auth/resend-verification';

  /// Routes that must never trigger the interceptor's refresh-and-replay: a
  /// 401 from one of these is the answer, not a stale-token symptom.
  static const Set<String> authRoutes = {
    loginEndpoint,
    refreshEndpoint,
    tokenEndpoint,
    // The phone flow establishes a session; a 401 from any of these is the
    // answer, not a stale-token symptom.
    sendOtpEndpoint,
    verifyOtpEndpoint,
    resendOtpEndpoint,
    mobileLoginEndpoint,
  };

  // ── Mobile customer endpoints ──────────────────────────────────────
  static const String customersEndpoint = '$apiPrefix/mobile/customers';

  /// `GET /customers/by-code/{code}` — the **portal** surface, deliberately not
  /// under `/mobile`.
  ///
  /// It answers with the portal envelope (`data` + `meta`, no `success`) and the
  /// portal customer shape (`code` not `customerCode`, a nested `address`, a
  /// bare `creditLimit` number), so it needs its own parser. Documented as a
  /// rough edge rather than a design — see
  /// `docs/feature/customer/mobile/mobile.md` §Looking a customer up by code.
  static const String customersByCodeEndpoint = '$apiPrefix/customers/by-code';

  /// The server clamps `pageSize` to this rather than rejecting a larger
  /// value, so the real size must be read back from `metadata.pageSize`.
  static const int maxPageSize = 200;

  // ── Mobile materials endpoints ─────────────────────────────────────
  //
  // The guided selection surface, per
  // `docs/feature/order/product-selection/api.md`.
  // All of them require `materials.read` and answer the standard envelope; a
  // 403 with no `errorCode` means the role is missing that permission, not
  // that the request is malformed.
  //
  // None of these calls SAP — they read the platform's own synced copy of the
  // material master, which is why the finder keeps working when the ERP does
  // not. The one exception is [materialAvailabilityEndpoint], which is a live
  // SAP round trip and must only be called when a rep commits to a material.
  static const String materialsEndpoint = '$apiPrefix/mobile/materials';

  /// Stage zero — the categories that open the finder.
  static const String materialCategoriesEndpoint =
      '$materialsEndpoint/selection/categories';

  /// The wizard's shape for one category (or every published one).
  /// Configuration, not catalogue data: fetch once per session and cache it.
  static const String materialSchemaEndpoint =
      '$materialsEndpoint/selection/schema';

  /// The options for exactly one step. `{attribute, selection}`.
  static const String materialFacetsEndpoint =
      '$materialsEndpoint/selection/facets';

  /// The terminal read. `{selection, page, pageSize, search}` — note the
  /// different body shape from the facet call; putting the selection fields at
  /// the top level here is silently read as an empty selection.
  static const String materialSelectionEndpoint =
      '$materialsEndpoint/selection/materials';

  /// Banded on-hand stock for one material, with a per-plant breakdown.
  ///
  /// `{ material, band, isSellable, baseUnit, plants[], checkedAt }` — a band
  /// (`High` / `Medium` / `Low` / `None`), never a quantity. This is the read
  /// the order flow uses to decide whether a rep may set a quantity at all.
  static String materialStockEndpoint(String material) =>
      '$materialsEndpoint/$material/stock';

  /// SAP's live sellability verdict for one material.
  ///
  /// Note the path: this one sits at `/materials/...`, **not** under the
  /// `/mobile/` prefix the rest of this block uses. Verified against the
  /// staging host; deriving it from [materialsEndpoint] would 404.
  ///
  /// Unlike every other call here it is a live SAP round trip, so it is slow
  /// and it fails when the middleware is down. Call it when a rep commits to a
  /// material — never while they browse.
  static String materialAvailabilityEndpoint(String material) =>
      '$apiPrefix/materials/$material/availability';

  /// Customer-specific prices for one or more materials.
  ///
  /// `GET /mobile/pricing/customers/{customerId}?materials=A&materials=B` —
  /// the `materials` parameter repeats rather than taking a delimited list, so
  /// a quotation with eight lines is one round trip instead of eight.
  static String customerPricingEndpoint(String customerId) =>
      '$apiPrefix/mobile/pricing/customers/$customerId';

  /// The realtime pricing hub. The access token rides on the query string,
  /// which is the transport's own contract — browsers and sockets cannot set
  /// an Authorization header on the handshake.
  static const String pricingHubPath = '/hubs/pricing';

  /// The material list is one-based, like every other paged mobile endpoint.
  static const int firstPage = 1;

  // ── Mobile visit endpoints (docs/feature/my-visits/api.md) ──────────────
  //
  // Scope is always the signed-in rep: the server derives `repId` from the
  // bearer token. The client sends `territory` to narrow the result set, never
  // as an authorisation claim — a client-supplied rep identity is not trusted
  // and is not sent.
  /// `GET` — the rep's routes, paginated, with a flat de-duplicated
  /// `customers` list each stop joins to by `customerId`.
  static const String visitRoutesEndpoint = '$apiPrefix/mobile/visits/routes';

  /// `GET` — same body shape as [visitRoutesEndpoint], narrowed by `since`.
  /// Deliberately a full re-pull of the rep's current scoped set rather than a
  /// row-level diff: a rep has a handful of routes a day, so the simplicity is
  /// worth more than the bytes.
  static const String visitRoutesDeltaEndpoint = '$visitRoutesEndpoint/delta';

  /// `POST` — one batch carrying every pending capture of every kind.
  /// Answers 200 with an accepted/rejected id split; a single bad row must
  /// never fail the batch.
  static const String visitPushEndpoint = '$apiPrefix/mobile/visits/push';

  // ── Mobile notification endpoints ──────────────────────────────────
  //
  // Per `docs/feature/notification/README.md` §3. The same routes also exist
  // without the `/mobile` segment for the admin portal — same handlers,
  // different envelope. **Use these**, or the response comes back in the
  // portal's shape and every parse fails.
  //
  // All of these require authentication. The inbox and preference routes
  // additionally need `notifications.read`, which every seeded role holds.
  // Device registration deliberately requires **only** authentication: a rep
  // who cannot read notifications must still be able to tell the platform
  // their token changed.

  /// `POST` — register or refresh this installation's FCM token. Idempotent on
  /// `deviceId`, so calling it on every launch costs one cheap round trip;
  /// calling it less often is how a rep silently stops receiving anything
  /// (§4.1).
  static const String deviceRegisterEndpoint =
      '$apiPrefix/mobile/devices/register';

  /// `GET` — the rep's registered installations.
  static const String devicesEndpoint = '$apiPrefix/mobile/devices';

  /// `DELETE` — deregister on sign-out. **Call before discarding the access
  /// token**, or the platform keeps pushing one rep's notifications at a
  /// handset that has since been handed to somebody else (§4.4).
  static String deviceEndpoint(String deviceId) => '$devicesEndpoint/$deviceId';

  /// `GET` — the inbox, paged and filtered. The guaranteed delivery path: this
  /// is what makes a dropped push cost nothing (§1).
  static const String notificationsEndpoint = '$apiPrefix/mobile/notifications';

  /// `GET` — badge figures. Cheap enough to call on every foreground, and the
  /// only correct source for them: a locally incremented counter drifts the
  /// first time a push is dropped (§7).
  static const String notificationCountsEndpoint =
      '$notificationsEndpoint/unread-count';

  /// `PATCH` — mark one read. Idempotent; the first read timestamp wins.
  static String notificationReadEndpoint(String id) =>
      '$notificationsEndpoint/$id/read';

  /// `PATCH` — mark all read, optionally scoped by `?category=`.
  static const String notificationReadAllEndpoint =
      '$notificationsEndpoint/read-all';

  /// `POST` — record that the rep **acted**. The only call that closes an item
  /// requiring acknowledgement; wiring "scrolled past it" here instead of to
  /// `/read` silently breaks the supervisor escalation chain (§8.3).
  static String notificationActionEndpoint(String id) =>
      '$notificationsEndpoint/$id/action';

  /// `DELETE` — dismiss. A state change, not a deletion; answers 409 when the
  /// item requires acknowledgement.
  static String notificationDismissEndpoint(String id) =>
      '$notificationsEndpoint/$id';

  /// `GET`/`PUT` — the settings screen. Build it from the response's
  /// `categories`, never from a list compiled into the app (§13).
  static const String notificationPreferencesEndpoint =
      '$notificationsEndpoint/preferences';

  /// One catch-up page. Comfortably inside the server's clamp of
  /// [maxPageSize] and large enough that a rep returning from a week offline
  /// drains in a handful of round trips (§6.1).
  static const int notificationPageSize = 100;

  /// Safety stop on the catch-up loop.
  ///
  /// A paging bug — a server that always reports `hasNextPage`, or a cursor that
  /// never advances — would otherwise spin until the app is killed, on a rep's
  /// mobile data. Ten pages is 1,000 notifications, far past any real backlog;
  /// hitting it is a defect and is logged as one rather than silently truncated.
  static const int notificationMaxCatchUpPages = 10;

  /// Minimum accepted by `POST /auth/change-password` and `/auth/reset-password`.
  static const int minPasswordLength = 12;

  // ── Secure storage keys ────────────────────────────────────────────
  static const String kAccessToken = 'isi.access_token';
  static const String kRefreshToken = 'isi.refresh_token';
  static const String kCachedUser = 'isi.cached_user';

  /// Per-installation device identifier sent with login and refresh. Survives
  /// restarts, may change on reinstall, never used for authorisation.
  static const String kDeviceId = 'isi.device_id';

  /// Hive key for the cached notification-preferences document (§13).
  ///
  /// Hive rather than the encrypted database, and deliberately: these are the
  /// rep's own toggles and quiet-hours window — settings, not business records
  /// or PII — and they are regenerable from the server on demand
  /// (`docs/blueprint/system-architecture.md` §3, Layer 2). Caching them needs no schema
  /// migration and the cache is never authoritative.
  static const String kNotificationPreferences = 'isi.notification_preferences';

  /// Hive key for when the push-permission explainer was last shown.
  ///
  /// §14 caps re-showing it at once every 14 days after a decline. Local UI
  /// state with nothing sensitive in it, so Hive is the right home.
  static const String kPushExplainerShownAt = 'isi.push_explainer_shown_at';

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
