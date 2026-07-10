import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_cubit.dart';
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
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/resumable_visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_dashboard_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/continue_work_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/order_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/connectivity_banner.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/continue_visit_card.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/continue_working_card.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/pending_sync_badge.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/sync_overlay.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/screens/customers_screen.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/main_app_bar.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/monthly_target_widget.dart'; // Ensure correct path name
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/my_work_grid_section.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/quick_action_widget.dart';

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
    // Offline-first rule: never auto-navigate on startup. A resumable route (or
    // draft) is surfaced through the Continue-Working card on the Home tab and
    // resumed only on an explicit tap — no automatic redirect to Visits.
    sl<ResumableVisitCubit>().refresh();
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
    // Returning to Home re-checks for an in-progress check-in to resume.
    if (_tabController.value == 0) sl<ResumableVisitCubit>().refresh();
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

  Widget _buildWelcomeSection(BuildContext context) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greetingKey.tr,
                  style: TextStyle(
                    color: Colors.white,
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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const PendingSyncBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => HomeCubit(const HomeRepositoryImpl())..load()),
        BlocProvider(create: (_) => sl<AddCustomerBloc>()),
      ],
      child: SizedBox.expand(
        child: Column(
          children: [
            // Pushes down dynamic screen list view past appbar safety boundary
            SafeArea(
              bottom: false,
              child: SizedBox(height: 70.h),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(0, 8.h, 0, 16.h),
                children: [
                  // 1. Welcome Header Section
                  _buildWelcomeSection(context),
                  SizedBox(height: 16.h),

                  // 2. Monthly Target Card aligned safely with 16.w edge-to-edge layout padding
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const MonthlyTargetCard(
                      targetAmount: 1000000,
                      achievedAmount: 750000,
                      monthName: 'August',
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Offline-first "Continue last action" section: resume drafts
                  // and monitor SAP sync inline — no floating overlay, no auto
                  // navigation. Each widget self-hides when it has nothing to
                  // show.
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const ConnectivityBanner(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const ContinueVisitCard(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const ContinueWorkingCard(),
                  ),
                  SizedBox(height: 8.h),
                  QuickActionsSection(),
                  MyWorkGridSection(),
                ],
              ),
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
          child: wrapWithTopSpacing(
              const PipelineScreen(initialStage: PipelineStage.leads)),
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

    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectivityCubit>(create: (_) => sl<ConnectivityCubit>()),
        BlocProvider<PendingSyncCubit>(create: (_) => sl<PendingSyncCubit>()),
        BlocProvider<ContinueWorkCubit>(create: (_) => sl<ContinueWorkCubit>()),
        BlocProvider<ResumableVisitCubit>.value(
            value: sl<ResumableVisitCubit>()),
      ],
      child: ReconnectSyncListener(
        child: PopScope(
          canPop: _index == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _tabController.goTo(0);
          },
          child: Scaffold(
            backgroundColor: Vibe.canvas,
            body: Stack(
              children: [
                // Upgraded Premium Blurred Image Header Background
                if (_index == 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.26,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32.r),
                        bottomRight: Radius.circular(32.r),
                      ),
                      child: Stack(
                        children: [
                          // 1. Background Image Asset
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/isi_main_app_bar_bg.png', // <-- Insert your dashboard image asset route path here
                              fit: BoxFit.cover,
                            ),
                          ),
                          // 1b. Black gradient scrim: opaque at the bottom,
                          // fading to transparent toward the top — keeps the
                          // header text readable over any image.
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.75),
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
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
        ),
      ),
    );
  }
}
