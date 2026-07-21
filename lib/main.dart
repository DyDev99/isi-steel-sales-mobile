import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/app.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/sap_native_transport.dart';
import 'package:isi_steel_sales_mobile/core/bootstrap/app_bootstrap_service.dart';
import 'package:isi_steel_sales_mobile/core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // All initialization lives in AppBootstrapService so the boot sequence has one
  // documented, testable home. It performs no network I/O and no navigation —
  // see that class's doc comment for why (ADR-002 §3/§5, OFFLINE_FIRST §2.2).
  await const AppBootstrapService().run();

  // TEMPORARY diagnostic — remove once the transport decision is made.
  // Sends `{}` (never credentials); the server answers 400, which proves the
  // whole TLS + HTTP path works through the platform stack.
  if (kDebugMode && SapNativeTransport.isSupported) {
    try {
      final r = await SapNativeTransport.post(
        url: '${Env.sapBaseUrlPrimary}/api/Auth/Login',
        body: '{}',
      );
      debugPrint('[native-tls] >>> PLATFORM STACK WORKS — HTTP ${r.statusCode} <<<');
    } catch (e) {
      debugPrint('[native-tls] >>> PLATFORM STACK FAILS <<< $e');
    }
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // The app starts regardless of bootstrap outcome: SplashScreen owns the first
  // transition and a guest can always browse local data. Surfacing a hard boot
  // error screen would contradict "offline is a normal state, not an error
  // state" (ADR-002 §4).
  runApp(const ISISteelSalesApp());
}
