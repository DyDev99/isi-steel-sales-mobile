import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/screens/active_route_screen.dart';
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
            create: (_) => GetIt.instance<PipelineBloc>()..add(const PipelineLoadRequested()),
            child: const PipelineScreen(initialStage: PipelineStage.leads),
          ),
          settings,
        );

      case Static.order:
        return _page(const OrderScreen(), settings);

      case Static.routes:
        return _page(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => GetIt.instance<ActiveRouteBloc>()..add(const ActiveRouteLoadRequested('routeId')),
              ),
              BlocProvider(
                create: (_) => GetIt.instance<LocationTrackingCubit>(),
              ),
              BlocProvider(
                create: (_) => GetIt.instance<VisitCubit>(),
              ),
            ],
            child: const ActiveRouteScreen(),
          ),
          settings,
        );

        case Static.profile:
          return _page(
            BlocProvider(
              create: (_) => sl<ProfileCubit>(),
              child: const ProfileScreen(),
            ),
            settings,
          );
      default:
        return _page(_NotFound(name: settings.name), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) {
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