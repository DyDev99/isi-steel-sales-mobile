import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/utils/shimmer.dart';

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
    return Column(children: [
      for (var i = 0; i < itemCount; i++) const OrderTileSkeleton()
    ]);
  }
}
