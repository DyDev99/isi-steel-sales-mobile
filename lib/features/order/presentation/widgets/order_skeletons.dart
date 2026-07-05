import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/shimmer.dart';

/// Placeholder for one product tile — mirrors `ProductCard`'s composition
/// (1.3-ratio image, code line, two-line name, meta, price row) so the grid
/// doesn't reflow when real products arrive. The grid's fixed
/// `childAspectRatio` already pins the cell size.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: DecoratedBox(
                decoration: BoxDecoration(color: kSkeletonBase, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            const SkeletonBox(width: 44, height: 10, radius: 4),
            const SizedBox(height: 6),
            const SkeletonBox(width: double.infinity, height: 12, radius: 4),
            const SizedBox(height: 4),
            const SkeletonBox(width: 90, height: 11, radius: 4),
            const SizedBox(height: 8),
            const SkeletonBox(width: 70, height: 11, radius: 4),
            const Spacer(),
            Row(
              children: const [
                SkeletonBox(width: 54, height: 14, radius: 4),
                Spacer(),
                SkeletonBox(width: 28, height: 28, radius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for one pending-order row — mirrors `_OrderTile` (items + date
/// on the left, status pill + total on the right).
class OrderTileSkeleton extends StatelessWidget {
  const OrderTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Shimmer(
          child: Row(
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 60, height: 13, radius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 84, height: 11, radius: 4),
                  ],
                ),
              ),
              SkeletonBox(width: 74, height: 18, radius: 20),
              SizedBox(width: 10),
              SkeletonBox(width: 52, height: 14, radius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading state for the Orders "Recent Orders" list.
class PendingOrdersSkeleton extends StatelessWidget {
  const PendingOrdersSkeleton({super.key, this.itemCount = 3});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(children: [for (var i = 0; i < itemCount; i++) const OrderTileSkeleton()]);
  }
}

/// Full loading grid for the catalog — same 2-column layout, spacing, and
/// aspect ratio as the loaded product grid.
class CatalogGridSkeleton extends StatelessWidget {
  const CatalogGridSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}
