import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/offline_banner.dart';
import 'package:isi_steel_sales_mobile/core/utils/page_transitions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/events/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_check_in_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_info/route_info_hero_header.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_info/route_info_map_preview.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_info/route_info_objectives.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_info/route_info_quick_actions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_info/route_info_stats_row.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_info/route_info_timeline.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_info/skip_stop_reason_dialog.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/route_map.dart';

/// Route Information — the visit preparation screen (new "Before Check-In" step).
///
/// Replaces the old "choose stop" Dispatch step in the primary flow: it shows
/// everything about the selected route (hero, stats, timeline, map, objectives,
/// quick actions) and hands off to Check-In via a single "Start Visit" CTA.
///
/// Business logic is unchanged — it drives the same `ActiveRouteBloc`
/// (`StartDayRequested`/`StopSelected`), keeps the geofence listener live
/// underneath Check-In, and forwards the same bloc/cubit instances forward
/// (mirrors `RouteDispatchScreen._startWithStop`).
class RouteInformationScreen extends StatefulWidget {
  const RouteInformationScreen({super.key});

  static const String routeName = 'route_information';

  @override
  State<RouteInformationScreen> createState() => _RouteInformationScreenState();
}

class _RouteInformationScreenState extends State<RouteInformationScreen> {
  bool _trackingRequested = false;

  void _ensureTracking(RoutePlan route) {
    if (_trackingRequested) return;
    _trackingRequested = true;
    context.read<LocationTrackingCubit>().start(route.id, background: true);
  }

  int _nextIndex(RoutePlan route) => route.stops.indexWhere((s) =>
      s.status != VisitStatus.checkedOut && s.status != VisitStatus.missed);

  /// Straight-line inter-stop distance + a coarse duration estimate — a display
  /// figure shown as an estimate, mirroring `RouteDashboardCubit`'s approach
  /// (25 km/h blended field average, ~15 min per stop). Pure, no side effects.
  ({double distanceKm, int durationMin}) _estimate(RoutePlan route) {
    var meters = 0.0;
    for (var i = 1; i < route.stops.length; i++) {
      final a = route.stops[i - 1].customer;
      final b = route.stops[i].customer;
      meters += GeofenceService.distanceMeters(
          a.latitude, a.longitude, b.latitude, b.longitude);
    }
    final km = meters / 1000;
    final driving = km <= 0 ? 0 : ((km / 25) * 60).round();
    return (distanceKm: km, durationMin: driving + route.stops.length * 15);
  }

  Future<void> _start(BuildContext context, RoutePlan route, int index) async {
    final nextIndex = _nextIndex(route);
    if (index < 0) return;
    HapticFeedback.mediumImpact();

    if (index != nextIndex && nextIndex >= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('my_visits.flow.deviation_warning'.tr),
          duration: const Duration(seconds: 2),
        ));
    }

    final bloc = context.read<ActiveRouteBloc>();
    final state = bloc.state;
    if (state is! ActiveRouteReady) return;
    if (!state.dayStarted) bloc.add(const StartDayRequested());
    bloc.add(StopSelected(index));

    final visitCubit = context.read<VisitCubit>();
    final locationCubit = context.read<LocationTrackingCubit>();
    await Navigator.of(context).push(slideLeftRoute(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: visitCubit),
          BlocProvider.value(value: locationCubit),
        ],
        child: const RouteCheckInScreen(),
      ),
    ));
  }

  /// Skipping a stop always goes through a required-reason dialog first
  /// ([SkipStopReasonDialog]); only a real reason dispatches the skip, which
  /// marks the stop missed and records the reason.
  Future<void> _skip(BuildContext context, RoutePlan route, int index) async {
    if (index < 0 || index >= route.stops.length) return;
    final stop = route.stops[index];
    HapticFeedback.selectionClick();
    final bloc = context.read<ActiveRouteBloc>();

    final reason =
        await SkipStopReasonDialog.show(context, stopName: stop.customer.name);
    if (reason == null || !context.mounted) return;

    bloc.add(SkipStopRequested(index: index, reason: reason));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('my_visits.route_info.skip_done'.tr),
        duration: const Duration(seconds: 2),
      ));
  }

  void _onQuickAction(BuildContext context, RouteInfoAction action) {
    // Phase 1: Call/Navigate/Customer/Notes/History are surfaced as premium
    // affordances but not yet wired (needs url_launcher + customer-detail
    // route). Honest placeholder rather than a dead tap.
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('my_visits.route_info.action_coming_soon'.tr),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.canvas,
      // Full-bleed hero has no AppBar, so a floating back button is overlaid to
      // return to the dashboard route list.
      body: Stack(
        children: [
          _buildContent(context, colors),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: const _RouteInfoBackButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeColors colors) {
    // Keep the geofence status live for the selected stop while Check-In sits
    // on top — this listener stays mounted (moved here from Dispatch).
    return BlocListener<LocationTrackingCubit, LocationTrackingState>(
        listener: (context, locationState) {
          final position = locationState.current;
          final activeState = context.read<ActiveRouteBloc>().state;
          if (position == null || activeState is! ActiveRouteReady) return;
          final geofence = evaluateStopGeofence(
            stops: activeState.route.stops,
            currentStopIndex: activeState.currentStopIndex,
            latitude: position.latitude,
            longitude: position.longitude,
          );
          if (geofence == null) return;
          context.read<ActiveRouteBloc>().add(GeofenceStatusChanged(
                insideGeofence: geofence.insideGeofence,
                distanceMeters: geofence.distanceMeters,
                accuracyMeters: position.accuracyMeters,
                isMocked: position.isMocked,
                latitude: position.latitude,
                longitude: position.longitude,
              ));
        },
        child: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
          builder: (context, state) {
            final route = switch (state) {
              ActiveRouteReady(:final route) => route,
              ActiveRouteCompleted(:final route) => route,
              _ => null,
            };
            if (route == null) {
              if (state is ActiveRouteError) {
                return Center(
                    child: Text(state.message,
                        style: TextStyle(color: colors.textSecondary)));
              }
              return const Center(child: CircularProgressIndicator());
            }

            WidgetsBinding.instance
                .addPostFrameCallback((_) => _ensureTracking(route));
            final skipReasons = state is ActiveRouteReady
                ? state.skipReasons
                : const <String, String>{};
            return _RouteInfoBody(
              route: route,
              nextIndex: _nextIndex(route),
              estimate: _estimate(route),
              onStartStop: (i) => _start(context, route, i),
              onSkipStop: (i) => _skip(context, route, i),
              skipReasons: skipReasons,
              onQuickAction: (a) => _onQuickAction(context, a),
            );
          },
        ),
    );
  }
}

/// Frosted circular back button overlaid on the hero — returns to the dashboard
/// route list. Themed so it reads on both the navy hero and the canvas
/// loading/error states.
class _RouteInfoBackButton extends StatelessWidget {
  const _RouteInfoBackButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.card.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        child: Padding(
          padding: EdgeInsets.all(9.w),
          child: Icon(Icons.arrow_back_rounded,
              size: 22.w, color: colors.textPrimary),
        ),
      ),
    );
  }
}

class _RouteInfoBody extends StatelessWidget {
  const _RouteInfoBody({
    required this.route,
    required this.nextIndex,
    required this.estimate,
    required this.onStartStop,
    required this.onSkipStop,
    required this.skipReasons,
    required this.onQuickAction,
  });

  final RoutePlan route;
  final int nextIndex;
  final ({double distanceKm, int durationMin}) estimate;
  final ValueChanged<int> onStartStop;
  final ValueChanged<int> onSkipStop;
  final Map<String, String> skipReasons;
  final ValueChanged<RouteInfoAction> onQuickAction;

  @override
  Widget build(BuildContext context) {
    final allDone = nextIndex < 0;
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<LocationTrackingCubit, LocationTrackingState>(
            builder: (context, locationState) {
              final position = locationState.current;
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  RouteInfoHeroHeader(route: route),
                  SizedBox(height: 16.h),
                  const OfflineBanner(
                      margin: EdgeInsets.symmetric(horizontal: 20)),
                  RouteInfoStatsRow(
                    total: route.totalStops,
                    completed: route.completedStops,
                    remaining: route.totalStops - route.completedStops,
                    distanceKm: estimate.distanceKm,
                    durationMinutes: estimate.durationMin,
                  ),
                  SizedBox(height: 20.h),
                  _SectionTitle('my_visits.route_info.section_map'.tr),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: RouteInfoMapPreview(
                      stops: route.stops,
                      currentStopIndex: nextIndex < 0 ? 0 : nextIndex,
                      currentPosition: position,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _SectionTitle('my_visits.route_info.section_timeline'.tr),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: RouteInfoTimeline(
                      stops: route.stops,
                      nextIndex: nextIndex,
                      currentPosition: position,
                      onStartStop: onStartStop,
                      onSkipStop: onSkipStop,
                      skipReasons: skipReasons,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _SectionTitle('my_visits.route_info.section_objectives'.tr),
                  const RouteInfoObjectives(),
                  SizedBox(height: 20.h),
                  _SectionTitle('my_visits.route_info.section_actions'.tr),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: RouteInfoQuickActions(onAction: onQuickAction),
                  ),
                  SizedBox(height: 24.h),
                ],
              );
            },
          ),
        ),
        _StartVisitCta(
          enabled: !allDone,
          label: allDone
              ? 'my_visits.flow.route_complete'.tr
              : 'my_visits.route_info.start_visit'.tr,
          onTap: allDone ? null : () => onStartStop(nextIndex),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 10.h),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _StartVisitCta extends StatelessWidget {
  const _StartVisitCta(
      {required this.enabled, required this.label, required this.onTap});
  final bool enabled;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(
                enabled
                    ? Icons.play_arrow_rounded
                    : Icons.check_circle_rounded,
                size: 20.w),
            label: Text(label,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? scheme.primary : colors.success,
              foregroundColor: scheme.onPrimary,
              disabledBackgroundColor: colors.success.withValues(alpha: 0.6),
              disabledForegroundColor: scheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 15.h),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
          ),
        ),
      ),
    );
  }
}
