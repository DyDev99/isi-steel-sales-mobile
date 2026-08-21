import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_note.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/add_visit_note.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/add_visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/routes_params.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_stop_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/stop_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/route_sync_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/stop_dashboard_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/today_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_stop_information.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/calendar/calendar_widget_section.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stop_card.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stop_card_skeleton.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/today_visits_progress_cart.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// The primary My Visits entry point: today's stops, sorted nearest-first by
/// live location. Replaces the route-centric dashboard.
///
/// Reps see *stops* directly (not routes); the list re-sorts as they move.
/// Offline-first — data is the local Drift stream; distance/sort/search are all
/// local. Kicks route sync on open; the live stream picks up whatever lands.
class StopDashboardScreen extends StatefulWidget {
  const StopDashboardScreen({super.key});

  @override
  State<StopDashboardScreen> createState() => _StopDashboardScreenState();
}

class _StopDashboardScreenState extends State<StopDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StopDashboardCubit>().start();
    // The only source of routes: pull from the backend, push what's pending.
    // Debug fixture seeding used to run here too, writing hardcoded routes
    // straight into the live database on every launch. It has been removed —
    // seeded rows are indistinguishable from synced ones once written, so they
    // sat on top of real API data and made an empty or wrong route feed look
    // populated. Mock data now has exactly one entry point:
    // `--dart-define=USE_MOCK_DATA=true`, which swaps the *remote* source and
    // leaves the database honest about where its rows came from.
    context.read<RouteSyncCubit>().syncIfNeeded();
    context.read<RouteSyncCubit>().pushPending();
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

  /// Marks a stop missed with the rep's reason (always) and proof photo (if
  /// taken), then reloads so the card reflects it immediately — the dashboard
  /// has no live `ActiveRouteBloc` for an arbitrary stop from this flattened
  /// list, so this writes straight through the usecases, the same way
  /// `CompleteVisitCheckOut` is triggered from contexts with no bloc.
  Future<void> _skipStop(
    BuildContext context,
    TodayStop todayStop,
    String reason,
    String? photoPath,
  ) async {
    final stopId = todayStop.stop.id;
    final now = DateTime.now();

    await sl<UpdateStopStatus>()(
        UpdateStopStatusParams(stopId: stopId, status: VisitStatus.missed));
    await sl<AddVisitNote>()(VisitNote(
      id: '${now.microsecondsSinceEpoch}',
      stopId: stopId,
      type: VisitNoteType.general,
      text: 'Visit skipped: $reason',
      createdAt: now,
    ));
    if (photoPath != null) {
      await sl<AddVisitPhoto>()(VisitPhoto(
        id: '${now.microsecondsSinceEpoch}-photo',
        stopId: stopId,
        url: photoPath,
        caption: 'Skip proof: $reason',
        takenAt: now,
      ));
    }

    if (context.mounted) {
      context.read<StopDashboardCubit>().reload();
    }
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
                  onSkipStop: (s, reason, photoPath) =>
                      _skipStop(context, s, reason, photoPath),
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
    required this.onSkipStop,
    required this.onFilter,
    required this.onQuery,
  });

  final StopDashboardLoaded state;
  final Future<void> Function() onRefresh;
  final void Function(TodayStop stop) onTapStop;
  final void Function(TodayStop stop, String reason, String? photoPath)
      onSkipStop;
  final void Function(StopFilter filter) onFilter;
  final void Function(String query) onQuery;

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  DateTime _focusedMonth = DateTime.now();

  int _getStopCountForDate(DateTime date) => widget.state.stopCountForDay(date);

  // Inside _LoadedViewState in stop_dashboard_screen.dart

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final visible = widget.state.visibleStops;

    // Check if the selected calendar date is TODAY
    final isSelectedToday = DateUtils.isSameDay(
      widget.state.selectedDate,
      DateTime.now(),
    );

    // Count metrics for progress bar
    final total = widget.state.stops.length;
    final visited = widget.state.stops
        .where((s) => s.stop.status == VisitStatus.checkedOut)
        .length;
    final skipped = widget.state.stops
        .where((s) => s.stop.status == VisitStatus.missed)
        .length;

    return RefreshIndicator(
      color: scheme.primary,
      backgroundColor: colors.surfaceSoft,
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rw(20), context.rh(12), context.rw(20), 0),
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
                  SizedBox(height: context.rh(14)),
                  TodayVisitProgressCard(
                    totalVisits: total,
                    visitedCount: visited,
                    skippedCount: skipped,
                  ),
                  SizedBox(height: context.rh(12)),
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
              padding: EdgeInsets.fromLTRB(context.rw(20), context.rh(4),
                  context.rw(20), context.rh(24)),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final todayStop = visible[index];
                  return StopCard(
                    todayStop: todayStop,
                    isToday:
                        isSelectedToday, // 👈 CRITICAL: Pass whether selected date is today
                    onTap: () => widget.onTapStop(todayStop),
                    onSkipSubmitted: (reason, photoPath) =>
                        widget.onSkipStop(todayStop, reason, photoPath),
                  );
                },
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
        padding: EdgeInsets.all(context.rw(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAnyStops
                  ? Icons.filter_alt_off_rounded
                  : Icons.event_available_rounded,
              size: context.rw(40),
              color: colors.textHint,
            ),
            SizedBox(height: context.rh(12)),
            Text(
              hasAnyStops
                  ? 'my_visits.stop_dashboard.no_matches'.tr
                  : 'my_visits.stop_dashboard.no_stops_today'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.rsp(14),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.rh(6)),
            Text(
              hasAnyStops
                  ? 'my_visits.stop_dashboard.no_matches_hint'.tr
                  : 'my_visits.stop_dashboard.pull_to_sync'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.textSecondary, fontSize: context.rsp(12)),
            ),
          ],
        ),
      ),
    );
  }
}
