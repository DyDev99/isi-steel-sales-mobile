import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/calendar/calendar_month_view.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/calendar/calendar_toggle_button.dart';

/// Compact-by-default, expandable monthly route calendar for the My Visit
/// Dashboard.
///
/// Collapsed, it's just today's date plus a dot summary of today's routes —
/// a glance, not a whole screen of grid. Tapping it reveals the full month
/// view via [AnimatedSize] so a field rep can still drill into any date to
/// plan ahead, without the calendar eating vertical space by default.
///
/// This widget owns no Bloc/repository access on purpose — [routeCountForDate]
/// is a pure function the caller supplies, so the calendar itself stays
/// reusable and testable independent of how "routes for a day" is computed.
/// See `_MyVisitsDashboardScreenState.routesScheduledOn` in
/// `route_dashboard_screen.dart` for the (currently placeholder — see the
/// comment there) date association it's fed today.
///
/// Replaces the previous `GridCalendarCard`, which rendered the full month
/// grid unconditionally and took ~2x the vertical space this does collapsed.
class RouteCalendarSection extends StatefulWidget {
  const RouteCalendarSection({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.routeCountForDate,
    this.initiallyExpanded = false,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  /// Number of routes scheduled on [date]. Pure and side-effect free — this
  /// widget calls it for every visible cell, so keep it cheap (an O(n) scan
  /// per cell is fine for the route counts this app deals with, but cache
  /// upstream if that ever changes).
  final int Function(DateTime date) routeCountForDate;

  final bool initiallyExpanded;

  @override
  State<RouteCalendarSection> createState() => _RouteCalendarSectionState();
}

class _RouteCalendarSectionState extends State<RouteCalendarSection> {
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CalendarToggleButton(
            expanded: _expanded,
            todayRouteCount: widget.routeCountForDate(today),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: CalendarMonthView(
                      focusedMonth: widget.focusedMonth,
                      selectedDate: widget.selectedDate,
                      onMonthChanged: widget.onMonthChanged,
                      onDateSelected: widget.onDateSelected,
                      routeCountForDate: widget.routeCountForDate,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
