import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              heroTag: 'seed-test-route',
              backgroundColor: Vibe.violet,
              tooltip: 'Seed ISI Tower test route',
              onPressed: () => _seedTestRoute(context),
              child: const Icon(Icons.bug_report_rounded, color: Colors.white),
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
                  color: Vibe.violet,
                  backgroundColor: Vibe.bgSoft,
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
                      _GridCalendarCard(
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
                          color: Vibe.text,
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
                  child:
                      Text(message, style: const TextStyle(color: Vibe.muted))),
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
                  size: 28.w, color: Vibe.muted),
              SizedBox(height: 10.h),
              Text(
                'No customer visits scheduled for this date',
                style: TextStyle(color: Vibe.muted, fontSize: 12.sp),
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
        final count = snapshot.data;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Vibe.bgSoft,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Vibe.stroke),
          ),
          child: Text(
            count == null
                ? 'Pending sync: …'
                : 'Pending sync: $count record(s)',
            style: TextStyle(color: Vibe.muted, fontSize: 11.sp),
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
                color: Vibe.text.withValues(alpha: 0.85),
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EDF0),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '$completedStops/$totalStops',
                style: TextStyle(
                  color: const Color(0xFF5A6773),
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
                color: Vibe.text.withValues(alpha: 0.6),
                size: 20.w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCalendarCard extends StatelessWidget {
  const _GridCalendarCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);
    final firstDayOffset =
        DateTime(focusedMonth.year, focusedMonth.month, 1).weekday % 7;
    final weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CALENDAR',
                style: TextStyle(
                  color: Vibe.text.withValues(alpha: 0.8),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded,
                        color: Vibe.text, size: 20.w),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      onMonthChanged(DateTime(
                          focusedMonth.year, focusedMonth.month - 1, 1));
                    },
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    DateFormat('MMMM yyyy').format(focusedMonth),
                    style: TextStyle(
                        color: Vibe.text,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded,
                        color: Vibe.text, size: 20.w),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      onMonthChanged(DateTime(
                          focusedMonth.year, focusedMonth.month + 1, 1));
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayLabels
                .map((label) => Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EDF0),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                              color: const Color(0xFF5A6773),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 6.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + firstDayOffset,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5.h,
              crossAxisSpacing: 3.5.w,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < firstDayOffset) return const SizedBox.shrink();

              final dayNumber = index - firstDayOffset + 1;
              final dayDate =
                  DateTime(focusedMonth.year, focusedMonth.month, dayNumber);

              final bool isSelected = dayDate.year == selectedDate.year &&
                  dayDate.month == selectedDate.month &&
                  dayDate.day == selectedDate.day;

              Color blockBg = const Color(0xFFE9EDF0);
              Color textColor = Vibe.text;
              bool hasDot = false;
              Color dotColor = Colors.transparent;

              if (isSelected) {
                blockBg = const Color(0xFF7A8B99);
                textColor = Colors.white;
              } else {
                if (dayNumber == 13 || dayNumber == 16) {
                  blockBg = const Color(0xFFA1DBCB);
                  hasDot = true;
                  dotColor = const Color(0xFF1B6B59);
                } else if (dayNumber == 22) {
                  blockBg = const Color(0xFFF9C38F);
                  hasDot = true;
                  dotColor = const Color(0xFF9E5610);
                } else if ([4, 10, 23].contains(dayNumber)) {
                  hasDot = true;
                  dotColor = const Color(0xFF3A7D6F);
                }
              }

              return GestureDetector(
                onTap: () => onDateSelected(dayDate),
                child: Container(
                  decoration: BoxDecoration(
                    color: blockBg,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: hasDot ? 6.h : null,
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11.5.sp,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (hasDot)
                        Positioned(
                          bottom: 5.h,
                          child: Container(
                            width: 3.5.w,
                            height: 3.5.w,
                            decoration: BoxDecoration(
                                color: dotColor, shape: BoxShape.circle),
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityHistoryRibbon extends StatelessWidget {
  const _ActivityHistoryRibbon({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
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
                  color: Vibe.text,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13.w, color: Vibe.text),
          ],
        ),
      ),
    );
  }
}
