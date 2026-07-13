import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// Ensure this matches your project's import path for the theme extensions
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class GridCalendarCard extends StatelessWidget {
  const GridCalendarCard({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    // Read the app's custom theme tokens for active brightness (e.g., card, textPrimary, cardShadow)[cite: 2]
    final colors = context.appColors;
    
    // Read Material standard tokens (e.g., primary, onPrimary)[cite: 4]
    final colorScheme = Theme.of(context).colorScheme;

    final daysInMonth = DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final firstDayOffset = firstDay.weekday == 7 ? 0 : firstDay.weekday;
    
    final weekdayLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    const int totalGridSlots = 42; 

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: colors.card, // Responsive card color[cite: 2]
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: colors.cardShadow, // Soft elevation resolved for active theme[cite: 2]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: colors.iconMuted, size: 28.w), // Theme-aware muted icon[cite: 2]
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month - 1, 1));
                },
              ),
              SizedBox(width: 24.w),
              Text(
                DateFormat('MMMM yyyy').format(focusedMonth),
                style: TextStyle(
                  color: colors.textPrimary, // Theme-aware primary text[cite: 2]
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 24.w),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: colors.iconMuted, size: 28.w), // Theme-aware muted icon[cite: 2]
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + 1, 1));
                },
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Weekday Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayLabels
                .map((label) => Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: colors.textSecondary, // Secondary text for headers[cite: 2]
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 16.h),
          
          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalGridSlots,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 8.w,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink(); 
              }

              final dayNumber = index - firstDayOffset + 1;
              final isCurrentMonth = dayNumber <= daysInMonth;

              // Next Month trailing days
              if (!isCurrentMonth) {
                final nextMonthDay = dayNumber - daysInMonth;
                return Center(
                  child: Text(
                    '$nextMonthDay',
                    style: TextStyle(
                      color: colors.textHint, // Faded hint text for next month's days[cite: 2]
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              // Current Month Days
              final dayDate = DateTime(focusedMonth.year, focusedMonth.month, dayNumber);
              final bool isSelected = dayDate.year == selectedDate.year &&
                  dayDate.month == selectedDate.month &&
                  dayDate.day == selectedDate.day;

              // Dummy logic for event days
              final bool hasEvent = dayNumber == 24 || dayNumber == 27;

              return GestureDetector(
                onTap: () => onDateSelected(dayDate),
                child: Container(
                  decoration: BoxDecoration(
                    // Selected applies scheme primary, event applies soft background[cite: 2, 4]
                    color: isSelected
                        ? colorScheme.primary
                        : hasEvent
                            ? colors.surfaceSoft
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isSelected ? colorScheme.onPrimary : colors.textPrimary, // Inverse text if selected[cite: 4]
                          fontSize: 14.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      // Notification dot for events
                      if (hasEvent && !isSelected)
                        Positioned(
                          top: 4.h,
                          right: 4.w,
                          child: Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(
                              color: colorScheme.error, // Reddish error hue for notification dots[cite: 4]
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}