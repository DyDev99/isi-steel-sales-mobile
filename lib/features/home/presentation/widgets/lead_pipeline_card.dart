import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';

/// An upscaled Lead Pipeline card featuring completely externalized string labels.
/// Safely evaluates translation keys within the widget lifecycle to avoid compilation errors.
class LeadPipelineCard extends StatefulWidget {
  const LeadPipelineCard({
    super.key,
    required this.leadCount,
    required this.opportunityCount,
    required this.wonCount,
    this.leadLabel, 
    this.opportunityLabel,
    this.wonLabel,
    this.title, 
    this.icon = Icons.person_add_alt_1_rounded,
    this.onTap,
  });

  final int leadCount;
  final int opportunityCount;
  final int wonCount;
  
  final String? leadLabel;
  final String? opportunityLabel;
  final String? wonLabel;

  final String? title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<LeadPipelineCard> createState() => _LeadPipelineCardState();
}

class _LeadPipelineCardState extends State<LeadPipelineCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sweepAnimation;

  int get _total => widget.leadCount + widget.opportunityCount + widget.wonCount;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _sweepAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Fixed: Removed () since .tr is a getter property ---
    final resolvedLeadLabel = widget.leadLabel ?? 'home.quick_access.leads'.tr;
    final resolvedOpportunityLabel = widget.opportunityLabel ?? 'home.quick_access.opportunities'.tr;
    final resolvedWonLabel = widget.wonLabel ?? 'home.quick_access.won_deals'.tr;
    final resolvedTitle = widget.title ?? 'home.quick_access.leads'.tr;

    // Pipeline sequence using the resolved translation strings
    final segments = <_Segment>[
      _Segment(resolvedWonLabel, widget.wonCount, Vibe.success),
      _Segment(resolvedOpportunityLabel, widget.opportunityCount, Vibe.amber),
      _Segment(resolvedLeadLabel, widget.leadCount, Vibe.violet),
    ];

    return GlassCard(
      onTap: widget.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
        child: SizedBox(
          width: 260.w, 
          height: 135.h, 
          child: Stack(
            children: [
              // --- Dynamic Canvas Layer ---
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _sweepAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _OrbitingPipelinePainter(
                        segments: segments,
                        total: _total,
                        strokeWidth: 10.w, 
                        trackColor: Vibe.surfaceStrong,
                        animationValue: _sweepAnimation.value,
                      ),
                    );
                  },
                ),
              ),

              // --- Centered Inner Circle Target ---
              Center(
                child: Container(
                  width: 54.w, 
                  height: 54.w, 
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Vibe.violet.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: Vibe.violet, size: 18.sp), 
                      SizedBox(height: 2.h),
                      Text(
                        resolvedTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Vibe.text,
                          fontSize: 10.sp, 
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment {
  const _Segment(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;
}

class _OrbitingPipelinePainter extends CustomPainter {
  _OrbitingPipelinePainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
    required this.trackColor,
    required this.animationValue,
  });

  final List<_Segment> segments;
  final int total;
  final double strokeWidth;
  final Color trackColor;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final donutDiameter = 84.w; 
    final radius = (donutDiameter - strokeWidth) / 2;
    final outerRingEdge = radius + (strokeWidth / 2);

    // 1. Background Ring Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0) return;

    var startAngle = -math.pi / 2; 

    for (final s in segments) {
      if (s.count <= 0) continue;

      final sweep = (s.count / total) * 2 * math.pi;
      final animatedSweep = sweep * animationValue;

      // Draw active data color arc
      final segmentPaint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        animatedSweep,
        false,
        segmentPaint,
      );

      // 2. Position Vector Calculation based on Segment Midpoints
      final midAngle = startAngle + (sweep / 2);
      final cosA = math.cos(midAngle);
      final sinA = math.sin(midAngle);

      final pStart = center + Offset(cosA, sinA) * (outerRingEdge + 3.w);
      final arrowLength = 12.w; 
      final pEnd = center + Offset(cosA, sinA) * (outerRingEdge + 3.w + arrowLength);

      // Uses the safely resolved runtime translation strings
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${s.label}: ${s.count}',
          style: TextStyle(
            color: s.color,
            fontSize: 12.5.sp, 
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Spatial tracking adjustments depending on position hemisphere
      double textX = pEnd.dx;
      double textY = pEnd.dy;

      if (cosA > 0.25) {
        textX = pEnd.dx + 5.w;
        textY = pEnd.dy - textPainter.height / 2;
      } else if (cosA < -0.25) {
        textX = pEnd.dx - textPainter.width - 5.w;
        textY = pEnd.dy - textPainter.height / 2;
      } else {
        textX = pEnd.dx - textPainter.width / 2;
        textY = sinA < 0 ? (pEnd.dy - textPainter.height - 4.h) : (pEnd.dy + 4.h);
      }

      // 3. Render Tracking Arrows and Labels
      final fadePaint = Paint()
        ..color = s.color.withValues(alpha: animationValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3.w 
        ..strokeCap = StrokeCap.round;

      final pCtrl = Offset(
        pStart.dx + (pEnd.dx - pStart.dx) * 0.3,
        pStart.dy + (pEnd.dy - pStart.dy) * 0.7,
      );
      final arrowPath = Path()
        ..moveTo(pStart.dx, pStart.dy)
        ..quadraticBezierTo(pCtrl.dx, pCtrl.dy, pEnd.dx, pEnd.dy);
      canvas.drawPath(arrowPath, fadePaint);

      final double arrowSize = 4.w;
      final headAngle = math.atan2(sinA, cosA);
      final wing1 = pEnd - Offset(math.cos(headAngle - 0.35), math.sin(headAngle - 0.35)) * arrowSize;
      final wing2 = pEnd - Offset(math.cos(headAngle + 0.35), math.sin(headAngle + 0.35)) * arrowSize;
      canvas.drawLine(pEnd, wing1, fadePaint);
      canvas.drawLine(pEnd, wing2, fadePaint);

      textPainter.paint(canvas, Offset(textX, textY));

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitingPipelinePainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.total != total ||
        oldDelegate.animationValue != animationValue;
  }
}