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
              primary: Color(0xFF00569B), 
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
                    Icon(Icons.location_on_rounded, size: 15.w, color: const Color(0xFF7C3AED)),
                    SizedBox(width: 3.w),
                    Text(
                      'my_visits.add_my_visits'.tr,
                      style: TextStyle(
                        fontSize: 10.5.sp, 
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
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
                  color: const Color(0xFF00569B), 
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
                      color: const Color(0xFF00569B), 
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
                    child: _buildPipelineSummaryCard(),
                  ),
                ),
                
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                    children: [
                      _buildActionGrid(),
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

  Widget _buildPipelineSummaryCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPipelineItem(
                  icon: Icons.lightbulb_outline_rounded,
                  iconColor: Colors.orange,
                  iconBg: Colors.orange.withValues(alpha: 0.1),
                  value: '12',
                  label: "leads.title".tr,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildPipelineItem(
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF00569B), 
                  iconBg: const Color(0xFF00569B).withValues(alpha: 0.1),
                  value: '5',
                  label: "leads.opportunities".tr,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildPipelineItem(
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.green,
                  iconBg: Colors.green.withValues(alpha: 0.1),
                  value: '2',
                  label: "leads.won_deals".tr,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              'leads.view_leads'.tr,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPipelineItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16.w),
        ),
        SizedBox(height: 6.h),
        Text(value, style: TextStyle(color: Vibe.text, fontWeight: FontWeight.bold, fontSize: 16.sp)),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11.sp),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30.h,
      width: 1,
      color: Vibe.stroke,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10.h, // Decreased from 12.h
      crossAxisSpacing: 10.w, // Decreased from 12.w
      childAspectRatio: 1.15, // Adjusted slightly to optimize vertical space on compact devices
      children: [
        _buildGridCard(
          icon: Icons.people_alt_rounded, 
          iconColor: const Color(0xFF00569B), 
          iconBg: const Color(0xFF00569B).withValues(alpha: 0.1), 
          value: '150', 
          label: 'customers.title'.tr,
          onTap: () => _tabController.goTo(1),
        ),
        _buildGridCard(
          icon: Icons.location_on_rounded, 
          iconColor: Colors.purple, 
          iconBg: Colors.purple.withValues(alpha: 0.1), 
          value: '12', 
          label: 'my_visits.title'.tr,
          onTap: () => _tabController.goTo(2),
        ),
        _buildGridCard(
          icon: Icons.receipt_long_rounded, 
          iconColor: Colors.orange, 
          iconBg: Colors.orange.withValues(alpha: 0.1), 
          value: '45', 
          label: 'orders.sales_order.title'.tr,
          onTap: () => _tabController.goTo(4),
        ),
        _buildRevenueCard(
          achieved: '\$10k',
          target: '\$12.5k',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildRevenueCard({
    required String achieved,
    required String target,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w), // Decreased ~20% from 16.w
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12.r), // Standardized corner radius
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w), // Decreased from 8.w
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1), 
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(Icons.attach_money_rounded, color: Colors.green, size: 16.w), // Decreased from 20.w
            ),
            SizedBox(height: 6.h), // Decreased from 8.h
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: achieved, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Vibe.text), // Decreased from 18.sp
                  ),
                  TextSpan(
                    text: ' ${'home.achieved'.tr}', 
                    style: TextStyle(fontSize: 9.5.sp, color: Colors.grey.shade500), // Decreased from 11.sp
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: target, 
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.sp, color: Colors.grey.shade600), // Decreased from 13.sp
                  ),
                  TextSpan(
                    text: ' ${'home.target'.tr}', 
                    style: TextStyle(fontSize: 9.5.sp, color: Colors.grey.shade500), // Decreased from 11.sp
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required IconData icon, 
    required Color iconColor, 
    required Color iconBg, 
    required String value, 
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(0.w), // Decreased ~20% from 16.w
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w), // Decreased from 8.w
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6.r)),
              child: Icon(icon, color: iconColor, size: 16.w), // Decreased from 20.w
            ),
            SizedBox(height: 6.h), // Decreased from 8.h
            Text(
              value, 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp), // Decreased from 20.sp
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h), // Decreased from 4.h
            Text(
              label, 
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10.sp), // Decreased from 12.sp
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        backgroundColor: const Color(0xFFF3F5F7),
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
                      colors: [Color(0xFF0F2547), Color(0xFF00569B)], 
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