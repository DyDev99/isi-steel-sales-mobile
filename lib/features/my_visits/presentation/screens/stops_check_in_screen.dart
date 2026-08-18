import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/platform/local_files.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/offline_banner.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/proof_photo_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/events/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/visit_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_inventory_visibility.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/stop_information_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/transit_map.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/painters/dashed_rrect.dart';

const bool kDebugForceInsideGeofence = true;

class RouteCheckInScreen extends StatefulWidget {
  const RouteCheckInScreen({
    super.key,
    this.stop,
  });

  final RouteStop? stop;

  @override
  State<RouteCheckInScreen> createState() => _RouteCheckInScreenState();
}

class _RouteCheckInScreenState extends State<RouteCheckInScreen>
    with SingleTickerProviderStateMixin {
  bool _capturing = false;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /// Helper to safely obtain BLoC/Cubit instances from BuildContext or Service Locator
  static T _resolveBloc<T extends StateStreamableSource<Object?>>(
      BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return sl<T>();
    }
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    final initialStop = widget.stop;
    if (initialStop != null) {
      _resolveBloc<VisitCubit>(context).load(initialStop.id);
    } else {
      final activeRouteBloc = _resolveBloc<ActiveRouteBloc>(context);
      final state = activeRouteBloc.state;
      if (state is ActiveRouteReady && state.hasCurrentStop) {
        _resolveBloc<VisitCubit>(context)
            .load(state.route.stops[state.currentStopIndex].id);
      }
    }

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  static int _etaMinutes(double meters) =>
      max(1, ((meters / 1000) / 25 * 60).round());

  static String _distanceLabel(double meters) {
    final km = meters / 1000;
    return km < 0.1 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
  }

  Future<void> _capture(RouteStop stop) async {
    if (_capturing) return;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    final pos = _resolveBloc<LocationTrackingCubit>(context).state.current;
    setState(() => _capturing = true);

    try {
      final result = await sl<ProofPhotoService>().captureStamped(
        latitude: pos?.latitude ?? stop.customer.latitude,
        longitude: pos?.longitude ?? stop.customer.longitude,
      );

      if (!mounted) return;

      if (result != null) {
        _resolveBloc<VisitCubit>(context).addPhoto(VisitPhoto(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          stopId: stop.id,
          url: result.filePath,
          caption: 'my_visits.stop.shopfront_proof'.tr,
          takenAt: result.takenAt,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  void _submit(RouteStop stop) {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    // Fire-and-forget, like every other workflow write in this flow: a
    // slow/blocked validation surfaces on the next rebuild via
    // `blockedCheckInReason` (the geo-status banner already renders it), it
    // just doesn't hold up the guided flow here.
    _resolveBloc<ActiveRouteBloc>(context).add(const CheckInRequested());
    _goToVisit(context, stop);
  }

  static List<VisitPhoto> _photosForStop(VisitState state, String stopId) {
    if (state is! VisitLoaded) return const [];
    return state.data.photos.where((p) => p.stopId == stopId).toList();
  }

  void _expandMap(BuildContext context, RouteStop stop) {
    final locationCubit = _resolveBloc<LocationTrackingCubit>(context);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        fullscreenDialog: true,
        pageBuilder: (_, animation, secondaryAnimation) => BlocProvider.value(
          value: locationCubit,
          child: FadeTransition(
            opacity: animation,
            child: _FullScreenTransitMap(stop: stop),
          ),
        ),
      ),
    );
  }

  void _goToVisit(BuildContext context, RouteStop stop) {
    final navigator = Navigator.of(context);

    // No explicit workflow write here: the `CheckInRequested` dispatched in
    // `_submit` already seeds it — `ActiveRouteBloc._writeWorkflowPointer`
    // sets the baseline resume pointer to the Inventory Visibility step as
    // soon as the check-in lands.
    navigator
        .popUntil((r) => r.settings.name == StopInformationScreen.routeName);

    openInventoryVisibilityForCustomer(
      navigator.context,
      customerId: stop.customer.id,
      customerName: context.localized(stop.customer.displayName),
    );
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final activeRouteBloc = _resolveBloc<ActiveRouteBloc>(context);
    final visitCubit = _resolveBloc<VisitCubit>(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'my_visits.flow.checkin_title'.tr,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: context.rsp(17),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
        bloc: activeRouteBloc,
        builder: (context, state) {
          final RouteStop? stop = widget.stop ??
              ((state is ActiveRouteReady && state.hasCurrentStop)
                  ? state.route.stops[state.currentStopIndex]
                  : null);

          if (stop == null) {
            return Center(
              child: CircularProgressIndicator(
                color: scheme.primary,
                strokeWidth: 2.8,
              ),
            );
          }

          final bool dynamicInsideGeofence =
              (state is ActiveRouteReady ? state.insideGeofence : false) ||
                  kDebugForceInsideGeofence;
          final double distanceMeters =
              state is ActiveRouteReady ? state.distanceMeters : 0.0;
          final String? blockedReason =
              state is ActiveRouteReady ? state.blockedCheckInReason : null;
          final List<String> warnings =
              state is ActiveRouteReady ? state.checkInWarnings : const [];

          return BlocBuilder<VisitCubit, VisitState>(
            bloc: visitCubit,
            builder: (context, visitState) {
              final photos = _photosForStop(visitState, stop.id);

              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      const OfflineBanner(margin: EdgeInsets.zero),

                      // Segment 1: Customer Header Card
                      _UnifiedCustomerHeader(
                        stop: stop,
                        distanceLabel: _distanceLabel(distanceMeters),
                        etaMinutes: _etaMinutes(distanceMeters),
                      ),

                      // Segment 2: Interactive Real-time Map Viewport
                      Expanded(
                        flex: 4,
                        child: BlocBuilder<LocationTrackingCubit,
                            LocationTrackingState>(
                          bloc: _resolveBloc<LocationTrackingCubit>(context),
                          builder: (context, locationState) => Stack(
                            children: [
                              Positioned.fill(
                                child: TransitMap(
                                  target: stop,
                                  currentPosition: locationState.current,
                                ),
                              ),
                              Positioned(
                                right: 14,
                                top: 14,
                                child: _MapExpandButton(
                                  onTap: () => _expandMap(context, stop),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Segment 3: Workspace Action Board
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, -6),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 20, 12),
                              shrinkWrap: true,
                              children: [
                                _GeoStatusBanner(
                                  insideGeofence: dynamicInsideGeofence,
                                  distanceMeters: distanceMeters,
                                  blockedReason: blockedReason,
                                  warnings: warnings,
                                  radiusMeters: stop
                                      .customer.geofenceRadiusMeters
                                      .round(),
                                ),
                                SizedBox(height: context.rh(18)),
                                Row(
                                  children: [
                                    Text(
                                      'my_visits.flow.proof_photo'.tr,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: context.rsp(14),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (photos.isEmpty) _PulseIndicator(),
                                  ],
                                ),
                                SizedBox(height: context.rh(12)),
                                _CameraDropzone(
                                  photos: photos,
                                  capturing: _capturing,
                                  isLocked: false,
                                  onTap: () => _capture(stop),
                                ),
                                SizedBox(height: context.rh(10)),
                                Text(
                                  'my_visits.flow.checkin_explainer'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: context.rsp(11.5),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Contextual Bottom CTA
                      _CheckInBottomBar(
                        enabled: true,
                        submitting: false,
                        hint: null,
                        onTap: () => _submit(stop),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.localized(stop.customer.displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(17),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: context.rh(3)),
                Text(
                  stop.customer.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.rsp(12.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.rw(12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.navigation_rounded,
                  color: scheme.primary,
                  size: context.rr(14),
                ),
                SizedBox(width: context.rw(5)),
                Text(
                  '$distanceLabel • ~$etaMinutes ${'my_visits.flow.minutes_shortTemplate'.tr}',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: context.rsp(11.5),
                    fontWeight: FontWeight.w800,
                  ),
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
          SizedBox(height: context.rh(8)),
          _StatusPill(
            color: scheme.error,
            icon: Icons.block_rounded,
            text: blockedReason!,
          ),
        ],
        for (final warning in warnings) ...[
          SizedBox(height: context.rh(8)),
          _StatusPill(
            color: colors.warning,
            icon: Icons.warning_amber_rounded,
            text: warning,
          ),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.color,
    required this.icon,
    required this.text,
    this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: context.rr(18), color: color),
          SizedBox(width: context.rw(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: context.rsp(12.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: context.rh(2)),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: context.rsp(11),
                    ),
                  ),
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
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isLocked ? 0.55 : 1.0,
        child: CustomPaint(
          painter: _DashedBorderPainter(color: borderColor, radius: 16),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isLocked
                  ? colors.surfaceSoft
                  : scheme.primary.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: capturing
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary,
                    ),
                  )
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: context.rh(48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (isLocked ? colors.textSecondary : scheme.primary)
                .withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLocked ? Icons.lock_outline_rounded : Icons.camera_alt_rounded,
            color: isLocked ? colors.textSecondary : scheme.primary,
            size: context.rr(22),
          ),
        ),
        SizedBox(height: context.rh(10)),
        Text(
          isLocked
              ? 'my_visits.flow.transit_banner_locked'.tr
              : 'my_visits.flow.take_photo'.tr,
          style: TextStyle(
            color: isLocked ? colors.textSecondary : colors.textPrimary,
            fontSize: context.rsp(13.5),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: context.rh(3)),
        Text(
          'my_visits.flow.fit_frame'.tr,
          style: TextStyle(color: colors.textSecondary, fontSize: context.rsp(11.5)),
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
          padding: EdgeInsets.all(context.rr(10)),
          itemCount: photos.length,
          separatorBuilder: (_, __) => SizedBox(width: context.rw(10)),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: localFileImage(photos[index].url, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_rounded,
                  color: Colors.white,
                  size: context.rr(13),
                ),
                SizedBox(width: context.rw(5)),
                Text(
                  '${photos.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.rsp(11.5),
                    fontWeight: FontWeight.w800,
                  ),
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
  const _CheckInBottomBar({
    required this.enabled,
    required this.submitting,
    required this.hint,
    required this.onTap,
  });

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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint != null) ...[
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: context.rsp(11.5)),
              ),
              SizedBox(height: context.rh(8)),
            ],
            SizedBox(
              width: double.infinity,
              height: context.rh(52),
              child: ElevatedButton.icon(
                onPressed: enabled ? onTap : null,
                icon: submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Icon(
                        enabled
                            ? Icons.check_circle_rounded
                            : Icons.lock_rounded,
                        size: context.rr(20),
                      ),
                label: Text(
                  'my_visits.flow.checkin_continue'.tr,
                  style: TextStyle(
                    fontSize: context.rsp(15),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: enabled ? colors.success : scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  disabledBackgroundColor: colors.border,
                  disabledForegroundColor: colors.textSecondary,
                  elevation: enabled ? 3 : 0,
                  shadowColor: colors.success.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
    duration: const Duration(milliseconds: 900),
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1 + (_controller.value * 0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'REQUIRED',
          style: TextStyle(
            color: primary.withValues(alpha: 0.75 + (_controller.value * 0.25)),
            fontSize: context.rsp(9.5),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _MapExpandButton extends StatelessWidget {
  const _MapExpandButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: colors.card.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.open_in_full_rounded,
                    size: context.rr(13),
                    color: colors.textPrimary,
                  ),
                  SizedBox(width: context.rw(6)),
                  Text(
                    'my_visits.route_info.expand_map'.tr,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: context.rsp(11.5),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenTransitMap extends StatelessWidget {
  const _FullScreenTransitMap({required this.stop});
  final RouteStop stop;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.card,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'my_visits.route_info.route_map'.tr,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: context.rsp(16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: BlocBuilder<LocationTrackingCubit, LocationTrackingState>(
        bloc: _RouteCheckInScreenState._resolveBloc<LocationTrackingCubit>(
            context),
        builder: (context, locationState) => TransitMap(
          target: stop,
          currentPosition: locationState.current,
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
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    // PathMetrics.extractPath per dash overflows the stack on web; the
    // polyline walker draws the same border with no lazy Path involved.
    drawDashedRRect(canvas, rrect, paint, dash: 6.0, gap: 4.0);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
