import 'package:flutter/material.dart';

import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/calendar/stops_indicator_dots.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// One cell in [CalendarMonthView]'s grid: a date number with wrapping stop
/// dots (up to 4 columns) centered directly beneath it.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.stopCount,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final int stopCount;
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
          SizedBox(height: context.rh(4)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            // FIXED: Used context.rr for uniform radial scaling on circular container
            width: context.rr(30),
            height: context.rr(30),
            decoration:
                BoxDecoration(color: circleColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: numberColor,
                fontSize: context.rsp(14),
                fontWeight: numberWeight,
              ),
            ),
          ),
          SizedBox(height: context.rh(4)),
          isCurrentMonth
              ? StopIndicatorDots(
                  count: stopCount,
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