import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/shimmer.dart';

/// Skeleton grid shown while products are loading.
class RevenueLoadingView extends StatelessWidget {
  const RevenueLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (_, __) => GlassCard(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(height: 64, width: double.infinity, radius: 10),
              const SizedBox(height: 8),
              const SkeletonBox(height: 12, width: double.infinity),
              const SizedBox(height: 6),
              SkeletonBox(height: 10, width: 80),
              const SizedBox(height: 8),
              SkeletonBox(height: 14, width: 60),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when no products match the current search/category filter.
class RevenueEmptyView extends StatelessWidget {
  const RevenueEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: colors.primaryHover.withValues(alpha: 0.16), // Replaced Vibe.primaryLight
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.inventory_2_outlined,
                  size: 34, color: colors.accentPurple), // Replaced Vibe.violet
            ),
            const SizedBox(height: 16),
            Text(
              'revenue.empty.title'.tr,
              style: TextStyle(
                  color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800), // Replaced Vibe.text
            ),
            const SizedBox(height: 6),
            Text(
              'revenue.empty.subtitle'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13), // Replaced Vibe.muted
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when loading products/categories/discounts/credit summary fails.
class RevenueErrorView extends StatelessWidget {
  const RevenueErrorView(
      {super.key, required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final errorColor = Theme.of(context).colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.12), // Replaced Vibe.danger
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.cloud_off_rounded,
                  size: 34, color: errorColor), // Replaced Vibe.danger
            ),
            const SizedBox(height: 16),
            Text(
              'revenue.error.title'.tr,
              style: TextStyle(
                  color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800), // Replaced Vibe.text
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'common.generic_error'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13), // Replaced Vibe.muted
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPurple, // Replaced Vibe.violet
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('common.retry'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}