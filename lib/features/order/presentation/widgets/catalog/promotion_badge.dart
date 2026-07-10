import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

class PromotionBadge extends StatelessWidget {
  const PromotionBadge({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Vibe.danger.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer_rounded, size: 11, color: Vibe.danger),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  color: Vibe.danger,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
