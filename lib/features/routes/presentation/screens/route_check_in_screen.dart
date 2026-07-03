import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/offline_banner.dart';
import 'package:isi_steel_sales_mobile/core/utils/page_transitions.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/services/proof_photo_service.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/screens/route_stock_count_screen.dart';

/// Step 3 of the guided field flow — Geofence Verification & Proof-of-Presence.
///
/// The fraud-prevention checkpoint: the rep is inside the geofence (green
/// "GPS matched" banner) and must take a stamped shopfront photo before the
/// "Check-in & Continue" CTA unlocks. Check-in writes the `CheckInRecord`
/// (offline-safe) via `ActiveRouteBloc`, then bridges into the existing
/// capture screen — Step 4 (Market-intel stock count) will replace that.
class RouteCheckInScreen extends StatefulWidget {
  const RouteCheckInScreen({super.key});

  @override
  State<RouteCheckInScreen> createState() => _RouteCheckInScreenState();
}

class _RouteCheckInScreenState extends State<RouteCheckInScreen> {
  ProofPhotoResult? _proof;
  bool _capturing = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Load visit data so the proof photo can be attached to this stop.
    final state = context.read<ActiveRouteBloc>().state;
    if (state is ActiveRouteReady && state.hasCurrentStop) {
      context.read<VisitCubit>().load(state.route.stops[state.currentStopIndex].id);
    }
  }

  Future<void> _capture(RouteStop stop) async {
    if (_capturing) return;
    final pos = context.read<LocationTrackingCubit>().state.current;
    setState(() => _capturing = true);
    final result = await sl<ProofPhotoService>().captureStamped(
      latitude: pos?.latitude ?? stop.customer.latitude,
      longitude: pos?.longitude ?? stop.customer.longitude,
    );
    if (!mounted) return;
    setState(() {
      _capturing = false;
      if (result != null) _proof = result;
    });
  }

  void _submit(RouteStop stop) {
    final proof = _proof;
    if (proof == null) return;
    HapticFeedback.mediumImpact();
    context.read<VisitCubit>().addPhoto(VisitPhoto(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          stopId: stop.id,
          url: proof.filePath,
          caption: 'Shopfront proof',
          takenAt: proof.takenAt,
        ));
    setState(() => _submitting = true);
    context.read<ActiveRouteBloc>().add(const CheckInRequested());
  }

  void _goToVisit(BuildContext context) {
    final bloc = context.read<ActiveRouteBloc>();
    final visitCubit = context.read<VisitCubit>();
    Navigator.of(context).push(slideLeftRoute(
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
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: Text('routes.flow.checkin_title'.tr,
            style: const TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: BlocListener<ActiveRouteBloc, ActiveRouteState>(
        listener: (context, state) {
          if (!_submitting || state is! ActiveRouteReady || !state.hasCurrentStop) return;
          final stop = state.route.stops[state.currentStopIndex];
          if (stop.status == VisitStatus.checkedIn) {
            _submitting = false;
            _goToVisit(context);
          } else if (state.blockedCheckInReason != null) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.blockedCheckInReason!)));
          }
        },
        child: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
          builder: (context, state) {
            if (state is! ActiveRouteReady || !state.hasCurrentStop) {
              return Center(child: Text('routes.flow.no_stop'.tr, style: const TextStyle(color: Vibe.muted)));
            }
            final stop = state.route.stops[state.currentStopIndex];
            final canSubmit = state.insideGeofence && _proof != null && !_submitting;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      const OfflineBanner(margin: EdgeInsets.only(bottom: 12)),
                      Text(stop.customer.name,
                          style: const TextStyle(color: Vibe.text, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(stop.customer.address, style: const TextStyle(color: Vibe.muted, fontSize: 12.5)),
                      const SizedBox(height: 16),
                      _GeoBanner(
                        insideGeofence: state.insideGeofence,
                        distanceMeters: state.distanceMeters,
                        blockedReason: state.blockedCheckInReason,
                        warnings: state.checkInWarnings,
                      ),
                      const SizedBox(height: 22),
                      Text('routes.flow.proof_photo'.tr,
                          style: const TextStyle(color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      _CameraDropzone(
                        proof: _proof,
                        capturing: _capturing,
                        onTap: () => _capture(stop),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'routes.flow.checkin_explainer'.tr,
                        style: const TextStyle(color: Vibe.muted, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                _CheckInCta(
                  enabled: canSubmit,
                  submitting: _submitting,
                  hint: !state.insideGeofence
                      ? 'routes.flow.hint_move_inside'.tr
                      : (_proof == null ? 'routes.flow.hint_take_photo'.tr : null),
                  onTap: () => _submit(stop),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GeoBanner extends StatelessWidget {
  const _GeoBanner({
    required this.insideGeofence,
    required this.distanceMeters,
    required this.blockedReason,
    required this.warnings,
  });

  final bool insideGeofence;
  final double distanceMeters;
  final String? blockedReason;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Pill(
          color: insideGeofence ? Vibe.success : Vibe.amber,
          icon: insideGeofence ? Icons.check_circle_rounded : Icons.location_searching_rounded,
          text: insideGeofence
              ? 'routes.flow.geo_matched'.tr
              : 'routes.flow.geo_not_matched'.tr.replaceAll('{dist}', distanceMeters.toStringAsFixed(0)),
        ),
        if (blockedReason != null) ...[
          const SizedBox(height: 8),
          _Pill(color: Vibe.danger, icon: Icons.block_rounded, text: blockedReason!),
        ],
        for (final warning in warnings) ...[
          const SizedBox(height: 8),
          _Pill(color: Vibe.amber, icon: Icons.warning_amber_rounded, text: warning),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _CameraDropzone extends StatelessWidget {
  const _CameraDropzone({required this.proof, required this.capturing, required this.onTap});
  final ProofPhotoResult? proof;
  final bool capturing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: capturing ? null : onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: proof != null ? Vibe.success : Vibe.violet.withValues(alpha: 0.6),
          radius: 16,
        ),
        child: SizedBox(
          height: 190,
          width: double.infinity,
          child: capturing
              ? const Center(child: CircularProgressIndicator(color: Vibe.violet))
              : proof == null
                  ? const _DropzonePlaceholder()
                  : _ProofPreview(path: proof!.filePath),
        ),
      ),
    );
  }
}

class _DropzonePlaceholder extends StatelessWidget {
  const _DropzonePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Vibe.violet.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.photo_camera_rounded, color: Vibe.violet, size: 26),
        ),
        const SizedBox(height: 12),
        Text('routes.flow.take_photo'.tr,
            style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('routes.flow.fit_frame'.tr,
            style: const TextStyle(color: Vibe.muted, fontSize: 11.5)),
      ],
    );
  }
}

class _ProofPreview extends StatelessWidget {
  const _ProofPreview({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(File(path), fit: BoxFit.cover),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 5),
                Text('routes.flow.retake'.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckInCta extends StatelessWidget {
  const _CheckInCta({required this.enabled, required this.submitting, required this.hint, required this.onTap});
  final bool enabled;
  final bool submitting;
  final String? hint;
  final VoidCallback onTap;

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
            if (hint != null) ...[
              Text(hint!, textAlign: TextAlign.center, style: const TextStyle(color: Vibe.muted, fontSize: 11.5)),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: enabled ? onTap : null,
                icon: submitting
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.login_rounded, size: 20),
                label: Text('routes.flow.checkin_continue'.tr,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Vibe.violet,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Vibe.stroke,
                  disabledForegroundColor: Vibe.muted,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a rounded dashed border for the camera dropzone.
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
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}
