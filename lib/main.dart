import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/app.dart';
import 'package:isi_steel_sales_mobile/core/bootstrap/app_bootstrap_service.dart';
import 'package:isi_steel_sales_mobile/core/bootstrap/error_boundary.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/notifications/push_messaging_service.dart';

Future<void> main() async {
  // Constructed directly rather than resolved from DI: it has to be able to
  // report a failure in DI itself, so it cannot depend on DI succeeding.
  const AppLogger logger = ConsoleAppLogger();

  // Installed first, before anything can throw. A build error, an uncaught
  // async error, or a widget that fails to build is now logged and contained
  // instead of replacing the screen with an error box nobody records.
  ErrorBoundary.install(logger);

  ErrorBoundary.runGuarded(logger, () async {
    WidgetsFlutterBinding.ensureInitialized();

    // All initialization lives in AppBootstrapService so the boot sequence has
    // one documented, testable home. It performs no network I/O and no
    // navigation — see that class's doc comment for why (ADR-002 §3/§5,
    // OFFLINE_FIRST §2.2).
    await const AppBootstrapService().run();

    // Push is deliberately NOT started here. `NotificationCoordinator.start()`
    // runs from `NotificationHost`, under `MaterialApp`, because two of its
    // steps need things that do not exist yet at this point in boot:
    //
    //   * Android notification channels are created with **translated** names,
    //     and the language bundle is loaded asynchronously by `LanguageCubit`
    //     when the widget tree builds. Android caches a channel's name at
    //     creation and ignores later renames — so creating them here would pin
    //     every rep's system settings to raw localisation keys, permanently.
    //   * A tapped notification has to navigate, and there is no Navigator
    //     until `MaterialApp` exists.
    //
    // The one exception is the debug token dump below, which needs the
    // transport but none of the rest.
    //
    // Fire-and-forget: `getToken()` is a network round trip on first mint, and
    // boot must never block on the network (ADR-002 §3).
    unawaited(printFcmTokenForDebugging());

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // The app starts regardless of bootstrap outcome: SplashScreen owns the
    // first transition and a guest can always browse local data. Surfacing a
    // hard boot error screen would contradict "offline is a normal state, not
    // an error state" (ADR-002 §4).
    runApp(const ISISteelSalesApp());
  });
}

/// Prints this installation's FCM registration token to the console.
///
/// TODO(release-gate): debug-only. Remove or leave guarded — never ship a build
/// where this can run.
///
/// ## Why you want this
///
/// Sending a test push from the Firebase console needs the token, and there is
/// no other way to read it off a real handset. Run the app and look for:
///
///     [isi.debug] FCM token: <token>
///
/// ## Why it is guarded the way it is
///
/// `kDebugMode` is a compile-time constant, so the whole body is **tree-shaken
/// out of a release build** rather than merely skipped at runtime. That matters:
/// a registration token is a credential — it addresses pushes to one specific
/// handset — and `docs/skills/SECURITY.md` §10 keeps credentials out of logs.
///
/// It uses `debugPrint` rather than [AppLogger] deliberately. `LogRedactor`
/// replaces any field whose key matches `token` with `***REDACTED***`, which is
/// exactly right for every other caller and would make this line useless.
/// Bypassing the redactor is the reason the `kDebugMode` fence is not optional.
///
/// ## What "null" means here
///
/// On **iOS** the token is null until APNs issues one, and APNs only does that
/// after the notification permission is granted — which
/// `docs/features/notification-mobile.md` §14 defers to the in-app explainer, on
/// purpose. So a null on a fresh iOS install is correct, not broken: accept the
/// explainer, then hot-restart. On **web** there is no transport at all
/// (ADR-010).
Future<void> printFcmTokenForDebugging() async {
  if (!kDebugMode) return;

  try {
    // Resolved from DI rather than constructing the Firebase service directly:
    // the concrete class only exists on native, and importing it here would
    // break the web build outright.
    final messaging = sl<PushMessagingService>();

    if (!messaging.isSupported) {
      debugPrint('[isi.debug] FCM: no push transport on this platform.');
      return;
    }

    // Idempotent, and safe to run ahead of `NotificationCoordinator.start()` —
    // which is what normally initialises it, and which will simply see the work
    // already done.
    await messaging.initialize();

    final token = await messaging.token();
    if (token == null || token.isEmpty) {
      debugPrint(
        '[isi.debug] FCM token: not issued yet. On iOS this is expected until '
        'the notification permission is granted — accept the in-app prompt, '
        'then hot-restart.',
      );
      return;
    }

    debugPrint('[isi.debug] FCM token: $token');
  } catch (error) {
    // Never fatal, and never rethrown into `runGuarded`: a diagnostic aid that
    // can take the app down is worse than no diagnostic aid. The usual cause is
    // a missing or mismatched `google-services.json` / `GoogleService-Info.plist`,
    // which is worth naming because the symptom is otherwise silence.
    debugPrint('[isi.debug] FCM token unavailable: $error');
  }
}
