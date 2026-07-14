import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/app.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart'; // Import the new file
import 'package:isi_steel_sales_mobile/core/storage/hive/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Boxes must be open before any dependency (e.g. AppPreferences) reads them
  await HiveService.init();

  // Initialize all dependencies
  await initDependencies();

  // Now the app can safely start
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ISISteelSalesApp());
}
