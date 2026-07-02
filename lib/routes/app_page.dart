import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

// Screens
import 'package:isi_steel_sales_mobile/features/splash/presentation/splash_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/main_shell.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/data/home_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/lead_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/order_screen.dart';
import 'package:isi_steel_sales_mobile/features/opportunity/presentation/screens/opportunity_screen.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/login_screen.dart';

// Auth bloc + states (used to detect a successful login)
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';

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

      case Static.home:
        return _page(
          BlocProvider(
            create: (_) => HomeCubit(const HomeRepositoryImpl())..load(),
            child: const HomeScreen(userName: 'there'),
          ),
          settings,
        );

      case Static.lead:
        return _page(const LeadScreen(), settings);
      case Static.order:
        return _page(const OrderScreen(), settings);
      case Static.opportunity:
        return _page(const OpportunityScreen(), settings);

      default:
        return _page(_NotFound(name: settings.name), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(builder: (_) => child, settings: settings);
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