import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Renders up to [maxVisible] small dots — one per scheduled route — arranged
/// in a wrapping grid (default 4 columns) with an overflow count ("+3") appended.
///
/// Used by [CalendarDayCell] and by the compact header's route summary.
class RouteIndicatorDots extends StatelessWidget {
  const RouteIndicatorDots({
    super.key,
    required this.count,
    this.maxVisible = 5,
    this.dotSize = 4,
    this.spacing = 3,
    this.crossSpacing = 3, // Added spacing between wrapped rows
    this.columns = 4, // Added to enforce specific column count
    this.activeColor,
    this.overflowStyle,
  });

  final int count;
  final int maxVisible;
  final double dotSize;
  final double spacing; // Horizontal spacing between dots
  final double crossSpacing; // Vertical spacing between lines
  final int columns; // Number of columns before wrapping
  final Color? activeColor;
  final TextStyle? overflowStyle;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final colors = context.appColors;
    final color = activeColor ?? Theme.of(context).colorScheme.primary;
    final visibleCount = count > maxVisible ? maxVisible : count;
    final overflow = count - maxVisible;

    final double dotSizeW = dotSize.w;
    final double spacingW = spacing.w;

    // Calculate specific width needed to force wrapping after [columns] items.
    // Width = (dot * count) + (spacing * (count - 1))
    final wrapContainerWidth = (dotSizeW * columns) + (spacingW * (columns - 1));

    return Center(
      // We wrap it in a sized box with calculated width to force 
      // the Wrap widget to break lines exactly where we want (column 4).
      child: SizedBox(
        width: wrapContainerWidth,
        child: Wrap(
          // Alignment creates the grid-like appearance
          alignment: WrapAlignment.start,
          // Spacing between items on the main axis (horizontal)
          spacing: spacingW,
          // Spacing between lines on the cross axis (vertical)
          runSpacing: crossSpacing.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < visibleCount; i++)
              Container(
                width: dotSizeW,
                height: dotSizeW,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            if (overflow > 0)
              // Ensure overflow text has a slight gap even when wrapped
              Padding(
                padding: EdgeInsets.only(left: spacingW / 2),
                child: Text(
                  '+$overflow',
                  style: overflowStyle ??
                      TextStyle(
                        color: colors.textSecondary,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        height: 1, // Tight line height for better alignment
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}