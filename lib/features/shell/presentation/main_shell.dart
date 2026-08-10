// cspell:ignore Sokha
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/auth/auth_guard.dart';
import 'package:isi_steel_sales_mobile/core/device/device_insets.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_cubit.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_anchor_registry.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/widgets/app_coach_host.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/screens/customers_screen.dart';
import 'package:isi_steel_sales_mobile/features/home/data/home_repository.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/add_customer_bloc.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/pipeline_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/resumable_visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/stop_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_dashboard/stop_dashboard_screen.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/screen/notifications_sheet.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/continue_work_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/order_screen.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/screens/kpi_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/guest/guest_home_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/main_app_bar.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/monthly_target_widget.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/my_work_grid_section.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/connectivity_banner.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/continue_visit_card.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/continue_working_card.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/pending_sync_badge.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/sync_overlay.dart';

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
  final SessionManager _session = sl<SessionManager>();

  final CoachAnchorRegistry _coachAnchors = CoachAnchorRegistry();

  int _index = 0;
  final Set<int> _builtTabs = <int>{0};

  // Traditional Gold Accent Color Palette
  static const Color _goldLight = Color(0xFFF3E5AB);
  static const Color _goldPrimary = Color(0xFFD4AF37);
  static const Color _goldDark = Color(0xFF996515);

  @override
  void initState() {
    super.initState();
    _index = _tabController.value;
    _builtTabs.add(_index);
    _tabController.addListener(_onTabChanged);
    sl<ResumableVisitCubit>().refresh();
    sl<CustomerSyncCubit>().syncIfNeeded();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _index = _tabController.value;
      _builtTabs.add(_index);
    });
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

  Future<void> _openProfile(BuildContext context) async {
    final allowed = await AuthGuard.requireAuthentication(context);
    if (!allowed || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<ProfileCubit>(),
          child: LocalizedBuilder(builder: (_) => const ProfileScreen()),
        ),
      ),
    );
  }

  void _openGuestNotifications(BuildContext context) {
    showNotificationsSheet(
      context: context,
      fetchNotifications: sl<FetchNotifications>(),
      isGuest: !_session.isAuthenticated,
      onLogin: () => _openProfile(context),
    );
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
      padding: EdgeInsets.fromLTRB(
          context.pagePadding, context.rh(4), context.pagePadding, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                // Traditional Gold Pillar Accent Line
                Container(
                  width: context.rw(3.5),
                  height: context.rh(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.r),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_goldLight, _goldPrimary, _goldDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _goldPrimary.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        greetingKey.tr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: context.rsp(13),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Sokha Novel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.rsp(19),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PendingSyncBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedHomeTab({Key? key}) {
    return MultiBlocProvider(
      key: key,
      providers: [
        BlocProvider(
          create: (_) => HomeCubit(const HomeRepositoryImpl())..load(),
        ),
        BlocProvider(create: (_) => sl<AddCustomerBloc>()),
        BlocProvider(
          create: (_) => sl<PipelineBloc>()..add(const PipelineLoadRequested()),
        ),
      ],
      child: SizedBox.expand(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: SizedBox(height: context.rh(70)),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('authenticated_home_scroll_root'),
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  0,
                  8.h,
                  0,
                  context.deviceInsets.scrollBottomInset(extra: 16.h),
                ),
                children: [
                  _buildWelcomeSection(context),
                  SizedBox(height: context.rh(16)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                    child: CoachKeys.wrap(
                      CoachKeys.monthlyTarget,
                      child: MonthlyTargetCard(
                        targetAmount: 1000000,
                        achievedAmount: 750000,
                        monthName:
                            'calendar.months.m${DateTime.now().month}'.tr,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LocalizedBuilder(
                                builder: (_) => const KpiScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: context.rh(16)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                    child: const ConnectivityBanner(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                    child: const ContinueVisitCard(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                    child: const ContinueWorkingCard(),
                  ),
                  SizedBox(height: 8.h),
                  const MyWorkGridSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return StreamBuilder<Object?>(
      stream: _session.changes,
      builder: (context, snapshot) {
        final authenticated = _session.isAuthenticated;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: authenticated
              ? _buildAuthenticatedHomeTab(
                  key: const ValueKey('authenticated_home_view'))
              : GuestHomeScreen(
                  key: const ValueKey('guest_home_view'),
                  topInset: context.rh(70),
                  onLogin: () => _openProfile(context),
                ),
        );
      },
    );
  }

  Widget _buildTab(int i) {
    Widget wrapWithTopSpacing(Widget screen) {
      return Padding(
        padding: EdgeInsets.only(top: context.rh(80)),
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
            BlocProvider(create: (_) => sl<StopDashboardCubit>()),
            BlocProvider(create: (_) => sl<RouteSyncCubit>()),
          ],
          child: wrapWithTopSpacing(const StopDashboardScreen()),
        );
      case 3:
        return wrapWithTopSpacing(
          const PipelineScreen(initialStage: PipelineStage.leads),
        );
      case 4:
        return wrapWithTopSpacing(const OrderScreen());
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildNavigationRail(BuildContext context, WindowSize size) {
    return NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: _tabController.goTo,
      extended: false,
      labelType: size.isExpanded
          ? NavigationRailLabelType.all
          : NavigationRailLabelType.selected,
      backgroundColor: context.appColors.canvas,
      destinations: [
        for (final tab in _tabs)
          NavigationRailDestination(
            icon: Icon(tab.icon),
            label: Text(tab.label),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _tabs.length) _index = 0;

    return CoachAnchorScope(
      registry: _coachAnchors,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>(
            create: (_) => sl<ConnectivityCubit>(),
          ),
          BlocProvider<PendingSyncCubit>(
            create: (_) => sl<PendingSyncCubit>(),
          ),
          BlocProvider<ContinueWorkCubit>(
            create: (_) => sl<ContinueWorkCubit>(),
          ),
          BlocProvider<ResumableVisitCubit>.value(
            value: sl<ResumableVisitCubit>(),
          ),
          BlocProvider<PipelineBloc>(
            create: (_) =>
                sl<PipelineBloc>()..add(const PipelineLoadRequested()),
          ),
        ],
        child: ReconnectSyncListener(
          child: PopScope(
            canPop: _index == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _tabController.goTo(0);
            },
            child: Scaffold(
              backgroundColor: context.appColors.canvas,
              // Side navigation is deliberately *desktop-only*, not
              // `hasSideNavigation` (>= 600) and not `isExpanded` (>= 1024) —
              // an iPad Pro 12.9" is exactly 1024pt in portrait, so `expanded`
              // sits right on a tablet. On a tablet the rail added a second
              // navigation model on top of the "My Work" grid that phones
              // already use, for no gain, so tablets now get exactly the phone
              // experience. See [Breakpoints.sideNavigationMin].
              body: context.showsSideNavigation
                  ? Row(
                      children: [
                        _buildNavigationRail(context, context.windowSize),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(child: _buildBody(context)),
                      ],
                    )
                  : _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        // Top Hero Container with Traditional Gold Border Trim & 3D Depth
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.26,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            opacity: _index == 0 ? 1.0 : 0.0,
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: _index != 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32.r),
                    bottomRight: Radius.circular(32.r),
                  ),
                  // Outer Traditional Gold Trim & Elevation Shadow
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_goldLight, _goldPrimary, _goldDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      offset: const Offset(0, 6),
                      blurRadius: 12,
                    ),
                  ],
                ),
                padding: EdgeInsets.only(bottom: 2.5.h), // Gold Bottom Frame
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.r),
                    bottomRight: Radius.circular(30.r),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/isi_main_app_bar_bg.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.82),
                                Colors.black.withValues(alpha: 0.30),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
          ),
          child: Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutQuad,
              switchOutCurve: Curves.easeInQuad,
              child: IndexedStack(
                index: _index,
                children: List.generate(
                  _tabs.length,
                  (i) => _builtTabs.contains(i)
                      ? _buildTab(i)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        // Inside MainShell -> _buildBody -> Stack children:
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: MainAppBar(
            title: _titles[_index],
            currentTabIndex: _index,
            onBackToHomeTap: () => _tabController.goTo(0),
            onAvatarTap: () => _openProfile(context),
            onNotificationTap: _session.isAuthenticated
                ? null
                : () => _openGuestNotifications(context),
          ),
        ),
        // Wrap AppCoachHost in Positioned.fill directly inside the Stack
        const Positioned.fill(
          child: AppCoachHost(),
        ),
      ],
    );
  }
}
