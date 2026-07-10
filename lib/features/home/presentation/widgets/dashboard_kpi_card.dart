import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// One slice of a [DashboardKpiCard]'s distribution bar + legend.
class KpiSegment {
  const KpiSegment(
      {required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;
}

/// Small colored status pill shown in the card header, e.g. "3 missed".
/// Reserve this for things that genuinely need attention — it competes
/// with the chevron for eye space, so an empty/neutral state should pass
/// `null` rather than showing a badge with nothing to say.
class KpiBadge {
  const KpiBadge({required this.label, required this.color});
  final String label;
  final Color color;
}

/// Shared building block for every dashboard KPI summary card.
///
/// Design intent:
/// - The headline number is the first and largest thing on the card, so the
///   card can be read correctly in under a second by anyone, regardless of
///   dashboard/chart familiarity.
/// - Distribution is shown as a simple proportional bar rather than a pie/arc
///   — no angle-reading required, and it degrades gracefully at small sizes.
/// - "View details" is always spelled out, so tappability is never something
///   a person has to infer from a chevron alone.
/// - Motion is a single restrained fade/grow-in (easeOutCubic), not a bouncy
///   spring — calm enough to feel trustworthy on a sales dashboard, still
///   smooth enough to feel current.
class DashboardKpiCard extends StatefulWidget {
  const DashboardKpiCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.headline,
    required this.headlineCaption,
    required this.segments,
    this.badge,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String headline;
  final String headlineCaption;
  final List<KpiSegment> segments;
  final KpiBadge? badge;
  final VoidCallback? onTap;

  @override
  State<DashboardKpiCard> createState() => _DashboardKpiCardState();
}

class _DashboardKpiCardState extends State<DashboardKpiCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _reveal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _reveal = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DashboardKpiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    var changed = oldWidget.headline != widget.headline ||
        oldWidget.segments.length != widget.segments.length;
    if (!changed) {
      for (var i = 0; i < widget.segments.length; i++) {
        if (oldWidget.segments[i].value != widget.segments[i].value) {
          changed = true;
          break;
        }
      }
    }
    if (changed) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _total => widget.segments.fold(0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    final visibleSegments = widget.segments.where((s) => s.value > 0).toList();

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Vibe.bgSoft,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Vibe.stroke, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon chip · title · optional status badge · chevron
            Row(
              children: [
                Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 14.w, color: widget.iconColor),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Vibe.muted,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (widget.badge != null) ...[
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: widget.badge!.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      widget.badge!.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: widget.badge!.color,
                          fontSize: 6.6.sp,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: 6.w),
                ],
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12.w, color: Vibe.muted.withValues(alpha: 0.5)),
              ],
            ),
            SizedBox(height: 10.h),

            // Headline — the one number a person needs, read first and biggest.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                widget.headline,
                style: TextStyle(
                    color: Vibe.text,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.0),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              widget.headlineCaption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Vibe.muted,
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10.h),

            // Distribution bar — grows in from the left. Easier to scan at a
            // glance than matching up pie-wedge angles, and reads the same
            // whether or not you're used to looking at charts.
            AnimatedBuilder(
              animation: _reveal,
              builder: (context, child) => ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _reveal.value,
                  child: child,
                ),
              ),
              child: SizedBox(
                height: 7.h,
                width: double.infinity,
                child: _total == 0
                    ? Container(color: Vibe.stroke.withValues(alpha: 0.4))
                    : Row(
                        children: visibleSegments
                            .map((s) => Expanded(
                                flex: s.value,
                                child: Container(color: s.color)))
                            .toList(),
                      ),
              ),
            ),
            SizedBox(height: 10.h),

            // Legend — one line per segment: dot, label, value. No separate
            // count row underneath, so it stays compact in a 2-column grid.
            Wrap(
              spacing: 10.w,
              runSpacing: 4.h,
              children: visibleSegments.map((s) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration:
                          BoxDecoration(color: s.color, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 4.w),
                    Text('${s.label} ',
                        style: TextStyle(
                            color: Vibe.muted,
                            fontSize: 6.8.sp,
                            fontWeight: FontWeight.w500)),
                    Text('${s.value}',
                        style: TextStyle(
                            color: Vibe.text,
                            fontSize: 6.8.sp,
                            fontWeight: FontWeight.w700)),
                  ],
                );
              }).toList(),
            ),

            const Spacer(),
            SizedBox(height: 8.h),

            // Explicit affordance — spelled out, never left to be inferred.
            Row(
              children: [
                Text(
                  'common.view_details'.tr,
                  style: TextStyle(
                      color: widget.iconColor,
                      fontSize: 7.2.sp,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 3.w),
                Icon(Icons.arrow_right_alt_rounded,
                    size: 12.w, color: widget.iconColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
