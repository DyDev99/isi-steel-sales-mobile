import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/animations/shimmer_loading.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Shimmer placeholder mirroring [StopCard]'s metrics so the swap from loading
/// to data doesn't shift layout. Shown while the first GPS fix / stop stream is
/// still resolving (never a blank white screen).
class StopCardSkeleton extends StatelessWidget {
  const StopCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: colors.border),
        ),
        child: Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBox(width: 62.w, height: 40.h, radius: 12.r),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 150.w, height: 14.h, radius: 6.r),
                        SizedBox(height: 8.h),
                        ShimmerBox(width: 190.w, height: 11.h, radius: 6.r),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ShimmerBox(width: 54.w, height: 20.h, radius: 20.r),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  ShimmerBox(width: 90.w, height: 12.h, radius: 6.r),
                  SizedBox(width: 12.w),
                  ShimmerBox(width: 110.w, height: 12.h, radius: 6.r),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full loading state for the Stop Dashboard — summary strip placeholder + a few
/// stop-card skeletons.
class StopDashboardSkeleton extends StatelessWidget {
  const StopDashboardSkeleton({super.key, this.itemCount = 5});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(
          height: 96.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: colors.border),
          ),
          padding: EdgeInsets.all(14.w),
          child: Shimmer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 4; i++)
                  ShimmerBox(width: 48.w, height: 40.h, radius: 8.r),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        for (var i = 0; i < itemCount; i++) const StopCardSkeleton(),
      ],
    );
  }
}
