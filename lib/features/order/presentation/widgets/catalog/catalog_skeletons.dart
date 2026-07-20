import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/shimmer.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  static const _imageSize = 84.0;

  @override
  Widget build(BuildContext context) {
    final baseColor = context.appColors.border.withValues(alpha: 0.4);

    return GlassCard(
      padding: const EdgeInsets.all(8),
      child: Shimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                  color: baseColor, borderRadius: BorderRadius.circular(10)),
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
                      children: [
                        SkeletonBox(
                            width: 40, height: 10, radius: 4, color: baseColor),
                        const SizedBox(height: 4),
                        SkeletonBox(
                            width: double.infinity,
                            height: 13,
                            radius: 4,
                            color: baseColor),
                        const SizedBox(height: 4),
                        SkeletonBox(
                            width: 90, height: 11, radius: 4, color: baseColor),
                        const SizedBox(height: 3),
                        SkeletonBox(
                            width: 70, height: 11, radius: 4, color: baseColor),
                      ],
                    ),
                    Row(
                      children: [
                        SkeletonBox(
                            width: 46, height: 14, radius: 4, color: baseColor),
                        const Spacer(),
                        SkeletonBox(
                            width: 28, height: 28, radius: 8, color: baseColor),
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

class CatalogGridSkeleton extends StatelessWidget {
  const CatalogGridSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}
