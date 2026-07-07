import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// Surfaces exactly why check-in is (or isn't) allowed right now — blocked
/// reasons in red, non-blocking fraud/VPN warnings in amber. Covers both
/// "fraud" and "VPN" banners from one widget since they share the same
/// `CheckInValidation` source and layout.
class CheckinStatusBanner extends StatelessWidget {
  const CheckinStatusBanner({
    super.key,
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
              ? 'Inside geofence'
              : '${distanceMeters.toStringAsFixed(0)}m from customer — move closer',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
