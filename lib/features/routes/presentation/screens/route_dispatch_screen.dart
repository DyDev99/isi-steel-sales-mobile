import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/offline_banner.dart';
import 'package:isi_steel_sales_mobile/core/utils/page_transitions.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/services/geofence_service.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/screens/route_transit_screen.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/widgets/route_map.dart';

/// Step 1 of the guided field flow — Route Overview & Dispatch.
///
/// Shows the office-planned daily schedule as an ordered stop list with live
/// distance-from-current-location and status pills, and a sticky
/// "Start with [next shop]" CTA. Reps can deviate from the planned order (we
/// warn subtly but allow it). Pushed from `RouteDashboardScreen` with
/// `ActiveRouteBloc` / `LocationTrackingCubit` / `VisitCubit` already provided.
///
/// For now the CTA bridges straight into the existing `StopDetailScreen`
/// (check-in + capture); Step 2 (Transit & Navigation) will slot in between.
class RouteDispatchScreen extends StatefulWidget {
  const RouteDispatchScreen({super.key});

  /// Route name so the Step 4 "Build Quotation" handoff can `popUntil` back
  /// here before opening the order catalog.
  static const String routeName = 'route_dispatch';

  @override
  State<RouteDispatchScreen> createState() => _RouteDispatchScreenState();
}

class _RouteDispatchScreenState extends State<RouteDispatchScreen> {
  bool _trackingRequested = false;

  /// Begin GPS tracking once the route is loaded so the cards can show live
  /// distances. Guarded so it only fires once. If permission is denied the
  /// list simply falls back to "-- km".
  void _ensureTracking(RoutePlan route) {
    if (_trackingRequested) return;
    _trackingRequested = true;
    context.read<LocationTrackingCubit>().start(route.id, background: true);
  }

  /// First stop that still needs visiting — the planned "next" target.
  int _nextIndex(RoutePlan route) =>
      route.stops.indexWhere((s) => s.status != VisitStatus.checkedOut && s.status != VisitStatus.missed);

  Future<void> _startWithStop(BuildContext context, int index, {required int nextIndex}) async {
    HapticFeedback.mediumImpact();

    // Deviating from the office plan is allowed — just flag it gently.
    if (index != nextIndex) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('routes.flow.deviation_warning'.tr),
          duration: const Duration(seconds: 2),
        ));
    }

    final bloc = context.read<ActiveRouteBloc>();
    final state = bloc.state;
    if (state is! ActiveRouteReady) return;
    if (!state.dayStarted) bloc.add(const StartDayRequested());
    bloc.add(StopSelected(index));

    // Forward the shared blocs into Step 2 (Transit). The geofence listener on
    // this Dispatch screen stays mounted underneath and keeps ActiveRouteBloc's
    // insideGeofence/distance updated for the selected stop.
    final visitCubit = context.read<VisitCubit>();
    final locationCubit = context.read<LocationTrackingCubit>();
    await Navigator.of(context).push(slideLeftRoute(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: visitCubit),
          BlocProvider.value(value: locationCubit),
        ],
        child: const RouteTransitScreen(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: Text('routes.flow.dispatch_title'.tr,
            style: const TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      // Keep the geofence status live for the selected stop even while the
      // pushed StopDetailScreen sits on top — this listener stays mounted.
      body: BlocListener<LocationTrackingCubit, LocationTrackingState>(
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
          builder: (context, state) => switch (state) {
            ActiveRouteReady() => _DispatchBody(
                route: state.route,
                onStart: (i, nextIndex) => _startWithStop(context, i, nextIndex: nextIndex),
                onReady: _ensureTracking,
                nextIndex: _nextIndex(state.route),
              ),
            ActiveRouteCompleted(:final route) => _DispatchBody(
                route: route,
                onStart: (i, nextIndex) => _startWithStop(context, i, nextIndex: nextIndex),
                onReady: _ensureTracking,
                nextIndex: _nextIndex(route),
              ),
            ActiveRouteError(:final message) => Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
            _ => const Center(child: CircularProgressIndicator(color: Vibe.violet)),
          },
        ),
      ),
    );
  }
}

class _DispatchBody extends StatelessWidget {
  const _DispatchBody({
    required this.route,
    required this.onStart,
    required this.onReady,
    required this.nextIndex,
  });

  final RoutePlan route;
  final void Function(int index, int nextIndex) onStart;
  final ValueChanged<RoutePlan> onReady;
  final int nextIndex;

  bool get _allDone => nextIndex < 0;

  @override
  Widget build(BuildContext context) {
    // Kick off tracking once the route is available (post-frame to avoid
    // emitting during build).
    WidgetsBinding.instance.addPostFrameCallback((_) => onReady(route));

    final stops = route.stops;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              const OfflineBanner(margin: EdgeInsets.only(bottom: 12)),
              _Header(name: route.name, stopCount: route.totalStops),
              const SizedBox(height: 6),
              Text(
                'routes.flow.dispatch_helper'.tr,
                style: const TextStyle(color: Vibe.muted, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              BlocBuilder<LocationTrackingCubit, LocationTrackingState>(
                builder: (context, locationState) {
                  final current = locationState.current;
                  return Column(
                    children: [
                      for (var i = 0; i < stops.length; i++)
                        _StopDispatchCard(
                          stop: stops[i],
                          isNext: i == nextIndex,
                          distanceMeters: current == null
                              ? null
                              : GeofenceService.distanceMeters(
                                  current.latitude,
                                  current.longitude,
                                  stops[i].customer.latitude,
                                  stops[i].customer.longitude,
                                ),
                          onTap: () => onStart(i, nextIndex),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        _DispatchCta(
          label: _allDone
              ? 'routes.flow.route_complete'.tr
              : 'routes.flow.start_with'.tr.replaceAll('{shop}', stops[nextIndex].customer.name),
          enabled: !_allDone,
          onTap: _allDone ? null : () => onStart(nextIndex, nextIndex),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.stopCount});
  final String name;
  final int stopCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(color: Vibe.text, fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Vibe.violet.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$stopCount ${'routes.flow.shops'.tr}',
              style: const TextStyle(color: Vibe.violet, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _StopDispatchCard extends StatelessWidget {
  const _StopDispatchCard({
    required this.stop,
    required this.isNext,
    required this.distanceMeters,
    required this.onTap,
  });

  final RouteStop stop;
  final bool isNext;
  final double? distanceMeters;
  final VoidCallback onTap;

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' };
  }

  String get _distanceLabel {
    if (distanceMeters == null) return '-- km';
    final km = distanceMeters! / 1000;
    return km < 0.1 ? '${distanceMeters!.round()} m' : '${km.toStringAsFixed(1)} km';
  }

  ({String label, Color color}) get _pill {
    if (isNext) return (label: 'routes.flow.pill_next'.tr, color: Vibe.violet);
    return switch (stop.status) {
      VisitStatus.checkedOut => (label: 'routes.flow.pill_done'.tr, color: Vibe.success),
      VisitStatus.missed => (label: 'routes.flow.pill_missed'.tr, color: Vibe.danger),
      VisitStatus.checkedIn => (label: 'routes.flow.pill_checked_in'.tr, color: Vibe.amber),
      _ => (label: 'routes.flow.pill_pending'.tr, color: Vibe.muted),
    };
  }

  @override
  Widget build(BuildContext context) {
    final pill = _pill;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isNext ? Vibe.violet : Vibe.violet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _ordinal(stop.sequence),
                style: TextStyle(
                  color: isNext ? Colors.white : Vibe.violet,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    '${stop.customer.territory} · $_distanceLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Vibe.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: pill.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(pill.label,
                  style: TextStyle(color: pill.color, fontSize: 10.5, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DispatchCta extends StatelessWidget {
  const _DispatchCta({required this.label, required this.enabled, required this.onTap});
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Vibe.bg,
        border: Border(top: BorderSide(color: Vibe.stroke)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(enabled ? Icons.navigation_rounded : Icons.check_circle_rounded, size: 20),
            label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? Vibe.violet : Vibe.stroke,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Vibe.success.withValues(alpha: 0.6),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }
}
