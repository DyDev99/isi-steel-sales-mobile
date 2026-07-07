import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/core/utils/page_transitions.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/bloc/language_cubit.dart';
import 'package:isi_steel_sales_mobile/routes/app_page.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

/// Replaces Material 3's default Android "stretch" overscroll (which visibly
/// grows/stretches content when scrolling past its bounds, even on screens
/// shorter than the viewport) with plain clamping — content stops at its
/// edges instead of bouncing/stretching, app-wide.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

// app.dart
class ISISteelSalesApp extends StatelessWidget {
  const ISISteelSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetIt.instance<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider.value(value: GetIt.instance<LanguageCubit>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
        if (state is AuthenticatedState) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(Static.main, (route) => false);
        } else if (state is UnauthenticatedState) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(Static.splash, (route) => false);
        }
      },
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          // Full "restart" on language change: the ValueKey below is rebuilt
          // with the new language code, which tears down and recreates the
          // entire MaterialApp/Navigator so every screen — and all the data it
          // loads — comes back up in the freshly selected language. Signed-in
          // users land straight back on the shell (not the splash) via the
          // auth-aware initial route.
          builder: (context, child) => BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              final authState = context.read<AuthBloc>().state;
              final initialRoute = authState is AuthenticatedState
                  ? Static.main
                  : (authState is UnauthenticatedState ? Static.login : Static.splash);
              return MaterialApp(
                key: ValueKey('lang_${locale.languageCode}'),
                navigatorKey: navigatorKey, // Assign the key here
                title: 'ISI Steel Sales',
                debugShowCheckedModeBanner: false,
                scrollBehavior: _AppScrollBehavior(),
                theme: _buildTheme(),
                locale: locale,
                initialRoute: initialRoute,
                // Build the initial route as a single page (avoids Flutter's
                // default '/'-splitting pulling in a not-found parent route).
                onGenerateInitialRoutes: (name) =>
                    [AppPages.onGenerateRoute(RouteSettings(name: name))],
                onGenerateRoute: AppPages.onGenerateRoute,
              );
            },
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
      // One smooth, modern transition for every MaterialPageRoute push,
      // across every platform this runs on.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values) platform: const ModernPageTransitionsBuilder(),
        },
      ),
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