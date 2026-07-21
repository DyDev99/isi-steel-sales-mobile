import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/auth/auth_guard.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_cubit.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/device/device_insets.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_anchor_registry.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/widgets/app_coach_host.dart';
import 'package:isi_steel_sales_mobile/features/home/data/home_repository.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/add_customer_bloc.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/pipeline_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/resumable_visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_dashboard_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/continue_work_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/order_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/connectivity_banner.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/continue_visit_card.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/continue_working_card.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/pending_sync_badge.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/sync/sync_overlay.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/screens/customers_screen.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/guest/guest_home_screen.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/screen/notifications_sheet.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/main_app_bar.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/monthly_target_widget.dart';
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
  final SessionManager _session = sl<SessionManager>();

  /// Owned per shell instance (not static): each MainShell publishes its coach
  /// anchors into its *own* registry, so two shells coexisting during the login
  /// transition can never collide the way the old static GlobalKeys did.
  final CoachAnchorRegistry _coachAnchors = CoachAnchorRegistry();

  int _index = 0;

  /// Tabs the user has actually opened.
  ///
  /// `IndexedStack` lays out *every* child, so building all five tabs up front
  /// mounted four offstage screens at boot: each opened its database streams,
  /// created its Blocs, and — via the skeleton widgets — started repeating
  /// `AnimationController`s that never stopped, because an offstage
  /// `IndexedStack` child still ticks. That cost the cold-start budget
  /// (AI_ENGINEERING_PLAYBOOK.md §9) and burned CPU for the whole session.
  ///
  /// Building lazily and *keeping* what has been built preserves the reason
  /// `IndexedStack` is here in the first place: once a tab is open, its state,
  /// scroll position and Blocs survive every subsequent switch.
  final Set<int> _builtTabs = <int>{0};

  @override
  void initState() {
    super.initState();
    _index = _tabController.value;
    _builtTabs.add(_index);
    _tabController.addListener(_onTabChanged);
    sl<ResumableVisitCubit>().refresh();
    // Customer directory sync must run before route sync can attach stops to
    // customers (route_stops.customer_id is a real FK into the customer
    // directory, ADR-001) — kick it off here, as early as possible, rather
    // than leaving it to only run once the user opens the Customers tab.
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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<ProfileCubit>(),
        child: LocalizedBuilder(builder: (_) => const ProfileScreen()),
      ),
    ));
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
            create: (_) => HomeCubit(const HomeRepositoryImpl())..load()),
        BlocProvider(create: (_) => sl<AddCustomerBloc>()),
        // QuickActionsSection reads PipelineBloc to seed "add customer from a
        // Won lead" and to dispatch LeadCreated. Without this provider in the
        // Home-tab scope, tapping a quick action throws
        // ProviderNotFoundException<PipelineBloc> — the crash reported after the
        // dashboard was reworked. Its own scope, loaded up front so the Won
        // column is ready by the time the sheet opens.
        BlocProvider(
          create: (_) => sl<PipelineBloc>()..add(const PipelineLoadRequested()),
        ),
      ],
      child: SizedBox.expand(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: SizedBox(height: 70.h),
            ),
            // FIX: Added the Expanded wrapper back to the ListView.
            Expanded(
              child: ListView(
                key: const ValueKey('authenticated_home_scroll_root'),
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(0, 8.h, 0,
                    context.deviceInsets.scrollBottomInset(extra: 16.h)),
                children: [
                  _buildWelcomeSection(context),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: CoachKeys.wrap(
                      CoachKeys.monthlyTarget,
                      child: const MonthlyTargetCard(
                        targetAmount: 1000000,
                        achievedAmount: 750000,
                        monthName: 'August',
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const ConnectivityBanner(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const ContinueVisitCard(),
                  ),
                  // FIX: Correctly spaced without Expanded here!
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const ContinueWorkingCard(),
                  ),
                  SizedBox(height: 8.h),
                  CoachKeys.wrap(
                    CoachKeys.quickActions,
                    child: const QuickActionsSection(),
                  ),
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

        // FIX: AnimatedSwitcher prevents immediate layout snaps during login
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
                  topInset: 70.h,
                  onLogin: () => _openProfile(context),
                ),
        );
      },
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
            // No `..load()` here: RouteDashboardCubit's constructor already
            // calls _subscribe(). Chaining load() cancelled that first
            // subscription mid-fetch, re-emitted RouteDashboardLoading (an
            // extra skeleton flash) and ran a second redundant fetchAllRoutes()
            // on every tab open.
            BlocProvider(create: (_) => sl<RouteDashboardCubit>()),
            BlocProvider(create: (_) => sl<RouteSyncCubit>()),
          ],
          child: wrapWithTopSpacing(
              const MyVisitsDashboardScreen()), // ✅ Replaced with a comma
        );
      case 3:
        return wrapWithTopSpacing(
            const PipelineScreen(initialStage: PipelineStage.leads));
      case 4:
        return wrapWithTopSpacing(const OrderScreen());
      default:
        return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _tabs.length) _index = 0;

    // Scope the coach anchor registry above the whole shell so every anchor
    // (dashboard cards, app-bar items) and the AppCoachHost that reads them
    // share this instance — see CoachAnchorRegistry for why this replaces the
    // old static GlobalKeys.
    return CoachAnchorScope(
      registry: _coachAnchors,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>(
              create: (_) => sl<ConnectivityCubit>()),
          BlocProvider<PendingSyncCubit>(create: (_) => sl<PendingSyncCubit>()),
          BlocProvider<ContinueWorkCubit>(
              create: (_) => sl<ContinueWorkCubit>()),
          BlocProvider<ResumableVisitCubit>.value(
              value: sl<ResumableVisitCubit>()),
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
              body: Stack(
                children: [
                  // FIX: Replaced layout-snapping absolute condition with a smooth fade opacity transition
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32.r),
                            bottomRight: Radius.circular(32.r),
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
                        // No per-tab key here: IndexedStack must keep a stable
                        // widget identity across tab switches so it actually
                        // preserves each tab's state instead of tearing down
                        // and recreating every tab (incl. factory-registered
                        // Blocs/Cubits) on every switch.
                        child: IndexedStack(
                          index: _index,
                          children: List.generate(
                            _tabs.length,
                            // Unvisited tabs are a zero-cost placeholder until
                            // first opened; once built they stay built, so
                            // state is preserved exactly as before.
                            (i) => _builtTabs.contains(i)
                                ? _buildTab(i)
                                : const SizedBox.shrink(),
                          ),
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
                      onNotificationTap: _session.isAuthenticated
                          ? null
                          : () => _openGuestNotifications(context),
                    ),
                  ),
                  const AppCoachHost(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
