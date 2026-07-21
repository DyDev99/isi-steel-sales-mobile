import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'route_indicator_dots.dart';

/// One cell in [CalendarMonthView]'s grid: a date number with wrapping route
/// dots (up to 4 columns) centered directly beneath it.
///
/// - **Today** always gets a filled primary circle + bold white text — this
///   holds even if today also happens to be the selected date.
/// - A **selected date that isn't today** gets a lighter tinted circle, so
///   the two states never look identical.
/// - Leading/trailing days from adjacent months render faded and disabled
///   (tapping does nothing) rather than blank, matching how Google/Apple
///   Calendar fill the grid instead of leaving the start of the month empty.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.routeCount,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final int routeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    Color circleColor = Colors.transparent;
    Color numberColor;
    FontWeight numberWeight = FontWeight.w500;

    if (isToday) {
      circleColor = scheme.primary;
      numberColor = scheme.onPrimary;
      numberWeight = FontWeight.bold;
    } else if (isSelected) {
      circleColor = scheme.primary.withValues(alpha: 0.14);
      numberColor = scheme.primary;
      numberWeight = FontWeight.bold;
    } else if (!isCurrentMonth) {
      numberColor = colors.textHint;
    } else {
      numberColor = colors.textPrimary;
    }

    return GestureDetector(
      onTap: isCurrentMonth ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 4.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 30.w,
            height: 30.w,
            decoration:
                BoxDecoration(color: circleColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: numberColor,
                fontSize: 14.sp,
                fontWeight: numberWeight,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          // Adjacent-month days never show route dots — those routes belong
          // to a different focused month and would be misleading here.
          isCurrentMonth
              ? RouteIndicatorDots(
                  count: routeCount,
                  maxVisible: 8,
                  columns: 4,
                  activeColor: isToday ? scheme.primary : colors.iconMuted,
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
