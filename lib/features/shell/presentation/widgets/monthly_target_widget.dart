import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class MonthlyTargetCard extends StatelessWidget {
  const MonthlyTargetCard({
    super.key,
    required this.targetAmount,
    required this.achievedAmount,
    required this.monthName,
    this.onTap,
  });

  final double targetAmount;
  final String monthName;
  final double achievedAmount;
  final VoidCallback? onTap;

  double get _progress =>
      targetAmount > 0 ? (achievedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  int get _percentage => (_progress * 100).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: appColors.border.withValues(alpha: 0.6),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.25 : 0.04,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header: Month Icon + Title & Percentage Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 16.sp,
                        color: scheme.primary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'shell.monthly_target'.trParams({'month': monthName}),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),

                // Percentage Chip
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: appColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '$_percentage%',
                    style: TextStyle(
                      color: appColors.success,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 2. Large Value Display
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${achievedAmount.toInt()}',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  '/ \$${targetAmount.toInt()}',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // 3. Progress Track
            Stack(
              children: [
                Container(
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: appColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _progress,
                  child: Container(
                    height: 10.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          appColors.success.withValues(alpha: 0.8),
                          appColors.success,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: appColors.success.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}