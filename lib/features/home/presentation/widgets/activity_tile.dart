import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/domain/dashboard_summary.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.item});
  final ActivityItem item;

  ({IconData icon, Color color}) get _style => switch (item.kind) {
        ActivityKind.lead => (
            icon: Icons.person_add_alt_1_rounded,
            color: Vibe.violet
          ),
        ActivityKind.order => (
            icon: Icons.receipt_long_rounded,
            color: Vibe.mint
          ),
        ActivityKind.opportunity => (
            icon: Icons.trending_up_rounded,
            color: Vibe.amber
          ),
        ActivityKind.payment => (
            icon: Icons.payments_rounded,
            color: Vibe.success
          ),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.icon, color: s.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Vibe.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Vibe.muted, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(item.timeAgo,
              style: const TextStyle(color: Vibe.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
