import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'route_indicator_dots.dart';

/// The calendar's compact, always-visible header: today's weekday + date and
/// a dot summary of today's routes, plus the chevron that expands the full
/// month view.
///
/// Deliberately always shows *today* rather than whichever date is selected
/// in the expanded grid — per the design brief, this is a quick "what's on
/// today" glance. The user's selection elsewhere already drives the existing
/// day-header/route list below the calendar on the dashboard screen.
class CalendarToggleButton extends StatelessWidget {
  const CalendarToggleButton({
    super.key,
    required this.expanded,
    required this.todayRouteCount,
    required this.onTap,
  });

  final bool expanded;
  final int todayRouteCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.calendar_today_rounded,
                  color: scheme.primary, size: 18.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(now),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'my_visits.calendar.todays_routes'.tr,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      RouteIndicatorDots(
                        count: todayRouteCount,
                        maxVisible: 8,
                        dotSize: 5,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: colors.iconMuted, size: 24.w),
            ),
          ],
        ),
      ),
    );
  }
}
