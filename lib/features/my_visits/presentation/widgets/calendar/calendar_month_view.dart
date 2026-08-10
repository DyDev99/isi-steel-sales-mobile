import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'calendar_day_cell.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// Prev/next chevrons around the "Month yyyy" label.
class MonthNavigation extends StatelessWidget {
  const MonthNavigation({
    super.key,
    required this.focusedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime focusedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
        Text(
          DateFormat.yMMMM().format(focusedMonth),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: context.rsp(16),
            fontWeight: FontWeight.w800,
          ),
        ),
        _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.rr(20)),
      child: Padding(
        padding: EdgeInsets.all(context.rr(6)),
        child: Icon(
          icon,
          color: colors.iconMuted,
          size: context.rr(22),
        ),
      ),
    );
  }
}

class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.stopCountForDate,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final int Function(DateTime date) stopCountForDate;

  static const _swipeVelocityThreshold = 200.0;

  void _goToMonth(int offset) {
    onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + offset, 1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();

    final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final leadingOffset = firstOfMonth.weekday - 1;
    final gridStart = firstOfMonth.subtract(Duration(days: leadingOffset));

    final weekdayLabels = List.generate(7, (i) {
      final d = gridStart.add(Duration(days: i));
      final label = DateFormat.E().format(d);
      return label.length > 2 ? label.substring(0, 2) : label;
    });

    // Adjusted childAspectRatio by / 1.15 to grant 15% extra height per cell
    final dynamicChildAspectRatio = context.responsive<double>(
      compact: 0.71,
      medium: 1.30,
      expanded: 1.74,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthNavigation(
          focusedMonth: focusedMonth,
          onPrevious: () => _goToMonth(-1),
          onNext: () => _goToMonth(1),
        ),
        SizedBox(height: context.rh(16)),
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: context.rsp(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: context.rh(8)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -_swipeVelocityThreshold) {
              _goToMonth(1);
            } else if (velocity > _swipeVelocityThreshold) {
              _goToMonth(-1);
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: GridView.builder(
              key: ValueKey('${focusedMonth.year}-${focusedMonth.month}'),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: context.rh(4),
                crossAxisSpacing: context.rw(2),
                childAspectRatio: dynamicChildAspectRatio,
              ),
              itemBuilder: (context, index) {
                final date = gridStart.add(Duration(days: index));
                final isCurrentMonth = date.month == focusedMonth.month;
                final isToday = DateUtils.isSameDay(date, now);
                final isSelected = DateUtils.isSameDay(date, selectedDate);
                return CalendarDayCell(
                  date: date,
                  isCurrentMonth: isCurrentMonth,
                  isToday: isToday,
                  isSelected: isSelected,
                  stopCount: isCurrentMonth ? stopCountForDate(date) : 0,
                  onTap: () => onDateSelected(date),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}