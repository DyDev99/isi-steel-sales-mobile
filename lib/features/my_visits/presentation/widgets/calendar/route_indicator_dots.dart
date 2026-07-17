import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Renders up to [maxVisible] small dots — one per scheduled route — with an
/// overflow count ("+3") appended instead of ever wrapping or shrinking the
/// dots to fit. Font size and dot size are fixed by design (per the calendar
/// spec: never shrink to avoid overflow, just cap and show a remainder).
///
/// Used by [CalendarDayCell] (max 5 per the grid-cell design) and by the
/// compact header's "today's routes" strip (max 8).
class RouteIndicatorDots extends StatelessWidget {
  const RouteIndicatorDots({
    super.key,
    required this.count,
    this.maxVisible = 5,
    this.dotSize = 4,
    this.spacing = 3,
    this.activeColor,
    this.overflowStyle,
  });

  final int count;
  final int maxVisible;
  final double dotSize;
  final double spacing;
  final Color? activeColor;
  final TextStyle? overflowStyle;

  @override
  Widget build(BuildContext context) {
    // Reserve the row's height even with zero routes so cells/rows around it
    // don't jump vertically as counts change.
    if (count <= 0) return SizedBox(height: dotSize.w);

    final colors = context.appColors;
    final color = activeColor ?? Theme.of(context).colorScheme.primary;
    final visibleCount = count > maxVisible ? maxVisible : count;
    final overflow = count - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visibleCount; i++) ...[
          if (i != 0) SizedBox(width: spacing.w),
          Container(
            width: dotSize.w,
            height: dotSize.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
        if (overflow > 0) ...[
          SizedBox(width: spacing.w),
          Text(
            '+$overflow',
            style: overflowStyle ??
                TextStyle(
                  color: colors.textSecondary,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ],
    );
  }
}
