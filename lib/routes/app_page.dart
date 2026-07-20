import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/create_new_password_screen.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/success_screen.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/verify_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/events/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:isi_steel_sales_mobile/features/splash/presentation/language_selection_screen.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

// Screens
import 'package:isi_steel_sales_mobile/features/splash/presentation/splash_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/main_shell.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/data/home_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/pipeline_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/order_screen.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_dashboard_screen.dart';

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

      case Static.lead:
        return _page(
          BlocProvider(
            create: (_) => GetIt.instance<PipelineBloc>()
              ..add(const PipelineLoadRequested()),
            child: const PipelineScreen(initialStage: PipelineStage.leads),
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
            child: const MyVisitsDashboardScreen(),
          ),
          settings,
        );

      case Static.chooseLanguage:
        return _page(const LanguageSelectionScreen(), settings);

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
              onSubmit: (identifier) async {
                // TODO: replace with your real reset-request call
                await Future.delayed(const Duration(seconds: 1));
                const result = ForgotPasswordResult.success();

                if (result.isSuccess) {
                  // 👉 this is what gets you to the 6-box verify screen
                  Navigator.of(context).pushNamed(
                    Static.verifyOtp,
                    arguments: identifier,
                  );
                }
                return result;
              },
              onBackToLogin: () => Navigator.of(context).pop(),
            ),
          ),
          settings,
        );
      case Static.createNewPassword:
        final args = settings.arguments as Map<String, String>? ?? {};
        return _page(
          Builder(
            builder: (context) => CreateNewPasswordScreen(
              onSubmit: (newPassword) async {
                // TODO: call your actual reset endpoint with
                // args['target'], args['code'], newPassword

                await Future.delayed(const Duration(seconds: 1));
                return const ResetPasswordResult.success();
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
        final target = settings.arguments as String? ?? '';
        return _page(
          Builder(
            builder: (context) => VerifyScreen(
              target: target,
              onVerify: (code) async {
                // TODO: wire this to your actual OTP verification call —
                // e.g. context.read<AuthBloc>().add(VerifyOtpRequestedEvent(target, code))
                // and await/convert the resulting state, or call a repository
                // method directly. Placeholder below just simulates a network call
                // and accepts the mock token 111111 for UI testing.
                await Future.delayed(const Duration(seconds: 1));
                if (code == '111111') {
                  return const VerifyResult.success();
                }
                return VerifyResult.failure('auth.invalid_code'.tr);
              },
              // No onVerified: falls back to VerifyScreen's built-in navigation to
              // CreateNewPasswordScreen. Provide onVerified here once AuthBloc/reset
              // routing exists to override that behaviour.
              onResend: () async {
                // TODO: re-trigger the forgot-password request for `target`.
                await Future.delayed(const Duration(seconds: 1));
              },
              onBackToLogin: () => Navigator.of(context).pop(),
            ),
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
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route: ${name ?? "(null)"}')),
    );
  }
}
