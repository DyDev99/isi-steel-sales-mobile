import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// The calendar's compact header: today's date and a dot summary of today's stops.
class CalendarToggleButton extends StatelessWidget {
  const CalendarToggleButton({
    super.key,
    required this.expanded,
    required this.todayStopCount,
    required this.onTap,
  });

  final bool expanded;
  final int todayStopCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.rr(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.rw(4), vertical: context.rh(2)),
        child: Row(
          children: [
            Container(
              // FIXED: Converted width, height, and icon size to context.rr
              width: context.rr(40),
              height: context.rr(40),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(context.rr(12)),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.calendar_today_rounded,
                color: scheme.primary,
                size: context.rr(18),
              ),
            ),
            SizedBox(width: context.rw(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(now),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: context.rsp(14),
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                ],
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.iconMuted,
                size: context.rr(24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}