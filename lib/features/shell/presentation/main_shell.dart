import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/data/home_repository.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/add_customer_bloc.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/pipeline_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_dashboard_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/order_screen.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/screens/customers_screen.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/add_customer_bottom_sheet.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/add_visit_bottom_sheet.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/main_app_bar.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/home_action_grid.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/home_pipeline_card.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

class NavTab {
  final IconData icon;
  final String label;

  NavTab(this.icon, this.label);
}

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
    setState(() {
      _index = _tabController.value;
    });
  }

  List<NavTab> get _tabs => [
        NavTab(Icons.grid_view_rounded, 'home.title'.tr),
        NavTab(Icons.people_alt_rounded, 'customers.title'.tr),
        NavTab(Icons.location_on_rounded, 'my_visits.title'.tr),
        NavTab(Icons.trending_up_rounded, 'leads.title'.tr), 
        NavTab(Icons.receipt_long_rounded, 'orders.title'.tr),
      ];

  List<String> get _titles => [
        'home.title'.tr,
        'customers.title'.tr,
        'my_visits.title'.tr,
        'leads.title'.tr,
        'orders.title'.tr,
      ];

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<ProfileCubit>(),
        child: LocalizedBuilder(builder: (_) => const ProfileScreen()),
      ),
    ));
  }

  Future<void> _openCalendarPicker(BuildContext context) async {
    await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Vibe.brandNavy, 
              onPrimary: Colors.white,
              onSurface: Vibe.text,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
  final int dayNumber = DateTime.now().day;
  final int hour = DateTime.now().hour;

  late final String greetingKey;
  if (hour < 12) {
    greetingKey = 'common.good_morning';
  } else if (hour < 17) {
    greetingKey = 'common.good_afternoon';
  } else {
    greetingKey = 'common.good_evening';
  }

  return Padding(
    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Side: Greeting Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greetingKey.tr, 
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.h),
              Text(
                'Sokha Novel', 
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        SizedBox(width: 8.w),

        // Right Side: Action row grouping Visit, Customer, and Calendar with white shadows
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Add Visit Action Button
            GestureDetector(
              onTap: () => showAddVisitSheet(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25), // White premium shadow glow
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded, size: 15.w, color: Vibe.accentPurple),
                    SizedBox(width: 3.w),
                    Text(
                      'my_visits.add_my_visits'.tr,
                      style: TextStyle(
                        fontSize: 10.5.sp, 
                        fontWeight: FontWeight.w700,
                        color: Vibe.accentPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(width: 6.w),

            // 2. Add Customer Action Button
            GestureDetector(
              onTap: () => showAddCustomerSheet(context),
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: Vibe.brandNavy, 
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2), // White glow on dark background
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 16.w),
              ),
            ),
            
            SizedBox(width: 6.w),

            // 3. Calendar Day Action Picker
            GestureDetector(
              onTap: () => _openCalendarPicker(context),
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25), // Consistent white shadow
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: Vibe.brandNavy, 
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
  
  Widget _buildHomeTab() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeCubit(const HomeRepositoryImpl())..load()),
        BlocProvider(create: (_) => sl<AddCustomerBloc>()),
      ],
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: SizedBox(height: 80.h), 
                ),
                
                _buildWelcomeSection(context),
                
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0.h),    
                  child: GestureDetector(
                    onTap: () => _tabController.goTo(3),
                    child: const HomePipelineCard(),
                  ),
                ),
                
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                    children: [
                      HomeActionGrid(
                        onCustomersTap: () => _tabController.goTo(1),
                        onVisitsTap: () => _tabController.goTo(2),
                        onOrdersTap: () => _tabController.goTo(4),
                        onRevenueTap: () => Navigator.of(context).pushNamed(Static.revenue),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ],
            ),
          ),

         
        ],
      ),
    );
  }


  Widget _buildTab(int i) {
    Widget wrapWithTopSpacing(Widget screen) {
      return Padding(
        padding: EdgeInsets.only(top: 80.h), 
        child: screen,
      );
    }

    switch (i) {
      case 0:
        return _buildHomeTab();
      case 1:
        return wrapWithTopSpacing(const CustomersScreen());
      case 2:
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<RouteDashboardCubit>()..load()),
            BlocProvider(create: (_) => sl<RouteSyncCubit>()),
          ],
          child: wrapWithTopSpacing(const MyVisitsDashboardScreen()),
        );
      case 3:
        return BlocProvider(
          create: (_) => sl<PipelineBloc>()..add(const PipelineLoadRequested()),
          child: wrapWithTopSpacing(const PipelineScreen(initialStage: PipelineStage.leads)),
        );
      case 4:
        return wrapWithTopSpacing(const OrderScreen());
      default:
        return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _tabs.length) _index = 0;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _tabController.goTo(0);
      },
      child: Scaffold(
        backgroundColor: Vibe.canvas,
        body: Stack(
          children: [
            if (_index == 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.28,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Vibe.brandNavyDark, Vibe.brandNavy], 
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32.r),
                      bottomRight: Radius.circular(32.r),
                    ),
                  ),
                ),
              ),
            Theme(
              data: Theme.of(context).copyWith(
                scaffoldBackgroundColor: Colors.transparent,
              ),
              child: Positioned.fill(
                child: IndexedStack(
                  index: _index,
                  // FIX: Removed the manual array allocation cache to let layout dynamically re-translate on change
                  children: List.generate(
                    _tabs.length,
                    (i) => _buildTab(i),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: MainAppBar(
                title: _titles[_index],
                currentTabIndex: _index,
                onBackToHomeTap: () => _tabController.goTo(0),
                onAvatarTap: () => _openProfile(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}