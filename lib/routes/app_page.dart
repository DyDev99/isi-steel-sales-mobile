import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/create_new_password_screen.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/success_screen.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/verify_otp_args.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/verify_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/events/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_dashboard/stop_dashboard_screen.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:isi_steel_sales_mobile/core/notifications/notification_deep_link.dart';
import 'package:isi_steel_sales_mobile/features/notification/notification_coordinator.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/screen/notification_preferences_screen.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/screen/notifications_screen.dart';
import 'package:isi_steel_sales_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:isi_steel_sales_mobile/features/splash/presentation/language_selection_screen.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

// Screens
import 'package:isi_steel_sales_mobile/features/splash/presentation/splash_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/main_shell.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/data/home_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/order_screen.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/login_screen.dart';

/// Flow: splash (6s) -> login -> (on success) -> main shell.
class AppPages {
  AppPages._();

  // app_page.dart
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Static.splash:
        return _page(const SplashScreen(), settings);

      case Static.login:
        // REMOVED BlocProvider here. It is now provided at the root.
        return _page(const LoginScreen(), settings);

      case Static.main:
        return _page(const MainShell(), settings);

      // Deep-link routes into a single MainShell tab (see Static's doc
      // comment) — each provides its own bloc/cubit since these are reached
      // directly, not via MainShell's IndexedStack.
      case Static.home:
        return _page(
          BlocProvider(
            create: (_) => HomeCubit(const HomeRepositoryImpl())..load(),
            child: const HomeScreen(userName: 'there'),
          ),
          settings,
        );

      case Static.order:
        return _page(const OrderScreen(), settings);

      case Static.myVisits:
        return _page(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => GetIt.instance<ActiveRouteBloc>()
                  ..add(const ActiveRouteLoadRequested('routeId')),
              ),
              BlocProvider(
                create: (_) => GetIt.instance<LocationTrackingCubit>(),
              ),
              BlocProvider(
                create: (_) => GetIt.instance<VisitCubit>(),
              ),
            ],
            child: const StopDashboardScreen(),
          ),
          settings,
        );

      case Static.chooseLanguage:
        return _page(const LanguageSelectionScreen(), settings);

      case Static.onboarding:
        return _page(const OnboardingScreen(), settings);

      // The notification inbox as a real route, not only a bottom sheet.
      //
      // `app://notifications` is §11's fallback for **every** unroutable deep
      // link — an event that names no single record, and any URI pointing at a
      // screen this build does not have yet. A cold start from a notification
      // tap has nothing underneath to raise a sheet over, so that fallback needs
      // a route with a back button.
      case NotificationDeepLink.inboxRoute:
        return _page(
          // Tapping a row routes on its own `deep_link` — the backend builds
          // those (§11), so this hands the link straight back to the resolver
          // rather than deriving a destination from the entity fields.
          NotificationsScreen(
            onOpenNotification: (notification) =>
                sl<NotificationCoordinator>().openLink(notification.deepLink),
          ),
          settings,
        );

      case NotificationDeepLink.notificationSettingsRoute:
        return _page(const NotificationPreferencesScreen(), settings);

      case Static.profile:
        return _page(
          BlocProvider(
            create: (_) => sl<ProfileCubit>(),
            child: const ProfileScreen(),
          ),
          settings,
        );
      case Static.forgotPassword:
        return _page(
          Builder(
            builder: (context) => ForgotPasswordScreen(
              // `POST /auth/forgot-password { email }`. The field is
              // documented as taking an e-mail address; this app now sends a
              // phone number into it. `AuthRepositoryImpl.forgotPassword`
              // forwards the value untouched under the `email` key rather
              // than reinterpreting it, so whether the backend resolves a
              // phone number the way `/auth/login`'s `employeeId` resolves
              // an ID-or-e-mail is a question for the API team, not a claim
              // this client makes for itself.
              //
              // Deliberately does **not** navigate: `ForgotPasswordScreen`
              // already pushes `Static.verifyOtp` itself, tagged
              // `VerifyOtpArgs.passwordReset`, once this returns success. A
              // second push here — with a bare `String` argument the route no
              // longer accepts — double-navigated and crashed on the
              // `as VerifyOtpArgs?` cast.
              onSubmit: (identifier) async {
                final result = await GetIt.instance<AuthRepository>()
                    .forgotPassword(identifier);
                return result.when(
                  // `forgot-password` always answers success, whether or not
                  // the address exists — reporting otherwise turns the
                  // endpoint into an account-enumeration oracle.
                  success: (_) => const ForgotPasswordResult.success(),
                  failure: (f) => ForgotPasswordResult.failure(f.message),
                );
              },
              onBackToLogin: () => Navigator.of(context).pop(),
            ),
          ),
          settings,
        );
      case Static.createNewPassword:
        // Carried from VerifyScreen: {'target': phoneNumber, 'code': otp}.
        // `code` is the value the user typed on the verify screen — it is
        // sent to `/auth/reset-password` as `token`. There is no separate
        // "confirm the code" step for this flow the way sign-in has
        // `verify-otp`: the code and the new password are submitted together,
        // and a wrong code fails this single call.
        final resetArgs =
            settings.arguments as Map<String, dynamic>? ?? const {};
        return _page(
          Builder(
            builder: (context) => CreateNewPasswordScreen(
              onSubmit: (newPassword) async {
                final result =
                    await GetIt.instance<AuthRepository>().resetPassword(
                  email: resetArgs['target'] as String? ?? '',
                  token: resetArgs['code'] as String? ?? '',
                  newPassword: newPassword,
                );
                return result.when(
                  success: (_) => const ResetPasswordResult.success(),
                  failure: (f) => ResetPasswordResult.failure(f.message),
                );
              },
              onSuccess: () => Navigator.of(context).pushReplacementNamed(
                Static.resetPasswordSuccess,
              ),
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          settings,
        );

      case Static.resetPasswordSuccess:
        return _page(
          Builder(
            builder: (context) => SuccessScreen(
              title: 'auth.reset_password_success_title'.tr,
              subtitle: 'auth.reset_password_success_subtitle'.tr,
              buttonLabel: 'auth.back_to_login'.tr,
              onContinue: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(Static.login, (route) => false),
            ),
          ),
          settings,
        );
      case Static.verifyOtp:
        // `VerifyScreen` serves two journeys that look identical to the user
        // and differ completely underneath, so the origin is passed
        // explicitly. Inferring it from the stack would break the first time
        // anything deep-links here.
        final args = settings.arguments as VerifyOtpArgs?;

        // Password reset. The code *is* the reset token and cannot be checked
        // on its own — `/auth/reset-password` takes `{email, token,
        // newPassword}` together — so this screen only collects it and hands
        // it to the new-password screen, which submits both.
        if (args != null && !args.isLogin) {
          return _page(
            Builder(
              builder: (context) => VerifyScreen(
                target: args.target,
                // No `onVerify` round trip to the server here: unlike sign-in,
                // this flow has no separate "confirm the code" endpoint. The
                // code is submitted together with the new password at
                // `/auth/reset-password`, on the next screen — see
                // `Static.createNewPassword`. A wrong code fails that single
                // call rather than this one.
                onVerify: (_) async => const VerifyResult.success(),
                // `/auth/forgot-password` has no dedicated resend — sending
                // another request is the same call as the first one, and the
                // guide's "always answers success" rule applies here exactly
                // as it did to the original request.
                onResend: () async {
                  await GetIt.instance<AuthRepository>()
                      .forgotPassword(args.target);
                },
                onBackToLogin: () => Navigator.of(context).maybePop(),
              ),
            ),
            settings,
          );
        }

        // Sign-in.
        return _page(
          Builder(
            builder: (context) {
              final auth = context.read<AuthBloc>();

              return BlocListener<AuthBloc, AuthState>(
                // Routing is driven by the bloc: a session exists only once
                // step 3 has run, and `AuthenticatedState` is that fact.
                listenWhen: (prev, curr) => curr is AuthenticatedState,
                listener: (context, _) => Navigator.of(context)
                    .pushNamedAndRemoveUntil(Static.main, (route) => false),
                child: VerifyScreen(
                  target: args?.target ?? '',
                  // Server configuration, not constants.
                  codeLength: args?.challenge?.challenge.otpLength ?? 6,
                  resendCooldown: args?.challenge?.challenge.window ??
                      const Duration(seconds: 30),
                  // Supplied so the screen does *not* fall through to its
                  // built-in password-reset navigation — sign-in goes to the
                  // shell, and the BlocListener above owns that move.
                  onVerified: (_) {},
                  onVerify: (code) async {
                    auth.add(OtpSubmitted(code));

                    final settled = await auth.stream.firstWhere((s) =>
                        s is AuthenticatedState || s is AuthOtpFailureState);

                    return switch (settled) {
                      // Five wrong codes, an expired window or a spent id all
                      // mean the attempt is dead: start again at step 1.
                      AuthOtpFailureState(:final message, attemptDead: true) =>
                        () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              Static.login, (route) => false);
                          return VerifyResult.failure(message);
                        }(),
                      AuthOtpFailureState(:final message) =>
                        VerifyResult.failure(message),
                      _ => const VerifyResult.success(),
                    };
                  },
                  onResend: () async => auth.add(const OtpResendRequested()),
                  // No token exists yet — step 3 never ran — so abandoning
                  // leaves no credential behind.
                  onBackToLogin: () {
                    auth.add(const OtpAbandoned());
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          ),
          settings,
        );
      default:
        return _page(_NotFound(name: settings.name), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(
      Widget child, RouteSettings settings) {
    // Wrap every named route so its whole subtree (including MainShell and its
    // five tabs) rebuilds live when the language changes — the "hot reload"
    // localization effect, applied app-wide from one place.
    return MaterialPageRoute<dynamic>(
      builder: (_) => LocalizedBuilder(builder: (_) => child),
      settings: settings,
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('app.not_found'.tr)),
      body: Center(
          child: Text('app.no_route'.trParams({'name': name ?? '(null)'}))),
    );
  }
}
