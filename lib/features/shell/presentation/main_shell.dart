import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/data/home_repository.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/add_customer_bloc.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/pipeline_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/order_screen.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/screens/customers_screen.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/route_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/screens/route_dashboard_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/glass_nav_bar.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/main_app_bar.dart';

/// App shell: owns the bottom nav and hosts the five tabs.
///
/// Tabs live in a LAZY IndexedStack — each is built only when first visited,
/// then kept alive so its scroll/filters survive tab switches. Each tab
/// provides its own bloc, so state stays scoped to that feature.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = <NavTab>[
    NavTab(Icons.home_rounded, 'Home'),
    NavTab(Icons.lightbulb_rounded, 'Leads'),
    NavTab(Icons.receipt_long_rounded, 'Orders'),
    NavTab(Icons.trending_up_rounded, 'Routes'),
    NavTab(Icons.people_rounded, 'Customers'),
  ];

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<ProfileCubit>(),
        child: const ProfileScreen(),
      ),
    ));
  }

  static const _titles = <String>['Home', 'Leads', 'Orders', 'Active Routes', 'Customers'];

  late final List<Widget?> _built = List<Widget?>.filled(_tabs.length, null);

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => HomeCubit(const HomeRepositoryImpl())..load(),
                  ),
                  BlocProvider(
                    create: (_) => sl<AddCustomerBloc>(),
                  ),
                ],
                child: const HomeScreen(userName: 'there'),
              );
      case 1:
        return BlocProvider(
          create: (_) => sl<PipelineBloc>()..add(const PipelineLoadRequested()),
          child: const PipelineScreen(initialStage: PipelineStage.leads),
        );
      case 2:
        return const OrderScreen();
      // In main_shell.dart (Case 3 in your switch statement)
      case 3:
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<RouteDashboardCubit>()..load()),
            BlocProvider(create: (_) => sl<RouteSyncCubit>()),
          ],
          child: const RouteDashboardScreen(),   // was ActiveRouteScreen
        );
      default:
        return const CustomersScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    _built[_index] ??= _buildTab(_index); // lazily build the visited tab

    return Scaffold(
      backgroundColor: Vibe.bg,
      body: Column(
        children: [
          MainAppBar(
            title: _titles[_index],
            onAvatarTap: () => _openProfile(context),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: List.generate(
                _tabs.length,
                (i) => _built[i] ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: GlassNavBar(
        tabs: _tabs,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}