import 'package:flutter/material.dart';

import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/calendar/calendar_month_view.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/calendar/calendar_toggle_button.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// Compact-by-default, expandable monthly stop calendar for the My Visit Dashboard.
class StopCalendarSection extends StatefulWidget {
  const StopCalendarSection({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.stopCountForDate,
    this.initiallyExpanded = false,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  /// Number of stops scheduled on [date].
  final int Function(DateTime date) stopCountForDate;

  final bool initiallyExpanded;

  @override
  State<StopCalendarSection> createState() => _StopCalendarSectionState();
}

class _StopCalendarSectionState extends State<StopCalendarSection> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final today = DateTime.now();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(14),
        vertical: context.rh(14),
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(18)),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CalendarToggleButton(
            expanded: _expanded,
            todayStopCount: widget.stopCountForDate(today),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      key: const ValueKey('calendar-expanded'),
                      padding: EdgeInsets.only(top: context.rh(16)),
                      child: CalendarMonthView(
                        focusedMonth: widget.focusedMonth,
                        selectedDate: widget.selectedDate,
                        onMonthChanged: widget.onMonthChanged,
                        onDateSelected: widget.onDateSelected,
                        stopCountForDate: widget.stopCountForDate,
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('calendar-collapsed'),
                      width: double.infinity,
                      height: 0,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}