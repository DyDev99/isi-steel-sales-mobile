import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/seed_isi_tower_test_route.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/visit_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_dashboard_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_sync_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_route_dispatch.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/my_visits_history_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/calendar_widget_section.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_skeletons.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/region_card.dart';

class MyVisitsDashboardScreen extends StatefulWidget {
  const MyVisitsDashboardScreen({super.key});

  @override
  State<MyVisitsDashboardScreen> createState() =>
      _MyVisitsDashboardScreenState();
}

class _MyVisitsDashboardScreenState extends State<MyVisitsDashboardScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String? _selectedStopId;
  final Set<String> _collapsedRegions = {};
  int _pendingSyncBump = 0;

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
  }

  Future<void> _openRoute(BuildContext context, String routeId) async {
    final syncCubit = context.read<RouteSyncCubit>();
    final dashboardCubit = context.read<RouteDashboardCubit>();
    await openRouteDispatch(context, routeId, syncCubit: syncCubit);
    if (!mounted) return;
    dashboardCubit.load();
  }

  Future<void> _seedTestRoute(BuildContext context) async {
    await seedIsiTowerTestRoute(sl<RouteLocalDataSource>());
    if (!context.mounted) return;
    context.read<RouteDashboardCubit>().load();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seeded test route: ISI Tower')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.canvas,
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              heroTag: 'seed-test-route',
              backgroundColor: scheme.primary,
              tooltip: 'Seed ISI Tower test route',
              onPressed: () => _seedTestRoute(context),
              child: Icon(Icons.bug_report_rounded, color: scheme.onPrimary),
            )
          : null,
      body: SafeArea(
        child: BlocListener<RouteSyncCubit, RouteSyncState>(
          listenWhen: (prev, curr) => curr is RouteSyncSucceeded,
          listener: (context, _) {
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
                      // 1. Grid Calendar Section
                      GridCalendarCard(
                        focusedMonth: _focusedMonth,
                        selectedDate: _selectedDate,
                        onMonthChanged: (newMonth) {
                          setState(() => _focusedMonth = newMonth);
                        },
                        onDateSelected: (date) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedDate = date;
                            _selectedStopId = null;
                          });
                        },
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
    final filteredRoutes = routes.where((route) {
      return (route.id.hashCode + _selectedDate.day) % 2 == 0;
    }).toList();

    final List<_RouteStopWithPlanId> stopsWithPlan = [];
    for (var route in filteredRoutes) {
      for (var stop in route.stops) {
        stopsWithPlan.add(_RouteStopWithPlanId(stop: stop, routeId: route.id));
      }
    }

    if (stopsWithPlan.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 28.w, color: context.appColors.textSecondary),
              SizedBox(height: 10.h),
              Text(
                'No customer visits scheduled for this date',
                style: TextStyle(
                    color: context.appColors.textSecondary, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, List<_RouteStopWithPlanId>> grouped = {};
    for (final item in stopsWithPlan) {
      final region = item.stop.customer.territory.isNotEmpty
          ? item.stop.customer.territory
          : 'Unassigned';
      grouped.putIfAbsent(region, () => []).add(item);
    }
    final regionNames = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final regionName in regionNames) ...[
          Builder(builder: (context) {
            final items = grouped[regionName]!;
            final completed = items
                .where((i) => i.stop.status == VisitStatus.checkedOut)
                .length;
            final expanded = !_collapsedRegions.contains(regionName);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RegionGroupHeader(
                  regionName: regionName,
                  totalStops: items.length,
                  completedStops: completed,
                  expanded: expanded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (expanded) {
                        _collapsedRegions.add(regionName);
                      } else {
                        _collapsedRegions.remove(regionName);
                      }
                    });
                  },
                ),
                if (expanded)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => SizedBox(height: 0.h),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return RegionCard(
                        stop: item.stop,
                        selected: _selectedStopId == item.stop.id,
                        onTap: () {
                          setState(() => _selectedStopId = item.stop.id);
                          _openRoute(context, item.routeId);
                        },
                        onCartTap: () {
                          HapticFeedback.mediumImpact();
                        },
                      );
                    },
                  ),
                SizedBox(height: 14.h),
              ],
            );
          }),
        ],
      ],
    );
  }
}

/// Local structural model payload helper to bundle relationships safely
class _RouteStopWithPlanId {
  final RouteStop stop;
  final String routeId;
  const _RouteStopWithPlanId({required this.stop, required this.routeId});
}

/// Debug-only visibility into the visit-capture push-sync queue — not
/// production UX, just enough to demonstrate/verify the pending count
/// draining after `RouteSyncCubit.pushPending()` runs. Rebuilt (via its
/// `ValueKey`) whenever a sync completes.
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
                ? 'Pending sync: …'
                : 'Pending sync: $count record(s)',
            style: TextStyle(color: colors.textSecondary, fontSize: 11.sp),
          ),
        );
      },
    );
  }
}

/// Dynamic Region Collapsible Header Component
class RegionGroupHeader extends StatelessWidget {
  const RegionGroupHeader({
    super.key,
    required this.regionName,
    required this.totalStops,
    required this.completedStops,
    required this.expanded,
    required this.onTap,
  });

  final String regionName;
  final int totalStops;
  final int completedStops;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        child: Row(
          children: [
            Text(
              regionName.toUpperCase(),
              style: TextStyle(
                color: colors.textPrimary.withValues(alpha: 0.85),
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '$completedStops/$totalStops',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: expanded ? 0.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                color: colors.textPrimary.withValues(alpha: 0.6),
                size: 20.w,
              ),
            ),
          ],
        ),
      ),
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
              'my_visits.history.view_historyTemplate'.tr.toUpperCase() !=
                      'MY_VISITS.HISTORY.VIEW_HISTORYTEMPLATE'
                  ? 'my_visits.history.view_historyTemplate'.tr.toUpperCase()
                  : 'ACTIVITY HISTORY',
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
