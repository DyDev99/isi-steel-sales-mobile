import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/shimmer.dart';

/// Placeholder for one route tile — mirrors `_RouteTile`'s exact box metrics
/// (14 padding, r16 border, 40×40 leading icon, chevron) so the swap from
/// skeleton → data doesn't shift a single pixel.
class RouteCardSkeleton extends StatelessWidget {
  const RouteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Vibe.stroke)),
        child: Shimmer(
          child: Row(
            children: [
              const SkeletonBox(width: 40, height: 40, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 150, height: 13, radius: 6),
                    SizedBox(height: 8),
                    SkeletonBox(width: 190, height: 11, radius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SkeletonBox(width: 20, height: 20, radius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full loading state for the route dashboard — a "Today" header line plus a
/// few [RouteCardSkeleton]s, laid out with the same padding as the loaded list.
class RouteDashboardSkeleton extends StatelessWidget {
  const RouteDashboardSkeleton({super.key, this.itemCount = 4});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const Shimmer(child: SkeletonBox(width: 64, height: 15, radius: 6)),
        SizedBox(height: 10.h),
        for (var i = 0; i < itemCount; i++) const RouteCardSkeleton(),
      ],
    );
  }
}

/// Placeholder for one inventory/shelf-count row — mirrors `_ShelfRow`'s
/// metrics (r14 border, name + label on the left, two 48×48 steppers + value on
/// the right) so the counter list never jumps when data resolves.
class InventoryLineSkeleton extends StatelessWidget {
  const InventoryLineSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Vibe.stroke)),
      child: Shimmer(
        child: Row(
          children: const [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 14, radius: 6),
                  SizedBox(height: 6),
                  SkeletonBox(width: 60, height: 10, radius: 6),
                ],
              ),
            ),
            SkeletonBox(width: 48, height: 48, radius: 12),
            SizedBox(width: 12),
            SkeletonBox(width: 22, height: 18, radius: 6),
            SizedBox(width: 12),
            SkeletonBox(width: 48, height: 48, radius: 12),
          ],
        ),
      ),
    );
  }
}
