import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/seed_isi_tower_test_route.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/seed_mock_routes_for_dates.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/stop_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/route_sync_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/stop_dashboard_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/today_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_stop_information.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/calendar/calendar_widget_section.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stop_card.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stop_card_skeleton.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stop_dashboard/stop_filter_bar.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stop_dashboard/stop_search_field.dart';

/// The primary My Visits entry point: today's stops, sorted nearest-first by
/// live location. Replaces the route-centric dashboard.
///
/// Reps see *stops* directly (not routes); the list re-sorts as they move.
/// Offline-first — data is the local Drift stream; distance/sort/search are all
/// local. Kicks route sync + (debug) fixture seeding on open; the live stream
/// picks up whatever lands.
class StopDashboardScreen extends StatefulWidget {
  const StopDashboardScreen({super.key});

  @override
  State<StopDashboardScreen> createState() => _StopDashboardScreenState();
}

class _StopDashboardScreenState extends State<StopDashboardScreen> {
  /// Process-scoped latch — see the note in the old dashboard; seeding is
  /// idempotent, this only avoids redundant disk work on re-entry.
  static bool _debugFixturesSeeded = false;

  @override
  void initState() {
    super.initState();
    context.read<StopDashboardCubit>().start();
    context.read<RouteSyncCubit>().syncIfNeeded();
    context.read<RouteSyncCubit>().pushPending();
    if (kDebugMode) _autoSeedDebugFixtures();
  }

  /// TODO(release-gate): debug-only fixture seeding (docs/SECURITY.md §11).
  /// Writes test routes/customers straight to the local DB; the cubit's live
  /// stream re-emits automatically, so no manual reload is needed here.
  Future<void> _autoSeedDebugFixtures() async {
    if (_debugFixturesSeeded) return;
    _debugFixturesSeeded = true;
    try {
      await seedIsiTowerTestRoute(
          sl<RouteLocalDataSource>(), sl<CustomerLocalDataSource>());
      await seedMockRoutesForDates(
          sl<RouteLocalDataSource>(), sl<CustomerLocalDataSource>());
    } on StateError catch (e) {
      // Expected on a cold launch before customer sync lands — retry next open.
      _debugFixturesSeeded = false;
      debugPrint('Auto-seed skipped: ${e.message}');
    } catch (e) {
      _debugFixturesSeeded = false;
      debugPrint('Auto-seed failed: ${e is CacheException ? e.message : e}');
    }
  }

  Future<void> _refresh(BuildContext context) async {
    final sync = context.read<RouteSyncCubit>();
    await sync.refresh();
    await sync.pushPending();
  }

  void _openStop(
      BuildContext context, TodayStop todayStop, List<TodayStop> visibleStops) {
    final index =
        visibleStops.indexWhere((s) => s.stop.id == todayStop.stop.id);
    openStopInformation(
      context,
      stop: todayStop.stop,
      index: index != -1 ? index : 0,
      totalStops: visibleStops.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: BlocListener<RouteSyncCubit, RouteSyncState>(
          listenWhen: (p, c) => c is RouteSyncFailed || c is RouteSyncSucceeded,
          listener: (context, state) {
            // A pull that lands after the cubit took its opening snapshot is
            // otherwise invisible to it — sync writes through the local data
            // source, not the repository whose stream this screen watches. See
            // `StopDashboardCubit.reload`.
            if (state is RouteSyncSucceeded) {
              context.read<StopDashboardCubit>().reload();
              return;
            }
            if (state is RouteSyncFailed) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.message,
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  action: SnackBarAction(
                    label: 'common.retry'.tr,
                    onPressed: () =>
                        context.read<RouteSyncCubit>().syncIfNeeded(),
                  ),
                ));
            }
          },
          child: BlocBuilder<StopDashboardCubit, StopDashboardState>(
            builder: (context, state) => switch (state) {
              StopDashboardError(:final message) => Center(
                  child: Text(message,
                      style: TextStyle(color: colors.textSecondary))),
              StopDashboardLoaded() => _LoadedView(
                  state: state,
                  onRefresh: () => _refresh(context),
                  onTapStop: (s) => _openStop(context, s, state.visibleStops),
                  onFilter: (f) =>
                      context.read<StopDashboardCubit>().setFilter(f),
                  onQuery: (q) =>
                      context.read<StopDashboardCubit>().setQuery(q),
                ),
              _ => const StopDashboardSkeleton(),
            },
          ),
        ),
      ),
    );
  }
}

class _LoadedView extends StatefulWidget {
  const _LoadedView({
    required this.state,
    required this.onRefresh,
    required this.onTapStop,
    required this.onFilter,
    required this.onQuery,
  });

  final StopDashboardLoaded state;
  final Future<void> Function() onRefresh;
  final ValueChanged<TodayStop> onTapStop;
  final ValueChanged<StopFilter> onFilter;
  final ValueChanged<String> onQuery;

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  DateTime _focusedMonth = DateTime.now();

  /// Per-day stop count for the calendar dots — across every synced day, from
  /// the cubit's `allRoutes` (Today…+4 land here). Selecting a day filters the
  /// list via the cubit.
  int _getStopCountForDate(DateTime date) => widget.state.stopCountForDay(date);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final visible = widget.state.visibleStops;

    return RefreshIndicator(
      color: scheme.primary,
      backgroundColor: colors.surfaceSoft,
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StopCalendarSection(
                    focusedMonth: _focusedMonth,
                    selectedDate: widget.state.selectedDate,
                    onMonthChanged: (newMonth) =>
                        setState(() => _focusedMonth = newMonth),
                    onDateSelected: (newDate) => context
                        .read<StopDashboardCubit>()
                        .setSelectedDate(newDate),
                    stopCountForDate: _getStopCountForDate,
                  ),
                  SizedBox(height: 14.h),
                  StopSearchField(onChanged: widget.onQuery),
                  SizedBox(height: 10.h),
                  StopFilterBar(
                    selected: widget.state.filter,
                    onSelected: widget.onFilter,
                  ),
                  SizedBox(height: 6.h),
                  if (widget.state.locationUnavailable)
                    _Hint(
                      icon: Icons.location_off_rounded,
                      text: 'my_visits.stop_dashboard.location_denied'.tr,
                      color: colors.warning,
                    )
                  else if (widget.state.locating)
                    _Hint(
                      icon: Icons.my_location_rounded,
                      text: 'my_visits.stop_dashboard.locating'.tr,
                      color: colors.textSecondary,
                    ),
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ),
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(hasAnyStops: widget.state.stops.isNotEmpty),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final todayStop = visible[index];
                  return _FadeInItem(
                    key: ValueKey(todayStop.stop.id),
                    child: StopCard(
                      todayStop: todayStop,
                      onTap: () => widget.onTapStop(todayStop),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Gentle fade+rise as a card first appears — cheap enough for 500+ rows since
/// it runs once per item build, not per frame.
class _FadeInItem extends StatefulWidget {
  const _FadeInItem({super.key, required this.child});
  final Widget child;

  @override
  State<_FadeInItem> createState() => _FadeInItemState();
}

class _FadeInItemState extends State<_FadeInItem> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: Offset(0, _opacity == 1 ? 0 : 0.04),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAnyStops});
  final bool hasAnyStops;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAnyStops
                  ? Icons.filter_alt_off_rounded
                  : Icons.event_available_rounded,
              size: 40.w,
              color: colors.textHint,
            ),
            SizedBox(height: 12.h),
            Text(
              hasAnyStops
                  ? 'my_visits.stop_dashboard.no_matches'.tr
                  : 'my_visits.stop_dashboard.no_stops_today'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              hasAnyStops
                  ? 'my_visits.stop_dashboard.no_matches_hint'.tr
                  : 'my_visits.stop_dashboard.pull_to_sync'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }
}
