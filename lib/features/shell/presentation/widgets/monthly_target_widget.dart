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
  });

  final double targetAmount;
  final String monthName;
  final double achievedAmount;

  double get _progress => (achievedAmount / targetAmount).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: appColors.border,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Label left, Values right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'shell.monthly_target'.trParams({'month': monthName}),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'shell.target_progress'.trParams({
                  'achieved': '\$${achievedAmount.toInt()}',
                  'target': '\$${targetAmount.toInt()}',
                }),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Progress Bar
          Stack(
            children: [
              Container(
                height: 22.h,
                decoration: BoxDecoration(
                  color: appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _progress,
                child: Container(
                  height: 22.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: appColors.success,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
