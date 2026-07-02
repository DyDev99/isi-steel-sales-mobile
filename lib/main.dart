import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/app.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart'; // Import the new file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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