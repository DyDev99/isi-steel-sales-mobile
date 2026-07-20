import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/shimmer.dart';

/// Placeholder for one route tile — mirrors `RegionCard` / `_RouteTile`'s exact
/// metrics so the swap from skeleton -> data doesn't shift layout.
class RouteCardSkeleton extends StatelessWidget {
  const RouteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: context.appColors.border),
        ),
        child: Shimmer(
          child: Row(
            children: [
              SkeletonBox(width: 40.w, height: 40.w, radius: 12.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140.w, height: 13.h, radius: 6.r),
                    SizedBox(height: 8.h),
                    SkeletonBox(width: 180.w, height: 11.h, radius: 6.r),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              SkeletonBox(width: 20.w, height: 20.w, radius: 6.r),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full loading state for the route dashboard — mirrors the layout of
/// [MyVisitsDashboardScreen] (Calendar section + Activity History ribbon +
/// Day Header + Route Cards) so the view transition is seamless.
class RouteDashboardSkeleton extends StatelessWidget {
  const RouteDashboardSkeleton({super.key, this.itemCount = 3});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 1. Calendar section skeleton
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: context.appColors.border),
          ),
          child: Shimmer(
            child: Row(
              children: [
                SkeletonBox(width: 40.w, height: 40.w, radius: 12.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 160.w, height: 14.h, radius: 6.r),
                      SizedBox(height: 6.h),
                      SkeletonBox(width: 100.w, height: 10.h, radius: 6.r),
                    ],
                  ),
                ),
                SkeletonBox(width: 20.w, height: 20.w, radius: 6.r),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // 2. Activity history ribbon skeleton
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: context.appColors.border),
          ),
          child: Shimmer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 130.w, height: 13.h, radius: 6.r),
                SkeletonBox(width: 14.w, height: 14.w, radius: 4.r),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // 3. Day header skeleton
        Shimmer(
          child: SkeletonBox(width: 80.w, height: 14.h, radius: 6.r),
        ),
        SizedBox(height: 10.h),

        // 4. Route card skeletons
        for (var i = 0; i < itemCount; i++) const RouteCardSkeleton(),
      ],
    );
  }
}

/// Placeholder for one inventory/shelf-count row — mirrors `_ShelfRow`'s
/// metrics so the counter list never jumps when data resolves.
class InventoryLineSkeleton extends StatelessWidget {
  const InventoryLineSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.appColors.border),
      ),
      child: Shimmer(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120.w, height: 14.h, radius: 6.r),
                  SizedBox(height: 6.h),
                  SkeletonBox(width: 60.w, height: 10.h, radius: 6.r),
                ],
              ),
            ),
            SkeletonBox(width: 48.w, height: 48.w, radius: 12.r),
            SizedBox(width: 12.w),
            SkeletonBox(width: 22.w, height: 18.h, radius: 6.r),
            SizedBox(width: 12.w),
            SkeletonBox(width: 48.w, height: 48.w, radius: 12.r),
          ],
        ),
      ),
    );
  }
}