# Notifications — Mobile Build & Integration Guide

**For:** Flutter engineers on the SteelForce Sales Rep app
**Backend:** ISI SteelForce 360 · `ISI.Api` v1 · Phase 1 complete
**Verified:** 9 Sep 2026 — a real push was delivered end-to-end from these credentials

> Everything in Part 1 was verified against the live Firebase project, and every
> package version in Part 2 was resolved against this repo's actual dependency graph.
> No guessed versions, no invented paths.

---

## Contents

| Part | |
|---|---|
| **1** | [Verified facts](#part-1--verified-facts) — project ids, what works today |
| **2** | [Make it build](#part-2--make-it-build) — pubspec, Android, iOS, step by step |
| **3** | [Drop-in code](#part-3--drop-in-code) — matched to this app's architecture |
| **4** | [API reference](#part-4--api-reference) |
| **5** | [Behaviour rules](#part-5--behaviour-rules-that-bite) |
| **6** | [Troubleshooting](#part-6--troubleshooting) |

---

# Part 1 — Verified facts

```
Firebase project   steelforce-94963
Android package    com.isigroup.steelforce
iOS bundle         com.isigroup.steelforce
Backend project    ✅ authenticated, real push delivered 9 Sep 2026
```

> **Corrected 9 Sep 2026.** This table previously read `com.isigroup.steelsales`
> for both platforms. The shipped app is `com.isigroup.steelforce` — that is what
> `applicationId`, `namespace`, the iOS `PRODUCT_BUNDLE_IDENTIFIER`, and **both
> config files already registered in `steelforce-94963`** all say. Renaming the
> app to match the old text would have created a second Play listing and broken
> the Android build at `processDebugGoogleServices`, so the document was the
> thing that was wrong.

## What already works

| | |
|---|---|
| Backend → FCM | ✅ Verified. Service account authenticates, FCM accepts and delivers. |
| Inbox API | ✅ 14 endpoints live |
| Device registry | ✅ Upsert on `deviceId`, auto-deactivates dead tokens |
| Preferences | ✅ Quiet hours, per-category opt-out |
| Delivery log | ✅ Per-channel, with skip reasons |

## What is still missing

| Blocker | Owner | Status |
|---|---|---|
| `android/app/google-services.json` | Firebase console owner | ✅ present, `com.isigroup.steelforce` |
| `ios/Runner/GoogleService-Info.plist` | ″ | ✅ present **and in Copy Bundle Resources** |
| **APNs `.p8` uploaded to Firebase** | ″ | ⏳ **outstanding — iOS fails silently without it** |
| Firebase packages in `pubspec.yaml` | Mobile | ✅ done, versions pinned per Part 2 |

**Nothing in Part 2 or 3 will work until the two config files exist.** Adding
`firebase_core` without `google-services.json` fails the Android build outright.

The plist needed the Xcode step spelled out in Step 1: it was committed to the
repo but never added to the project, so it was not copied into `Runner.app` and
`Firebase.initializeApp()` threw `[core/not-initialized]` on every launch. Being
on disk is not enough.

## The one thing to understand

> **The inbox is the notification. Push is only an accelerator.**

Every notification is written to the database *before* FCM is called. Push then fails
routinely — flat battery, coverage hole, denied permission, OEM battery killer, rotated
token, Google having a bad afternoon.

**Design so a dropped push costs nothing.** If your only path to a route assignment is
`onMessage`, reps will miss work. Pull the inbox on every foreground.

```
Backend                                   Device
   │
   ├──▶ Notification row ─────────────▶  GET /mobile/notifications   ← GUARANTEED
   │    (system of record)                (poll + catch-up)
   │
   └──▶ FCM ──────────────────────────▶  onMessage / onMessageOpenedApp
        (best effort)                      ← ACCELERATOR ONLY
```

---

# Part 2 — Make it build

## Step 1 · Config files

Drop these in, from the **`steelforce-94963`** project:

```
frontend/android/app/google-services.json
frontend/ios/Runner/GoogleService-Info.plist
```

Add the plist to the Xcode target (drag into `Runner` → tick *Copy items if needed*,
target **Runner**). Dropping it in Finder alone is not enough — it must be in
*Build Phases → Copy Bundle Resources*.

Verify both name the right project:

```bash
grep project_id  android/app/google-services.json     # → steelforce-94963
plutil -p ios/Runner/GoogleService-Info.plist | grep -E 'PROJECT_ID|BUNDLE_ID'
```

> **Gitignore them.** They are not high-severity secrets, but they identify your
> project and should not be in a public repo. Add to `frontend/.gitignore`:
> ```gitignore
> android/app/google-services.json
> ios/Runner/GoogleService-Info.plist
> ```

## Step 2 · Packages

These versions resolve cleanly against this app's existing graph on
**Flutter 3.44.9 / Dart 3.12.2** — verified, not guessed:

```bash
cd frontend
flutter pub add firebase_core firebase_messaging flutter_local_notifications
```

| Package | Resolved | Why |
|---|---|---|
| `firebase_core` | 4.14.0 | Required by messaging |
| `firebase_messaging` | 16.6.0 | FCM |
| `flutter_local_notifications` | 22.3.0 | **Android foreground banners.** FCM does not display a notification while the app is foregrounded — you must render it yourself. |

`permission_handler` (13.0.2) also resolves, but **you do not need it** —
`firebase_messaging` has `requestPermission()` built in. Skip the extra dependency.

`timezone 0.11.1` arrives transitively via local_notifications. Harmless.

## Step 3 · Android

Your `settings.gradle.kts` uses the modern declarative plugins block (AGP 9.0.1,
Kotlin 2.3.20). Add the Google Services plugin there — **not** the old
`buildscript`/`classpath` style, which will not work with this setup:

```kotlin
// android/settings.gradle.kts
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false   // ← add
}
```

```kotlin
// android/app/build.gradle.kts — in the existing plugins { } block
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")        // ← add, must be last
}
```

`minSdk` comes from `flutter.minSdkVersion` — FCM needs 21+, and Flutter's floor is
already above that, so nothing to change.

**Android 13+ needs the runtime permission.** `firebase_messaging` declares
`POST_NOTIFICATIONS` in its own manifest, so you do not add it — but you *must* call
`requestPermission()` (Part 3) or the user never sees a notification.

### Notification channels

The backend sets a `channel_id` per category. **Create them at startup or Android
silently drops the notification into a default channel** and the rep loses per-category
control in system settings.

| Channel id | Category | Importance |
|---|---|---|
| `assignment` | ASSIGNMENT | HIGH |
| `finance` | FINANCE | HIGH |
| `approvals` | APPROVAL | HIGH |
| `security` | SECURITY | HIGH |
| `quotes` | QUOTE | DEFAULT |
| `orders` | ORDER | DEFAULT |
| `account` | ACCOUNT | DEFAULT |
| `system` | SYSTEM | DEFAULT |
| `announcements` | ANNOUNCE | DEFAULT |
| `kpi` | KPI | LOW |

## Step 4 · iOS

**Deployment target must be 15.0, not 14.0.**

`firebase_core` 4.14.0 and `firebase_messaging` 16.6.0 — the versions Step 2
pins — both declare a minimum iOS platform of **15.0**. The build fails outright:

```
Target Integrity (Xcode): The package product 'firebase-core' requires minimum
platform version 15.0 for the iOS platform, but this target supports 14.0
```

So `ios/Podfile` and all three `IPHONEOS_DEPLOYMENT_TARGET` entries in
`Runner.xcodeproj` are now 15.0. This drops **no hardware** — iOS 15 supports
exactly the same devices as iOS 14 (iPhone 6s and later); iOS 16 is where that
list actually shrinks. Only users who have declined to update past iOS 14 are
affected.

(The earlier text here said "already 14.0 — fine, FCM needs 12+". That is true of
FCM in the abstract and false for the pinned versions.)

**1. Xcode capabilities** — Runner target → *Signing & Capabilities* → **+**:
- **Push Notifications**
- **Background Modes** → tick *Remote notifications*

**2. `AppDelegate.swift`** — no change needed. `firebase_core` configures Firebase from
Dart, and `firebase_messaging` 16.x swizzles the APNs callbacks automatically. Do **not**
add `FirebaseApp.configure()` — it double-initialises and throws.

**3. Podfile** — no change. `pod install` runs via `flutter run`.

**4. Real device only.** The iOS Simulator cannot receive remote push. Android
emulators can, if they have Play Services.

## Step 5 · Verify the build

```bash
cd frontend
flutter pub get
flutter analyze          # baseline: 17 pre-existing info/warnings, 0 errors
flutter run              # real iOS device for push
```

---

# Part 3 — Drop-in code

Written against **your** architecture — `get_it` (`sl`), `dio_client`, `ApiEnvelope`,
`DeviceIdentity`, `AppBootstrapService`. No new patterns introduced.

## 3.1 · Reuse `DeviceIdentity` — do not mint your own id

You already have exactly the right thing at
`lib/core/device/device_identity.dart`: a stable per-installation UUID in secure
storage, and `describe({pushToken})` that already threads a push token into the login
body.

> **Never send the FCM token as `deviceId`.** Tokens rotate; installations do not. Using
> the token as the key creates a new device row on every rotation, and the backend ends
> up pushing to a pile of dead registrations.

## 3.2 · `lib/core/services/push_notification_service.dart`

```dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isi_steel_sales_mobile/core/device/device_identity.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';

/// Must be a top-level function — the OS spawns a separate isolate for it, so it
/// cannot close over anything from the app.
///
/// Deliberately does almost nothing. The inbox is the system of record and the
/// catch-up call on next foreground will collect this notification anyway; doing
/// real work here risks being killed mid-write by the OS.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Owns FCM: permission, token lifecycle, and turning a delivered message into
/// something the app reacts to.
///
/// It does **not** own the inbox. Notifications are read from
/// `GET /mobile/notifications`; this class only accelerates and routes.
class PushNotificationService {
  PushNotificationService({
    required DeviceIdentity deviceIdentity,
    required AppLogger logger,
    required Future<void> Function(String token) registerToken,
  })  : _deviceIdentity = deviceIdentity,
        _logger = logger,
        _registerToken = registerToken;

  final DeviceIdentity _deviceIdentity;
  final AppLogger _logger;
  final Future<void> Function(String token) _registerToken;

  final _local = FlutterLocalNotificationsPlugin();

  /// Deep links tapped before the router is ready, or before sign-in completes.
  /// Held rather than dropped — losing the link is the difference between landing
  /// on the route the rep tapped and landing on a home screen.
  String? pendingDeepLink;

  final _deepLinks = StreamController<String>.broadcast();

  /// Deep links to navigate to. Listen once, near the router.
  Stream<String> get deepLinks => _deepLinks.stream;

  final _inboxChanged = StreamController<void>.broadcast();

  /// Fires when a push suggests the inbox has moved. Refresh badges and the list.
  Stream<void> get inboxChanged => _inboxChanged.stream;

  StreamSubscription<String>? _tokenRefresh;

  /// Call once, after Firebase.initializeApp(), before the first frame.
  Future<void> initialise() async {
    await _createAndroidChannels();

    // Foreground: suppress the OS banner on iOS so we can render our own card.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: false);

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    // Terminated → tapped. MUST be checked at startup or the tap is swallowed
    // with no error and the rep thinks the notification did nothing.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onOpened(initial);

    // Tokens rotate without warning. Re-register on every rotation, or the
    // backend keeps pushing at an address that no longer resolves.
    _tokenRefresh = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(_safeRegister(token));
    });
  }

  /// Ask for the OS permission. Call this AFTER the rep has seen their first
  /// route, never on first launch — iOS gives exactly one prompt, ever.
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    _logger.info('Push permission: ${settings.authorizationStatus}');
    await syncToken(permissionGranted: granted);

    return granted;
  }

  /// Push the current token to the backend. Safe to call on every launch —
  /// registration is idempotent on deviceId.
  Future<void> syncToken({bool? permissionGranted}) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        _logger.warn('No FCM token available; skipping device registration.');
        return;
      }
      await _safeRegister(token);
    } catch (error, stack) {
      // Never fatal. A rep who cannot register for push must still be able to
      // use the app — the inbox works without it.
      _logger.error('Device registration failed', error, stack);
    }
  }

  Future<void> _safeRegister(String token) async {
    try {
      await _registerToken(token);
    } catch (error, stack) {
      _logger.error('Device registration failed', error, stack);
    }
  }

  void _onForeground(RemoteMessage message) {
    _inboxChanged.add(null);

    // Android shows nothing for a foreground message, so render it ourselves.
    // iOS is handled by setForegroundNotificationPresentationOptions above plus
    // whatever in-app card the UI layer decides to show.
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdFor(message.data['category']),
          _channelIdFor(message.data['category']),
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['deep_link'],
    );
  }

  void _onOpened(RemoteMessage message) {
    final link = message.data['deep_link'] ?? message.data['action'];
    if (link == null || link.isEmpty) return;

    _inboxChanged.add(null);
    _deepLinks.add(link);
  }

  Future<void> _createAndroidChannels() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,   // firebase_messaging owns the prompt
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final link = response.payload;
        if (link != null && link.isNotEmpty) _deepLinks.add(link);
      },
    );

    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // One channel per backend category. Without these Android drops everything
    // into a default channel and per-category system settings stop working.
    const high = <String>['assignment', 'finance', 'approvals', 'security'];
    const low = <String>['kpi'];
    const normal = <String>['quotes', 'orders', 'account', 'system', 'announcements'];

    for (final id in [...high, ...normal, ...low]) {
      await android.createNotificationChannel(AndroidNotificationChannel(
        id,
        id,
        importance: high.contains(id)
            ? Importance.high
            : low.contains(id)
                ? Importance.low
                : Importance.defaultImportance,
      ));
    }
  }

  String _channelIdFor(String? category) => switch (category) {
        'ASSIGNMENT' => 'assignment',
        'QUOTE' => 'quotes',
        'ORDER' => 'orders',
        'FINANCE' => 'finance',
        'APPROVAL' => 'approvals',
        'KPI' => 'kpi',
        'ACCOUNT' => 'account',
        'ANNOUNCE' => 'announcements',
        'SECURITY' => 'security',
        _ => 'system',
      };

  Future<void> dispose() async {
    await _tokenRefresh?.cancel();
    await _deepLinks.close();
    await _inboxChanged.close();
  }
}
```

## 3.3 · Registering the device

```dart
// lib/features/notifications/data/notification_api.dart
class NotificationApi {
  NotificationApi(this._dio, this._deviceIdentity);

  final Dio _dio;
  final DeviceIdentity _deviceIdentity;

  Future<void> registerDevice({
    required String pushToken,
    required bool permissionGranted,
  }) async {
    final response = await _dio.post<Object?>(
      '/mobile/devices/register',
      data: {
        // The SAME id used for /auth/login and /auth/refresh. Reusing it is what
        // keeps one installation to one device row.
        'deviceId': await _deviceIdentity.deviceId(),
        'pushToken': pushToken,
        'platform': Platform.isIOS ? 'IOS' : 'Android',
        'deviceName': await _deviceLabel(),
        'appVersion': (await PackageInfo.fromPlatform()).version,
        'osVersion': Platform.operatingSystemVersion,
        'locale': Platform.localeName,

        // IANA zone. Quiet hours and digests are wall-clock facts — without this
        // the backend assumes UTC and a 22:00 quiet window starts at 05:00 local.
        'timeZone': await _ianaTimeZone(),
        'pushPermissionGranted': permissionGranted,
      },
    );

    ApiEnvelope.fromBody(response.data);   // throws on a malformed envelope
  }

  Future<void> deregisterDevice() async {
    // Call BEFORE discarding the access token on sign-out, or the platform keeps
    // pushing one rep's notifications at a handset handed to somebody else.
    await _dio.delete<Object?>(
      '/mobile/devices/${await _deviceIdentity.deviceId()}',
    );
  }
}
```

## 3.4 · Wiring into bootstrap and DI

```dart
// lib/main.dart — before runApp
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
await di.init();
await sl<PushNotificationService>().initialise();
```

```dart
// lib/core/di/injection_container.dart — matching the existing sl style
sl.registerLazySingleton<NotificationApi>(() => NotificationApi(sl(), sl()));

sl.registerLazySingleton<PushNotificationService>(() => PushNotificationService(
      deviceIdentity: sl(),
      logger: sl(),
      registerToken: (token) => sl<NotificationApi>().registerDevice(
        pushToken: token,
        permissionGranted: true,
      ),
    ));
```

**Call `syncToken()` on every launch and after login** — not only the first time.

## 3.5 · Routing a deep link

```dart
sl<PushNotificationService>().deepLinks.listen((link) {
  if (!sl<SessionManager>().isAuthenticated) {
    // Preserve it across login. Dropping it here is why "tapping the
    // notification just opens the app" bugs happen.
    sl<PushNotificationService>().pendingDeepLink = link;
    router.go(AppRoutes.login);
    return;
  }
  router.go(_toAppRoute(link));
});

/// app://routes/{id} → /routes/{id}
String _toAppRoute(String deepLink) =>
    deepLink.replaceFirst('app://', '/');
```

Drain `pendingDeepLink` immediately after a successful login.

---

# Part 4 — API reference

Base `{host}/api/v1/mobile` · `Authorization: Bearer {token}` ·
`Accept-Language: km-KH | en-US`

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/mobile/devices/register` | Register / refresh push token |
| `GET` | `/mobile/devices` | List this rep's installations |
| `DELETE` | `/mobile/devices/{deviceId}` | Deregister on sign-out |
| `GET` | `/mobile/notifications` | Inbox / catch-up |
| `GET` | `/mobile/notifications/unread-count` | Badge figures |
| `PATCH` | `/mobile/notifications/{id}/read` | Mark one read |
| `PATCH` | `/mobile/notifications/read-all` | Mark all read (`?category=`) |
| `POST` | `/mobile/notifications/{id}/action` | Record that the rep **acted** |
| `DELETE` | `/mobile/notifications/{id}` | Dismiss |
| `GET` | `/mobile/notifications/preferences` | Settings screen |
| `PUT` | `/mobile/notifications/preferences` | Save settings |

Success uses your standard `ApiEnvelope`. Failures are **not** wrapped — they are
RFC 9457 problem documents. **Branch on `errorCode`, never on `detail`.**

## The notification object

Field names are `snake_case` here (they follow the published spec, unlike the rest of
the API):

```json
{
  "notification_id": "0198f2c1-9d3e-7f77-a1b2-4c9d8e7f6a5b",
  "event_code": "ROUTE.ASSIGNED",
  "category": "ASSIGNMENT",
  "priority": "P2",
  "title": "New route assigned — Wed, 26 Aug",
  "body": "North Phnom Penh R3: 12 stops from 08:00. Tap to review and confirm.",
  "deep_link": "app://routes/0198f2b0-1111-7000-8000-000000000001",
  "web_link": "/routes/0198f2b0-...",
  "requires_ack": true,
  "expires_at": null,
  "group_key": "Assignment:0198f2b0-...",
  "badge": 3,
  "actions": [
    {"id": "view", "label": "View Route", "type": "deeplink",
     "endpoint": null, "method": null, "destructive": false}
  ],
  "data": {"entity_type": "route", "entity_id": "0198f2b0-...", "stop_count": "12"},
  "state": "unread",
  "created_at": "2026-08-25T08:12:04Z",
  "delivered_at": "2026-08-25T08:12:04Z",
  "read_at": null,
  "actioned_at": null
}
```

### `state`

```
                 ┌──────────┐  read   ┌────────┐  acted  ┌────────────┐
   created ─────▶│  unread  │────────▶│  read  │────────▶│  actioned  │
                 └────┬─────┘         └───┬────┘         └────────────┘
                      │                   │
           ┌──────────┼───────────────────┤
           ▼          ▼                   ▼
     ┌───────────┐ ┌─────────┐  ┌────────────────────┐
     │ dismissed │ │ expired │  │ resolved_elsewhere │
     └───────────┘ └─────────┘  └────────────────────┘
```

Nothing is ever deleted. `expired` and `resolved_elsewhere` stay in history, greyed,
with an explanatory subtitle.

### `priority`

| Tier | Quiet hours | Opt-out | Push |
|---|---|---|---|
| `P1` Critical | **bypassed** | **bypassed** | high priority, alert tone |
| `P2` High | deferred | honoured | heads-up banner |
| `P3` Normal | deferred | honoured | silent-capable |
| `P4` Low | never pushed | honoured | **inbox only** |

**P4 never arrives as a push.** If your only render path is the FCM callback, every
digest is invisible.

## FCM payload

```json
{
  "notification": {"title": "New route assigned — Wed, 26 Aug", "body": "…"},
  "data": {
    "notification_id": "0198f2c1-…",
    "event_code": "ROUTE.ASSIGNED",
    "type": "ROUTE_ASSIGNED",
    "category": "ASSIGNMENT",
    "priority": "P2",
    "deep_link": "app://routes/0198f2b0-…",
    "action": "app://routes/0198f2b0-…",
    "entity_type": "route",   "referenceType": "ROUTE",
    "entity_id": "0198f2b0-…", "referenceId": "0198f2b0-…"
  }
}
```

Two naming conventions ship deliberately — canonical spec fields *and* the mobile
shorthand. Pick one set and be consistent.

> ⚠️ **Every FCM data value is a string.** `"stop_count": "12"`, not `12`.

## Deep links

| Destination | URI |
|---|---|
| Route | `app://routes/{routeId}` |
| Stop | `app://routes/{routeId}/stops/{stopId}` |
| Today | `app://today` |
| Quotation | `app://quotations/{quoteId}` |
| Order | `app://orders/{orderId}` (`?tab=credit`) |
| Approvals | `app://approvals?filter={type}` |
| Customer | `app://customers/{customerId}` |
| Dashboard | `app://dashboard?period={period}` |
| Inbox | `app://notifications` |

**The backend builds these — do not assemble your own.**

---

# Part 5 — Behaviour rules that bite

## Reading is not acting

A route assignment that has been **read** still counts against the badge and still
escalates to a supervisor. Only `POST /action` closes it.

Wiring "scrolled past it" to `/read` is right. Wiring it to `/action` silently breaks
the escalation chain the assignment flow depends on.

## The badge counts work, not mail

- App-icon badge ← `action_required`
- Inbox tab ← `unread`
- Nav sections ← `by_category`

Reconcile against the server on every sync. A local counter drifts the first time a
push is dropped, and a badge nobody trusts is a badge everybody ignores.

## The catch-up cursor

> Store `metadata.syncTimestamp`. Send it back as `since`. **Never the device clock.**

A handset running ten minutes fast that sends `DateTime.now()` asks for "changes since
the future" and silently receives nothing, for ever, with no error. This is the single
most common way an offline-first notification client breaks.

```dart
Future<void> catchUp() async {
  final cursor = await _prefs.getString('notif_cursor');

  final res = await _dio.get('/mobile/notifications', queryParameters: {
    if (cursor != null) 'since': cursor,
    'pageSize': 100,
  });

  final envelope = ApiEnvelope.fromBody(res.data);
  for (final json in envelope.data['items'] as List) {
    await _db.upsertNotification(json);   // idempotent on notification_id
  }
  await _prefs.setString('notif_cursor', envelope.metadata!.syncTimestamp);
}
```

Run it on start, foreground, pull-to-refresh and reconnect.

## Offline actions and 409

`409 Notification.AlreadyResolved` means somebody else decided first. Show the current
state — **do not retry**. Replaying an action already recorded returns `204`, so a
draining queue never stalls on its own success.

You already have `SyncQueueService` — route notification actions through it.

## Permission priming

Do not request on first launch. iOS gives you one prompt, ever.

```
Login → Onboarding → rep sees their first route
   → in-app explainer: "Get notified the moment a route needs you."  [Enable] [Not now]
   → Enable → OS prompt → register with pushPermissionGranted: true
```

If declined: register anyway with `false`, show a banner linking to system settings,
re-prompt at most once every 14 days. **The inbox works without the permission.**

---

# Part 6 — Troubleshooting

## Nothing arrives on Android

| Check | |
|---|---|
| `google-services.json` present and matching `steelforce-94963`? | |
| `com.google.gms.google-services` plugin applied? | Build fails loudly if not |
| Notification channels created at startup? | Silent drop if not |
| `requestPermission()` called on Android 13+? | Silent drop if not |
| Device registered? | `GET /mobile/devices` → `isActive: true` |
| OEM battery killer? | Xiaomi/Oppo/Vivo/Huawei — whitelist the app |

## Nothing arrives on iOS

**In order of likelihood:**

1. **APNs `.p8` not uploaded to Firebase.** ← by far the most common. FCM returns a
   message ID and nothing arrives. There is no error anywhere.
2. Testing on the Simulator — cannot receive push. Use a real device.
3. Push Notifications capability not added in Xcode.
4. Background Modes → Remote notifications not ticked.
5. `GoogleService-Info.plist` not in *Copy Bundle Resources*.

## Diagnosing from the backend

```bash
POST /api/v1/admin/notifications/test-push
{ "pushToken": "…" }
```

Returns **200 even when refused** — the provider's verdict is the payload:

| `errorCode` | Meaning | Fix |
|---|---|---|
| `NOT_CONFIGURED` | Backend has no credentials | Set `Firebase:CredentialsPath` |
| `UNREGISTERED` | Token dead — uninstalled or rotated | Fresh `getToken()` |
| `SenderIdMismatch` | Token from a **different Firebase project** | Check the config files |
| `AUTH_REJECTED` | Credentials rejected | Check the service account |
| `PROVIDER_ERROR` | Google unreachable | Transient, retry |

Writes nothing — no inbox row, no log entry. Safe to run repeatedly.

Also useful: `GET /api/v1/admin/notifications/logs?recipientId=…` shows per-channel
outcomes including skip reasons (`QUIET_HOURS`, `OPTED_OUT`, `NO_DEVICE`, `PRIORITY`).

---

## Build checklist

**Config**
- [x] `google-services.json` + `GoogleService-Info.plist` from `steelforce-94963`
- [x] plist in Xcode *Copy Bundle Resources*
- [ ] **APNs `.p8` uploaded to Firebase Console** ← the one remaining blocker for iOS
- [ ] Both gitignored — entries are in `.gitignore`, but the files are still
      **tracked**, so they are inert until
      `git rm --cached android/app/google-services.json ios/Runner/GoogleService-Info.plist`.
      Coordinate first: every developer and CI needs the files out of band.

**Build**
- [x] `firebase_core` 4.14.0, `firebase_messaging` 16.6.0, `flutter_local_notifications` 22.3.0
- [x] `com.google.gms.google-services` 4.4.4 in both Gradle files
- [x] iOS deployment target raised to 15.0 (forced by Firebase — see Step 4)
- [x] Core library desugaring enabled on Android (required by `flutter_local_notifications`)
- [ ] Push Notifications + Background Modes capabilities on the App ID in the
      Apple Developer account (the `aps-environment` entitlement is already wired)

**Startup**
- [ ] `Firebase.initializeApp()` before `runApp`
- [ ] `onBackgroundMessage` registered with a top-level `@pragma('vm:entry-point')` handler
- [ ] All ten Android channels created
- [ ] `getInitialMessage()` checked
- [ ] `onTokenRefresh` wired

**Auth**
- [ ] Register after login and on every launch, reusing `DeviceIdentity.deviceId()`
- [ ] Deregister **before** discarding the token on sign-out
- [ ] Deep link preserved across an expired-session login

**Inbox**
- [ ] Upserts keyed on `notification_id`
- [ ] Cursor is `syncTimestamp`, never the device clock
- [ ] Badge from `action_required`
- [ ] `requires_ack` items pinned and not swipeable
- [ ] `/read` and `/action` on different gestures
- [ ] 409 handled with a visible explanation

---

## Status

| | |
|---|---|
| Inbox, devices, preferences, push, delivery log | ✅ Phase 1 complete |
| Business events (route assigned, quote approved…) | ⏳ Phase 2+. Catalogue and deep links published now so you can build against them; nothing raises them yet. |
| Email / SMS / WebSocket | ⏳ Queued and visible in the log, adapters not registered |
| `ROUTE.ASSIGNED` vs `ROUTE_ASSIGNED` | ⚠️ Both ship in the payload pending sign-off |
