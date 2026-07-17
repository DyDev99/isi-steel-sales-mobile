import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'calendar_day_cell.dart';

/// Prev/next chevrons around the "Month yyyy" label. Uses the unqualified
/// `DateFormat.yMMMM()` constructor (no explicit locale string) so it follows
/// whatever `Intl.defaultLocale` the app already sets on locale switch — same
/// convention the rest of the app's `DateFormat` calls rely on.
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
            fontSize: 16.sp,
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
      borderRadius: BorderRadius.circular(20.r),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Icon(icon, color: colors.iconMuted, size: 22.w),
      ),
    );
  }
}

/// The real monthly grid: weekday labels (Monday-first) plus a fixed 6-row
/// (42-cell) day grid that always starts from the Monday on/before the 1st,
/// so leading and trailing days from adjacent months fill in faded instead
/// of leaving a blank gap at the start of the month.
///
/// A horizontal drag changes the month (swipe navigation, per the spec);
/// [AnimatedSwitcher] keyed by month gives the change a soft fade/slide
/// instead of an instant cut, without the bookkeeping a full `PageView`
/// carousel would add.
class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.routeCountForDate,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final int Function(DateTime date) routeCountForDate;

  static const _swipeVelocityThreshold = 200.0;

  void _goToMonth(int offset) {
    onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + offset, 1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();

    final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    // DateTime.weekday is 1 (Mon) .. 7 (Sun); this gives a Monday-first offset.
    final leadingOffset = firstOfMonth.weekday - 1;
    final gridStart = firstOfMonth.subtract(Duration(days: leadingOffset));

    final weekdayLabels = List.generate(7, (i) {
      final d = gridStart.add(Duration(days: i));
      // Two-letter abbreviation. For locales where that reads oddly, this is
      // a fine default to refine later — it's cosmetic only.
      final label = DateFormat.E().format(d);
      return label.length > 2 ? label.substring(0, 2) : label;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthNavigation(
          focusedMonth: focusedMonth,
          onPrevious: () => _goToMonth(-1),
          onNext: () => _goToMonth(1),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
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
                mainAxisSpacing: 4.h,
                crossAxisSpacing: 2.w,
                childAspectRatio: 0.78,
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
                  routeCount: isCurrentMonth ? routeCountForDate(date) : 0,
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
