import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/seed_isi_tower_test_route.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/seed_mock_routes_for_dates.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/visit_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/route_dashboard_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/route_sync_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_route_information.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/my_visits_history_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/calendar/calendar_widget_section.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_skeletons.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_summary_card.dart';

class MyVisitsDashboardScreen extends StatefulWidget {
  const MyVisitsDashboardScreen({super.key});

  @override
  State<MyVisitsDashboardScreen> createState() =>
      _MyVisitsDashboardScreenState();
}

List<RoutePlan> routesScheduledOn(DateTime date, List<RoutePlan> routes) {
  return routes
      .where((route) => DateUtils.isSameDay(route.visitDate, date))
      .toList();
}

class _MyVisitsDashboardScreenState extends State<MyVisitsDashboardScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  int _pendingSyncBump = 0;

  /// Process-scoped latch for [_autoSeedDebugFixtures]. Static so navigating
  /// away and back doesn't re-run the seeders on every visit — it is not a
  /// correctness guard (seeding is idempotent), just an efficiency one.
  static bool _debugFixturesSeeded = false;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    context.read<RouteSyncCubit>().syncIfNeeded();
    context.read<RouteSyncCubit>().pushPending();
    if (kDebugMode) _autoSeedDebugFixtures();
  }

  /// Tapping a route card opens the new premium Route Information screen (the
  /// visit-prep step). Its "Start Visit" CTA hands off to the guided Check-In
  /// flow; the shared `RouteSyncCubit` is forwarded so the pushed chain reuses
  /// this tab's sync orchestrator. Reload on return so any status change made
  /// downstream (check-ins, completions) is reflected on the dashboard.
  Future<void> _openRouteInfo(BuildContext context, RoutePlan route) async {
    final syncCubit = context.read<RouteSyncCubit>();
    final dashboardCubit = context.read<RouteDashboardCubit>();
    await openRouteInformation(context, route.id, syncCubit: syncCubit);
    if (!mounted) return;
    dashboardCubit.load();
  }

  /// TODO(release-gate): debug-only fixture seeding — must never run in a
  /// release build (`docs/SECURITY.md` §11: "mock data and mock APIs removed").
  /// Enforced by the [kDebugMode] guard at the single call site in [initState].
  ///
  /// Replaces the debug FloatingActionButton that used to trigger this by hand:
  /// a fresh device now shows route data on first open with no manual tap.
  ///
  /// Safe to re-run. Both seeders write fixed ids (`test-route-3-stops`,
  /// `test-route-<date>-<n>`) through the same `upsertCustomers`/`upsertRoutes`
  /// calls the sync engine uses, so a repeat run updates rows in place instead
  /// of duplicating them. [_debugFixturesSeeded] only avoids redundant disk
  /// work; it is not what makes this safe.
  Future<void> _autoSeedDebugFixtures() async {
    if (_debugFixturesSeeded) return;
    _debugFixturesSeeded = true;

    // Captured before the first await — the State may be disposed by the time
    // seeding finishes, and reading an inherited widget after that throws.
    final dashboardCubit = context.read<RouteDashboardCubit>();

    try {
      await seedIsiTowerTestRoute(
        sl<RouteLocalDataSource>(),
        sl<CustomerLocalDataSource>(),
      );
      await seedMockRoutesForDates(
        sl<RouteLocalDataSource>(),
        sl<CustomerLocalDataSource>(),
      );
    } on StateError catch (e) {
      // Expected on a cold first launch, not a bug: both seeders borrow real
      // customer ids so `route_stops.customer_id` resolves (ADR-001), and the
      // customer sync may not have landed yet. Release the latch so the next
      // visit to this screen retries once customers exist.
      _debugFixturesSeeded = false;
      debugPrint('Auto-seed skipped: ${e.message}');
      return;
    } catch (e) {
      _debugFixturesSeeded = false;
      final detail = e is CacheException ? e.message : e.toString();
      debugPrint('Auto-seed failed: $detail');
      return;
    }

    // Seeding writes straight to the local DB behind the cubit's back, so the
    // dashboard has to be told to re-read. Offline-first: a failed seed above
    // returns early and leaves the screen on whatever real data exists rather
    // than surfacing an error state (ADR-002 §4).
    if (!mounted) return;
    dashboardCubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: BlocListener<RouteSyncCubit, RouteSyncState>(
          listenWhen: (prev, curr) =>
              curr is RouteSyncSucceeded || curr is RouteSyncFailed,
          listener: (context, state) {
            if (state is RouteSyncFailed) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  // Bounded on purpose. `Failure.message` can carry a long
                  // server string, and an unbounded SnackBar grows to fit it —
                  // which is how the invisible-text bug became a full-screen
                  // rectangle rather than a small unreadable bar. Capping the
                  // height means even a pathological message stays a SnackBar.
                  content: Text(
                    state.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  action: SnackBarAction(
                    label: 'common.retry'.tr,
                    onPressed: () =>
                        context.read<RouteSyncCubit>().syncIfNeeded(),
                  ),
                ));
              return;
            }
            context.read<RouteDashboardCubit>().load();
            if (kDebugMode) setState(() => _pendingSyncBump++);
          },
          child: BlocBuilder<RouteDashboardCubit, RouteDashboardState>(
            builder: (context, state) => switch (state) {
              RouteDashboardLoaded() => RefreshIndicator(
                  color: scheme.primary,
                  backgroundColor: colors.surfaceSoft,
                  onRefresh: () async {
                    final syncCubit = context.read<RouteSyncCubit>();
                    await syncCubit.refresh();
                    await syncCubit.pushPending();
                    if (context.mounted) {
                      await context.read<RouteDashboardCubit>().load();
                    }
                  },
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                    children: [
                      // 1. Compact Expandable Calendar Section
                      RouteCalendarSection(
                        focusedMonth: _focusedMonth,
                        selectedDate: _selectedDate,
                        onMonthChanged: (newMonth) {
                          setState(() => _focusedMonth = newMonth);
                        },
                        onDateSelected: (date) {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedDate = date);
                        },
                        routeCountForDate: (date) =>
                            routesScheduledOn(date, state.routes).length,
                      ),
                      SizedBox(height: 12.h),

                      // 2. Activity History Section
                      _ActivityHistoryRibbon(
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                          settings: const RouteSettings(
                              name: MyVisitsHistoryScreen.routeName),
                          builder: (_) => const MyVisitsHistoryScreen(),
                        )),
                      ),
                      SizedBox(height: 20.h),

                      if (kDebugMode) ...[
                        _PendingSyncDebugBadge(key: ValueKey(_pendingSyncBump)),
                        SizedBox(height: 12.h),
                      ],

                      // 3. Conditional Day Header Label
                      Text(
                        _isToday
                            ? 'my_visits.flow.today'.tr.toUpperCase()
                            : DateFormat('EEEE, MMMM d')
                                .format(_selectedDate)
                                .toUpperCase(),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // 4. Filtered Route Content Pipeline loaded into StopCards
                      _buildFilteredRouteContent(context, state.routes),

                      // 5. Background-sync shimmer — fills the trailing gap
                      // below sparse content with a loading placeholder
                      // instead of blank space while a pull/delta sync runs.
                      BlocBuilder<RouteSyncCubit, RouteSyncState>(
                        builder: (context, syncState) =>
                            syncState is RouteSyncInProgress
                                ? const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: RouteCardSkeleton(),
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              RouteDashboardError(:final message) => Center(
                  child: Text(message,
                      style: TextStyle(color: colors.textSecondary))),
              _ => const RouteDashboardSkeleton(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredRouteContent(
      BuildContext context, List<RoutePlan> routes) {
    // DIAGNOSTIC ISSUE FIX 1: Database completely empty
    if (routes.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 36.w, color: context.appColors.textHint),
              SizedBox(height: 12.h),
              Text(
                'my_visits.dashboard.no_local_data'.tr,
                style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6.h),
              Text(
                kDebugMode
                    // Debug builds auto-seed on open; reaching this state means
                    // the seeders found no synced customers to borrow ids from.
                    ? 'Pull down to sync from remote. Debug fixtures seed '
                        'automatically once customers have synced.'
                    : 'my_visits.dashboard.pull_to_sync'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.appColors.textSecondary, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      );
    }

    final filteredRoutes = routesScheduledOn(_selectedDate, routes);

    // DIAGNOSTIC ISSUE FIX 2: Data exists in DB, but not on this selected date.
    if (filteredRoutes.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded,
                  size: 36.w, color: context.appColors.textHint),
              SizedBox(height: 12.h),
              Text(
                'my_visits.dashboard.no_visits_for_date'.tr,
                style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6.h),
              Text(
                'my_visits.dashboard.other_dates'
                    .trParams({'count': routes.length}),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.appColors.textSecondary, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      );
    }

    // Route-centric summary cards (one per RoutePlan) — the dashboard answers
    // "which route should I start?"; per-stop detail lives on Route Information.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final route in filteredRoutes)
          RouteSummaryCard(
            route: route,
            onTap: () => _openRouteInfo(context, route),
          ),
      ],
    );
  }
}

class _PendingSyncDebugBadge extends StatelessWidget {
  const _PendingSyncDebugBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: sl<VisitLocalDataSource>().countPendingVisitRecords(),
      builder: (context, snapshot) {
        final colors = context.appColors;
        final count = snapshot.data;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            count == null
                ? 'my_visits.dashboard.pending_sync_loading'.tr
                : 'my_visits.dashboard.pending_sync'.trParams({'count': count}),
            style: TextStyle(color: colors.textSecondary, fontSize: 11.sp),
          ),
        );
      },
    );
  }
}

class _ActivityHistoryRibbon extends StatelessWidget {
  const _ActivityHistoryRibbon({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'my_visits.dashboard.activity_history'.tr,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13.w, color: colors.textPrimary),
          ],
        ),
      ),
    );
  }
}
