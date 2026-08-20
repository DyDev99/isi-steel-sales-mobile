import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

class TodayVisitProgressCard extends StatelessWidget {
  const TodayVisitProgressCard({
    super.key,
    required this.totalVisits,
    required this.visitedCount,
    required this.skippedCount,
  });

  final int totalVisits;
  final int visitedCount;
  final int skippedCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final remainingCount =
        (totalVisits - visitedCount - skippedCount).clamp(0, totalVisits);
    final progressPercent = totalVisits > 0
        ? (((visitedCount + skippedCount) / totalVisits) * 100).round()
        : 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.rw(16)),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's visit progress",
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: context.rsp(14),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rw(10),
                  vertical: context.rh(3),
                ),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(context.rr(12)),
                ),
                child: Text(
                  '$progressPercent%',
                  style: TextStyle(
                    color: colors.success,
                    fontSize: context.rsp(12),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(12)),

          // Multi-segment progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(context.rr(6)),
            child: SizedBox(
              height: context.rh(8),
              child: Row(
                children: [
                  if (visitedCount > 0)
                    Expanded(
                      flex: visitedCount,
                      child:
                          Container(color: colors.success), // Visited - Green
                    ),
                  if (skippedCount > 0)
                    Expanded(
                      flex: skippedCount,
                      child: Container(color: Colors.amber), // Skipped - Yellow
                    ),
                  if (remainingCount > 0)
                    Expanded(
                      flex: remainingCount,
                      child: Container(
                          color: colors.border
                              .withValues(alpha: 0.5)), // Remaining - Grey
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.rh(12)),

          // Legends
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(
                color: colors.success,
                label: '$visitedCount In Plan',
              ),
              _LegendItem(
                color: Colors.amber,
                label: '$skippedCount skipped',
              ),
              _LegendItem(
                color: colors.textSecondary,
                label: '$remainingCount Remaining',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.rr(8),
          height: context.rr(8),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: context.rw(6)),
        Text(
          label,
          style: TextStyle(
            color: context.appColors.textSecondary,
            fontSize: context.rsp(11.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
