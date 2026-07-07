import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/shimmer.dart';

/// Placeholder for one product tile — mirrors `ProductCard`'s horizontal
/// composition (fixed-size image on the left, code/name/meta/price on the
/// right) so the grid doesn't reflow when real products arrive. The grid's
/// fixed `mainAxisExtent` already pins the cell size.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  static const _imageSize = 84.0;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(8),
      child: Shimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: kSkeletonBase, borderRadius: BorderRadius.circular(10)),
              child: const SizedBox(width: _imageSize, height: _imageSize),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: _imageSize,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 40, height: 10, radius: 4),
                        SizedBox(height: 4),
                        SkeletonBox(width: double.infinity, height: 13, radius: 4),
                        SizedBox(height: 4),
                        SkeletonBox(width: 90, height: 11, radius: 4),
                        SizedBox(height: 5),
                        SkeletonBox(width: 70, height: 11, radius: 4),
                      ],
                    ),
                    Row(
                      children: const [
                        SkeletonBox(width: 46, height: 14, radius: 4),
                        Spacer(),
                        SkeletonBox(width: 28, height: 28, radius: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full loading list for the catalog — same 1-column layout, spacing, and
/// fixed cell height as the loaded product list.
class CatalogGridSkeleton extends StatelessWidget {
  const CatalogGridSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}
