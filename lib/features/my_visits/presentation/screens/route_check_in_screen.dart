import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/offline_banner.dart';
import 'package:isi_steel_sales_mobile/core/utils/page_transitions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/proof_photo_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/events/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/visit_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_stock_count_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/transit_map.dart';

/// Flip to false before shipping to follow strict physical device live geolocations
const bool kDebugForceInsideGeofence = true;

class RouteCheckInScreen extends StatefulWidget {
  const RouteCheckInScreen({super.key});

  @override
  State<RouteCheckInScreen> createState() => _RouteCheckInScreenState();
}

class _RouteCheckInScreenState extends State<RouteCheckInScreen> {
  bool _capturing = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<ActiveRouteBloc>().state;
    if (state is ActiveRouteReady && state.hasCurrentStop) {
      context
          .read<VisitCubit>()
          .load(state.route.stops[state.currentStopIndex].id);
    }
  }

  static int _etaMinutes(double meters) =>
      max(1, ((meters / 1000) / 25 * 60).round());

  static String _distanceLabel(double meters) {
    final km = meters / 1000;
    return km < 0.1 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
  }

  Future<void> _capture(RouteStop stop) async {
    if (_capturing) return;
    HapticFeedback.lightImpact();
    final pos = context.read<LocationTrackingCubit>().state.current;

    setState(() => _capturing = true);

    final result = await sl<ProofPhotoService>().captureStamped(
      latitude: pos?.latitude ?? stop.customer.latitude,
      longitude: pos?.longitude ?? stop.customer.longitude,
    );

    if (!mounted) return;
    setState(() => _capturing = false);

    if (result == null) return;
    // Persisted to the Drift-backed VisitCubit/VisitRepository immediately so
    // the photo survives rebuilds, navigation, and app restarts instead of
    // living only in this screen's ephemeral State.
    context.read<VisitCubit>().addPhoto(VisitPhoto(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          stopId: stop.id,
          url: result.filePath,
          caption: 'Shopfront proof',
          takenAt: result.takenAt,
        ));
  }

  void _submit(RouteStop stop) {
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    context.read<ActiveRouteBloc>().add(const CheckInRequested());
  }

  static List<VisitPhoto> _photosForStop(VisitState state, String stopId) {
    if (state is! VisitLoaded) return const [];
    return state.data.photos.where((p) => p.stopId == stopId).toList();
  }

  void _goToVisit(BuildContext context) {
    final bloc = context.read<ActiveRouteBloc>();
    final visitCubit = context.read<VisitCubit>();
    Navigator.of(context).pushReplacement(slideLeftRoute(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: visitCubit),
        ],
        child: const RouteStockCountScreen(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scheme.surface,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'my_visits.flow.checkin_title'.tr,
          style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<ActiveRouteBloc, ActiveRouteState>(
        listener: (context, state) {
          if (!_submitting ||
              state is! ActiveRouteReady ||
              !state.hasCurrentStop) {
            return;
          }
          final stop = state.route.stops[state.currentStopIndex];
          if (stop.status == VisitStatus.checkedIn) {
            _submitting = false;
            _goToVisit(context);
          } else if (state.blockedCheckInReason != null) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                  SnackBar(content: Text(state.blockedCheckInReason!)));
          }
        },
        child: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
          builder: (context, state) {
            if (state is! ActiveRouteReady || !state.hasCurrentStop) {
              return Center(
                  child: Text('my_visits.flow.no_stop'.tr,
                      style: TextStyle(color: colors.textSecondary)));
            }

            final stop = state.route.stops[state.currentStopIndex];
            final bool dynamicInsideGeofence =
                state.insideGeofence || kDebugForceInsideGeofence;

            return BlocBuilder<VisitCubit, VisitState>(
              builder: (context, visitState) {
                final photos = _photosForStop(visitState, stop.id);
                final bool canSubmit = dynamicInsideGeofence &&
                    photos.isNotEmpty &&
                    !_submitting;

                return Column(
                  children: [
                    const OfflineBanner(margin: EdgeInsets.zero),

                    // Segment 1: Header Customer Profile Info Card
                    _UnifiedCustomerHeader(
                      stop: stop,
                      distanceLabel: _distanceLabel(state.distanceMeters),
                      etaMinutes: _etaMinutes(state.distanceMeters),
                    ),

                    // Segment 2: Interactive Real-time Embedded Map Viewport
                    Expanded(
                      flex: 4,
                      child: BlocBuilder<LocationTrackingCubit,
                          LocationTrackingState>(
                        builder: (context, locationState) => TransitMap(
                          target: stop,
                          currentPosition: locationState.current,
                        ),
                      ),
                    ),

                    // Segment 3: Workspace Action Board
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.card,
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadowColor.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, -4),
                            )
                          ],
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          children: [
                            _GeoStatusBanner(
                              insideGeofence: dynamicInsideGeofence,
                              distanceMeters: state.distanceMeters,
                              blockedReason: state.blockedCheckInReason,
                              warnings: state.checkInWarnings,
                              radiusMeters:
                                  stop.customer.geofenceRadiusMeters.round(),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Text(
                                  'my_visits.flow.proof_photo'.tr,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                if (dynamicInsideGeofence && photos.isEmpty)
                                  _PulseIndicator(),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _CameraDropzone(
                              photos: photos,
                              capturing: _capturing,
                              isLocked: !dynamicInsideGeofence,
                              onTap: () => _capture(stop),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'my_visits.flow.checkin_explainer'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Contextual CTA Processing Button Bar
                    _CheckInBottomBar(
                      enabled: canSubmit,
                      submitting: _submitting,
                      hint: !dynamicInsideGeofence
                          ? 'my_visits.flow.hint_move_inside'.tr
                          : (photos.isEmpty
                              ? 'my_visits.flow.hint_take_photo'.tr
                              : null),
                      onTap: () => _submit(stop),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UnifiedCustomerHeader extends StatelessWidget {
  const _UnifiedCustomerHeader({
    required this.stop,
    required this.distanceLabel,
    required this.etaMinutes,
  });

  final RouteStop stop;
  final String distanceLabel;
  final int etaMinutes;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: colors.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  stop.customer.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.navigation_rounded, color: scheme.primary, size: 13),
                const SizedBox(width: 4),
                Text(
                  '$distanceLabel • ~$etaMinutes ${'my_visits.flow.minutes_shortTemplate'.tr}',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _GeoStatusBanner extends StatelessWidget {
  const _GeoStatusBanner({
    required this.insideGeofence,
    required this.distanceMeters,
    required this.blockedReason,
    required this.warnings,
    required this.radiusMeters,
  });

  final bool insideGeofence;
  final double distanceMeters;
  final String? blockedReason;
  final List<String> warnings;
  final int radiusMeters;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusPill(
          color: insideGeofence ? colors.success : colors.warning,
          icon: insideGeofence
              ? Icons.check_circle_rounded
              : Icons.location_searching_rounded,
          text: insideGeofence
              ? 'my_visits.flow.geo_matchedTemplate'.tr
              : 'my_visits.flow.geo_not_matched'
                  .tr
                  .replaceAll('{dist}', distanceMeters.toStringAsFixed(0)),
          subtitle: insideGeofence
              ? 'my_visits.flow.transit_banner_ready'.tr
              : 'my_visits.flow.transit_disclaimer'
                  .tr
                  .replaceAll('{radius}', '$radiusMeters'),
        ),
        if (blockedReason != null) ...[
          const SizedBox(height: 6),
          _StatusPill(
              color: scheme.error,
              icon: Icons.block_rounded,
              text: blockedReason!),
        ],
        for (final warning in warnings) ...[
          const SizedBox(height: 6),
          _StatusPill(
              color: colors.warning,
              icon: Icons.warning_amber_rounded,
              text: warning),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(
      {required this.color,
      required this.icon,
      required this.text,
      this.subtitle});
  final Color color;
  final IconData icon;
  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(subtitle!,
                      style: TextStyle(
                          color: color.withValues(alpha: 0.85),
                          fontSize: 10.5)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraDropzone extends StatelessWidget {
  const _CameraDropzone({
    required this.photos,
    required this.capturing,
    required this.isLocked,
    required this.onTap,
  });

  final List<VisitPhoto> photos;
  final bool capturing;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final borderColor = isLocked
        ? colors.border
        : (photos.isNotEmpty
            ? colors.success
            : scheme.primary.withValues(alpha: 0.5));

    return GestureDetector(
      onTap: (capturing || isLocked) ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.55 : 1.0,
        child: CustomPaint(
          painter: _DashedBorderPainter(color: borderColor, radius: 12),
          child: Container(
            height: 180, // Optimized tracking screen height limit bounds
            width: double.infinity,
            decoration: BoxDecoration(
              color: isLocked ? colors.surfaceSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: capturing
                ? Center(
                    child: CircularProgressIndicator(color: scheme.primary))
                : photos.isEmpty
                    ? _DropzonePlaceholder(isLocked: isLocked)
                    : _ProofGallery(photos: photos),
          ),
        ),
      ),
    );
  }
}

class _DropzonePlaceholder extends StatelessWidget {
  const _DropzonePlaceholder({required this.isLocked});
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (isLocked ? colors.textSecondary : scheme.primary)
                .withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLocked ? Icons.lock_outline_rounded : Icons.photo_camera_rounded,
            color: isLocked ? colors.textSecondary : scheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLocked
              ? 'my_visits.flow.transit_banner_lockedTemplate'.tr
              : 'my_visits.flow.take_photo'.tr,
          style: TextStyle(
              color: isLocked ? colors.textSecondary : colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          'my_visits.flow.fit_frame'.tr,
          style: TextStyle(color: colors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _ProofGallery extends StatelessWidget {
  const _ProofGallery({required this.photos});
  final List<VisitPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.file(File(photos[index].url), fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_a_photo_rounded,
                    color: Colors.white, size: 13),
                const SizedBox(width: 4),
                Text(
                  '${photos.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckInBottomBar extends StatelessWidget {
  const _CheckInBottomBar(
      {required this.enabled,
      required this.submitting,
      required this.hint,
      required this.onTap});
  final bool enabled;
  final bool submitting;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint != null) ...[
              Text(hint!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: enabled ? onTap : null,
                icon: submitting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: scheme.onPrimary))
                    : Icon(
                        enabled
                            ? Icons.check_circle_rounded
                            : Icons.lock_rounded,
                        size: 18),
                label: Text(
                  'my_visits.flow.checkin_continue'.tr,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: enabled ? colors.success : scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  disabledBackgroundColor: colors.border,
                  disabledForegroundColor: colors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: enabled ? 2 : 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1 + (_controller.value * 0.15)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'REQUIRED',
          style: TextStyle(
            color: primary.withValues(alpha: 0.7 + (_controller.value * 0.3)),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
