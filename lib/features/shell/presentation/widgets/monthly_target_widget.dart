import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';

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
    // Solid white card (previously a frosted-glass BackdropFilter). Text is
    // dark so it stays legible on the white background.
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(
          color: AppColors.border,
          width: 1.w,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Label left, Values right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName Target',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${achievedAmount.toInt()} of \$${targetAmount.toInt()}',
                style: TextStyle(
                  color: AppColors.textPrimary,
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
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _progress,
                child: Container(
                  height: 22.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      color: AppColors.textInverse,
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
