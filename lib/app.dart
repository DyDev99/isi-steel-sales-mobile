import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/routes/app_page.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

// app.dart
class ISISteelSalesApp extends StatelessWidget {
  const ISISteelSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<AuthBloc>()..add(const AuthCheckRequested()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(Static.main, (route) => false);
          } else if (state is UnauthenticatedState) {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(Static.login, (route) => false);
          }
        },
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            navigatorKey: navigatorKey, // Assign the key here
            title: 'ISI Steel Sales',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            initialRoute: Static.splash,
            onGenerateRoute: AppPages.onGenerateRoute,
          ),
        ),
      ),
    );
  }
  // ... _buildTheme remains the same

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      // Make AppBar transparent so screens that use a Stack + background
      // don't get a conflicting solid bar.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1F2937)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}