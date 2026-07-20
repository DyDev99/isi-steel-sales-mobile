import 'package:flutter/material.dart';

class PromotionBadge extends StatelessWidget {
  const PromotionBadge({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_rounded, size: 11, color: scheme.error),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  color: scheme.error,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
