import 'package:flutter/material.dart';

import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// Renders up to [maxVisible] small dots — one per scheduled stop — arranged
/// in a wrapping grid (default 4 columns) with an overflow count ("+3") appended.
///
/// Used by [CalendarDayCell] and by the compact header's stop summary.
class StopIndicatorDots extends StatelessWidget {
  const StopIndicatorDots({
    super.key,
    required this.count,
    this.maxVisible = 5,
    this.dotSize = 4,
    this.spacing = 3,
    this.crossSpacing = 3, // Spacing between wrapped rows
    this.columns = 4, // Number of columns before wrapping
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

    // FIXED: Replaced flutter_screenutil extensions with responsive_sizing context methods
    final double dotSizePx = context.rr(dotSize);
    final double spacingPx = context.rw(spacing);

    // Calculate specific width needed to force wrapping after [columns] items.
    final wrapContainerWidth =
        (dotSizePx * columns) + (spacingPx * (columns - 1));

    return Center(
      child: SizedBox(
        width: wrapContainerWidth,
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: spacingPx,
          runSpacing: context.rh(crossSpacing),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < visibleCount; i++)
              Container(
                width: dotSizePx,
                height: dotSizePx,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            if (overflow > 0)
              Padding(
                padding: EdgeInsets.only(left: spacingPx / 2),
                child: Text(
                  '+$overflow',
                  style: overflowStyle ??
                      TextStyle(
                        color: colors.textSecondary,
                        fontSize: context.rsp(9),
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}