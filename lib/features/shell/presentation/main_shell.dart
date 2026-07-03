import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
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

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ShellTabController _tabController = sl<ShellTabController>();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = _tabController.value;
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    setState(() => _index = _tabController.value);
  }

  // FIXED: Changed to a dynamic getter so .tr updates automatically
  List<NavTab> get _tabs => [
        NavTab(Icons.home_rounded, 'home.title'.tr),
        NavTab(Icons.trending_up_rounded, 'routes.title'.tr),
        NavTab(Icons.lightbulb_rounded, 'leads.title'.tr),
        NavTab(Icons.receipt_long_rounded, 'orders.title'.tr),
        NavTab(Icons.people_rounded, 'customers.title'.tr),
      ];

  // FIXED: Changed to a dynamic getter so titles change languages cleanly
  List<String> get _titles => [
        'home.title'.tr,
        'routes.title'.tr,
        'leads.title'.tr,
        'orders.title'.tr,
        'customers.title'.tr,
      ];

  // Keep tracking lazy loading setup based on tab index size
  late final List<Widget?> _built = List<Widget?>.filled(5, null);

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<ProfileCubit>(),
        child: const ProfileScreen(),
      ),
    ));
  }

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
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<RouteDashboardCubit>()..load()),
            BlocProvider(create: (_) => sl<RouteSyncCubit>()),
          ],
          child: const RouteDashboardScreen(),
        );
      case 2:
        return BlocProvider(
          create: (_) => sl<PipelineBloc>()..add(const PipelineLoadRequested()),
          child: const PipelineScreen(initialStage: PipelineStage.leads),
        );
      case 3:
        return const OrderScreen();
      default:
        return const CustomersScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    _built[_index] ??= _buildTab(_index); // lazily build the visited tab

    return PopScope(
      // On the Home tab, let back behave normally (exit app). On any other
      // tab, back should return to Home instead of exiting/popping past MainShell.
      canPop: _index == ShellTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _tabController.goTo(ShellTab.home);
      },
      child: Scaffold(
        backgroundColor: Vibe.bg,
        body: Column(
          children: [
            MainAppBar(
              title: _titles[_index],
              currentTabIndex: _index,
              onBackToHomeTap: () => _tabController.goTo(ShellTab.home),
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
      //  bottomNavigationBar: GlassNavBar(
      //    tabs: _tabs,
      //    currentIndex: _index,
      //    onTap: (i) => setState(() => _index = i),
      //  ),
      ),
    );
  }
}