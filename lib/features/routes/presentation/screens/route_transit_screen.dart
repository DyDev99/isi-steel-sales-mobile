import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/page_transitions.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/screens/route_check_in_screen.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/widgets/transit_map.dart';

/// Step 2 of the guided field flow — Transit & Navigation Preview.
///
/// Once a rep commits to a destination on the Dispatch screen, this shows a
/// live map (GPS dot + target geofence + route line), a ticking distance/ETA,
/// and an "I've Arrived" CTA that stays **locked** until the device's live
/// position enters the shop's geofence — a proof-of-presence gate before the
/// check-in + stock audit unlocks.
///
/// Geofence status is fed by the still-mounted Dispatch screen's
/// `LocationTrackingCubit` listener into `ActiveRouteBloc`, so this screen just
/// reads `insideGeofence` / `distanceMeters` for the selected stop.
///
/// The "I've Arrived" CTA currently bridges into the existing
/// `StopDetailScreen`; Step 3 (Geofence Check-in + proof photo) will replace it.
class RouteTransitScreen extends StatelessWidget {
  const RouteTransitScreen({super.key});

  /// Rough urban ETA — average 25 km/h, floor of 1 minute.
  static int _etaMinutes(double meters) => max(1, ((meters / 1000) / 25 * 60).round());

  static String _distanceLabel(double meters) {
    final km = meters / 1000;
    return km < 0.1 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
  }

  Future<void> _arrived(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final bloc = context.read<ActiveRouteBloc>();
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

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
        builder: (context, state) {
          if (state is! ActiveRouteReady || !state.hasCurrentStop) {
            return Center(child: Text('routes.flow.no_stop'.tr, style: const TextStyle(color: Vibe.muted)));
          }
          final stop = state.route.stops[state.currentStopIndex];
          final radius = stop.customer.geofenceRadiusMeters.round();

          return Column(
            children: [
              _TransitHeader(
                stop: stop,
                insideGeofence: state.insideGeofence,
                distanceMeters: state.distanceMeters,
                etaMinutes: _etaMinutes(state.distanceMeters),
                distanceLabel: _distanceLabel(state.distanceMeters),
              ),
              Expanded(
                child: BlocBuilder<LocationTrackingCubit, LocationTrackingState>(
                  builder: (context, locationState) => TransitMap(
                    target: stop,
                    currentPosition: locationState.current,
                  ),
                ),
              ),
              _ArrivalBar(
                insideGeofence: state.insideGeofence,
                radiusMeters: radius,
                onArrived: () => _arrived(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TransitHeader extends StatelessWidget {
  const _TransitHeader({
    required this.stop,
    required this.insideGeofence,
    required this.distanceMeters,
    required this.etaMinutes,
    required this.distanceLabel,
  });

  final RouteStop stop;
  final bool insideGeofence;
  final double distanceMeters;
  final int etaMinutes;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Vibe.text),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(stop.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Vibe.text, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(stop.customer.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Vibe.muted, fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.route_rounded, color: Vibe.violet, size: 15),
                      const SizedBox(width: 5),
                      Text(distanceLabel, style: const TextStyle(color: Vibe.text, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule_rounded, color: Vibe.violet, size: 15),
                      const SizedBox(width: 5),
                      Text('~$etaMinutes ${'routes.flow.minutes_short'.tr}',
                          style: const TextStyle(color: Vibe.text, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrivalBar extends StatelessWidget {
  const _ArrivalBar({required this.insideGeofence, required this.radiusMeters, required this.onArrived});
  final bool insideGeofence;
  final int radiusMeters;
  final VoidCallback onArrived;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (insideGeofence ? Vibe.success : Vibe.violet).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(insideGeofence ? Icons.check_circle_rounded : Icons.my_location_rounded,
                      color: insideGeofence ? Vibe.success : Vibe.violet, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insideGeofence
                          ? 'routes.flow.transit_banner_ready'.tr
                          : 'routes.flow.transit_banner_locked'.tr,
                      style: TextStyle(
                        color: insideGeofence ? Vibe.success : Vibe.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _ArrivedButton(enabled: insideGeofence, onTap: onArrived),
            const SizedBox(height: 6),
            Text(
              'routes.flow.transit_disclaimer'.tr.replaceAll('{radius}', '$radiusMeters'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Vibe.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// "I've Arrived" — locked (grey, disabled) until inside the geofence, then it
/// turns green and pulses to draw the eye.
class _ArrivedButton extends StatefulWidget {
  const _ArrivedButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_ArrivedButton> createState() => _ArrivedButtonState();
}

class _ArrivedButtonState extends State<_ArrivedButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ArrivedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      HapticFeedback.lightImpact();
      _pulse.repeat(reverse: true);
    } else if (!widget.enabled && oldWidget.enabled) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = widget.enabled ? 0.25 + _pulse.value * 0.35 : 0.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.enabled
                ? [BoxShadow(color: Vibe.success.withValues(alpha: glow), blurRadius: 22, spreadRadius: 2)]
                : null,
          ),
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.enabled ? widget.onTap : null,
          icon: Icon(widget.enabled ? Icons.check_circle_rounded : Icons.lock_rounded, size: 20),
          label: Text('routes.flow.ive_arrived'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Vibe.success,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Vibe.stroke,
            disabledForegroundColor: Vibe.muted,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
