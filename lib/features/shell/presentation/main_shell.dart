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

  // --- ALIGNED INDEX MAP ---
  // Index 0: Home
  // Index 1: Customers
  // Index 2: Routes
  // Index 3: Leads/Pipeline
  // Index 4: Orders
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

  late final List<Widget?> _built = List<Widget?>.filled(5, null);

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<ProfileCubit>(),
        child: LocalizedBuilder(builder: (_) => const ProfileScreen()),
      ),
    ));
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
                SizedBox(height: 84.h),
                
                // Pipeline summary card switches to Pipeline Tab (Index 3) on tap
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 0.h),    
                  child: GestureDetector(
                    onTap: () => _tabController.goTo(3), // Navigate to Pipeline
                    child: _buildPipelineSummaryCard(),
                  ),
                ),
                
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 16.h),
                    children: [
                      _buildActionGrid(),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 60.h,
            right: 30.w,
            child: FloatingActionButton(
              heroTag: 'add_user_fab', 
              backgroundColor: const Color(0xFF2563EB),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              onPressed: () {
                showAddCustomerSheet(context);
              },
              child: const Icon(
                Icons.person_add_alt_1_rounded, 
                color: Colors.white,
              ),
            ),
          ),

          // "Add My Visit" floating popup button.
          // Stacked above the existing "Add Customer" FAB (60.h + ~56.h
          // button height + 16.h gap) so the two never overlap.
          Positioned(
            bottom: 132.h,
            right: 30.w,
            child: AnimatedScale(
              // Subtle entrance/press-friendly scale animation, kept purely
              // visual so it never affects layout or state.
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              scale: 1.0,
              child: FloatingActionButton.extended(
                heroTag: 'add_my_visit_fab',
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7C3AED),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                onPressed: () {
                  showAddVisitSheet(context);
                },
                icon: Icon(Icons.location_on_rounded, size: 20.w),
                label: Text(
                  'Add My Visit',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
              ),
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
            color: Colors.black.withValues(alpha: 0.08),
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
                  label: "Leads",
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildPipelineItem(
                  icon: Icons.trending_up_rounded,
                  iconColor: Colors.blue,
                  iconBg: Colors.blue.withValues(alpha: 0.1),
                  value: '5',
                  label: "Opportunities",
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildPipelineItem(
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.green,
                  iconBg: Colors.green.withValues(alpha: 0.1),
                  value: '2',
                  label: "Won",
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              'View pipeline >',
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
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.1,
      children: [
        _buildGridCard(
          icon: Icons.people_alt_rounded, 
          iconColor: Colors.blue, 
          iconBg: Colors.blue.withValues(alpha: 0.1), 
          value: '150', 
          label: 'Customers',
          onTap: () => _tabController.goTo(1), // Index 1: Customers
        ),
        _buildGridCard(
          icon: Icons.location_on_rounded, 
          iconColor: Colors.purple, 
          iconBg: Colors.purple.withValues(alpha: 0.1), 
          value: '12', 
          label: 'Routes',
          onTap: () => _tabController.goTo(2), // Index 2: Routes
        ),
        _buildGridCard(
          icon: Icons.receipt_long_rounded, 
          iconColor: Colors.orange, 
          iconBg: Colors.orange.withValues(alpha: 0.1), 
          value: '45', 
          label: 'Orders',
          onTap: () => _tabController.goTo(4), // Index 4: Orders
        ),
        _buildRevenueCard(
          achieved: '\$10k',
          target: '\$12.5k',
          onTap: () {}, // Leaves revenue static/non-clickable as requested
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
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
              child: Icon(Icons.attach_money_rounded, color: Colors.green, size: 20.w),
            ),
            const Spacer(),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: achieved, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Vibe.text)),
                  TextSpan(text: ' achieved', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500)),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: target, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp, color: Colors.grey.shade600)),
                  TextSpan(text: ' target', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500)),
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
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8.r)),
              child: Icon(icon, color: iconColor, size: 20.w),
            ),
            const Spacer(),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp)),
            SizedBox(height: 4.h),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int i) {
    Widget wrapWithTopSpacing(Widget screen) {
      return Padding(
        padding: EdgeInsets.only(top: 94.h),
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
    // Evict cached layout structure if index shifts out of bounds safely
    if (_index >= _built.length) _index = 0;
    _built[_index] ??= _buildTab(_index); 

    return PopScope(
      canPop: _index == 0, // Using explicit index integer directly matching home setup
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _tabController.goTo(0);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F5F7),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.24,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
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
                  children: List.generate(
                    _tabs.length,
                    (i) => _built[i] ?? const SizedBox.shrink(),
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