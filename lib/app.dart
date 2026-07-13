import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/local/app_preferences.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_theme.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_typography.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/bloc/language_cubit.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/domain/entities/app_theme_mode.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/presentation/cubit/theme_cubit.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/presentation/cubit/theme_state.dart';
import 'package:isi_steel_sales_mobile/routes/app_page.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

/// Replaces Material 3's default Android "stretch" overscroll (which visibly
/// grows/stretches content when scrolling past its bounds, even on screens
/// shorter than the viewport) with plain clamping — content stops at its
/// edges instead of bouncing/stretching, app-wide.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

// app.dart

/// One-shot latch so the splash screen is used as the initial route only on the
/// very first build (cold boot). Language changes recreate [MaterialApp], which
/// re-runs the initial-route resolver — without this, those rebuilds could
/// replay the splash. Module-private and set exactly once for the process.
bool _splashShown = false;

class ISISteelSalesApp extends StatelessWidget {
  const ISISteelSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              GetIt.instance<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider.value(value: GetIt.instance<LanguageCubit>()),
        BlocProvider.value(value: GetIt.instance<ThemeCubit>()),
      ],
      // Navigation is intentionally *not* driven from a global auth listener.
      // Each surface owns its own transition — Splash routes on boot, the login
      // form advances on success, and logout returns to the shell as a guest —
      // which keeps guests from being yanked around and avoids duplicate
      // redirects. This root only decides the *initial* route on (re)build.
      child: ScreenUtilInit(
          designSize: const Size(390, 844),
          // Full "restart" on language change: the ValueKey below is rebuilt
          // with the new language code, which tears down and recreates the
          // entire MaterialApp/Navigator so every screen — and all the data it
          // loads — comes back up in the freshly selected language. Signed-in
          // users and guests land straight back on the shell (not the splash)
          // via the auth-aware initial route.
          builder: (context, child) => BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              final authState = context.read<AuthBloc>().state;
              final initialRoute = _resolveInitialRoute(authState);
              final fontFamily = AppTypography.fontFamilyForLocale(locale);
              // Only the theme *mode* drives this rebuild — the two ThemeData
              // objects themselves are cached in AppTheme, so switching light
              // ⇄ dark never re-derives a theme and the whole app restyles in
              // one frame with no restart.
              return BlocSelector<ThemeCubit, ThemeState, AppThemeMode>(
                selector: (state) => state.mode,
                builder: (context, themeMode) {
                  return MaterialApp(
                    key: ValueKey('lang_${locale.languageCode}'),
                    navigatorKey: navigatorKey, // Assign the key here
                    title: 'ISI Steel Sales',
                    debugShowCheckedModeBanner: false,
                    scrollBehavior: _AppScrollBehavior(),
                    theme: AppTheme.light(fontFamily),
                    darkTheme: AppTheme.dark(fontFamily),
                    themeMode: _materialThemeMode(themeMode),
                    locale: locale,
                    initialRoute: initialRoute,
                    // Build the initial route as a single page (avoids Flutter's
                    // default '/'-splitting pulling in a not-found parent route).
                    onGenerateInitialRoutes: (name) => [
                      AppPages.onGenerateRoute(RouteSettings(name: name))
                    ],
                    onGenerateRoute: AppPages.onGenerateRoute,
                  );
                },
              );
            },
          ),
        ),
    );
  }

  /// Resolves the route the freshly-built [MaterialApp]/Navigator should open
  /// on. Called on cold boot and again on every language change (which rebuilds
  /// the app), so it must be stable and idempotent:
  ///
  ///  • an authenticated user or a guest who has finished onboarding goes
  ///    straight to the shell — no splash replay when they switch languages
  ///    mid-session;
  ///  • the very first cold boot shows the splash exactly once (it then routes
  ///    on onboarding status);
  ///  • later rebuilds before onboarding is done reopen language selection
  ///    directly, so toggling a language on that screen never flashes splash.
  String _resolveInitialRoute(AuthState authState) {
    final onboarded = GetIt.instance<AppPreferences>().isOnboardingComplete;
    final resolved = authState is AuthenticatedState || authState is AuthGuestState;
    if (onboarded && resolved) return Static.main;
    if (!_splashShown) {
      _splashShown = true;
      return Static.splash;
    }
    return onboarded ? Static.main : Static.chooseLanguage;
  }

  /// Maps the app's [AppThemeMode] onto Flutter's [ThemeMode]. `system` is
  /// modelled and persisted today; `MaterialApp` already honours it via the
  /// provided `theme`/`darkTheme` pair, so surfacing it in the UI later needs
  /// no further wiring here.
  ThemeMode _materialThemeMode(AppThemeMode mode) => switch (mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };
}
