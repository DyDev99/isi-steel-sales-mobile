import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_typography.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';
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
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

// app.dart
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
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            navigatorKey.currentState
                ?.pushNamedAndRemoveUntil(Static.main, (route) => false);
          } else if (state is UnauthenticatedState) {
            navigatorKey.currentState
                ?.pushNamedAndRemoveUntil(Static.splash, (route) => false);
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
                  : (authState is UnauthenticatedState
                      ? Static.login
                      : Static.splash);
              return MaterialApp(
                key: ValueKey('lang_${locale.languageCode}'),
                navigatorKey: navigatorKey, // Assign the key here
                title: 'ISI Steel Sales',
                debugShowCheckedModeBanner: false,
                scrollBehavior: _AppScrollBehavior(),
                theme: _buildTheme(locale),
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

  ThemeData _buildTheme(Locale locale) {
    // Inter for English/Latin, Kantumruy for Khmer — the whole MaterialApp is
    // rebuilt on language change (keyed by locale), so the font swaps with it.
    final fontFamily = AppTypography.fontFamilyForLocale(locale);
    // Seeded scheme keeps every Material-derived tone (errorContainer,
    // tertiary, outline, ...) that no screen currently overrides; only the
    // slots the app actively renders through are pinned to AppColors so
    // `Theme.of(context).colorScheme` resolves to real design tokens.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.textInverse,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textInverse,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textInverse,
    );

    return ThemeData(
      useMaterial3: true,
      // Global font family — every screen, dialog, and Material widget
      // (AppBar, TextField, SnackBar, DatePicker, ...) inherits Kantumruy
      // from here unless a widget explicitly overrides fontFamily.
      fontFamily: fontFamily,
      textTheme: AppTypography.textTheme(Vibe.text, fontFamily: fontFamily),
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      // One smooth, modern transition for every MaterialPageRoute push,
      // across every platform this runs on.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const ModernPageTransitionsBuilder(),
        },
      ),
      // Make AppBar transparent so screens that use a Stack + background
      // don't get a conflicting solid bar.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.icon),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radius)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppColors.radius)),
        ),
      ),
      // Only touch hint/label/error text colors — no `border`/`filled`
      // defaults, since ~half the app's TextFields build fully custom
      // decorations and a theme-level fill/border would visibly change them.
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textHint),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: TextStyle(color: AppColors.primary),
        errorStyle: TextStyle(color: AppColors.error),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.selected
                : AppColors.unselected,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.selected
                : AppColors.unselected,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textInverse,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.buttonText,
          disabledBackgroundColor: AppColors.unselected,
          disabledForegroundColor: AppColors.textInverse,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radius)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radius)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }
}
