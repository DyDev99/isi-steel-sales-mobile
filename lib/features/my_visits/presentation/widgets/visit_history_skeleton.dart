import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/shimmer.dart';

/// Placeholder for one `VisitHistoryCard` — mirrors its exact box metrics
/// (100 map height, 14 padding, r16 border) so the swap from skeleton to
/// data doesn't shift a single pixel.
class VisitHistoryCardSkeleton extends StatelessWidget {
  const VisitHistoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Vibe.stroke)),
        child: Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(height: 100, radius: 0),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 160, height: 13, radius: 6),
                    SizedBox(height: 8),
                    SkeletonBox(width: 200, height: 11, radius: 6),
                    SizedBox(height: 10),
                    SkeletonBox(width: 120, height: 11, radius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full loading state for the My Visits list screen.
class VisitHistoryListSkeleton extends StatelessWidget {
  const VisitHistoryListSkeleton({super.key, this.itemCount = 4});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      physics: const NeverScrollableScrollPhysics(),
      children: [for (var i = 0; i < itemCount; i++) const VisitHistoryCardSkeleton()],
    );
  }
}
