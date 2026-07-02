import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/ui/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/ui/glass_card.dart';

class TargetCard extends StatelessWidget {
  const TargetCard({super.key, required this.progress});
  final double progress; // 0..1

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly target',
                  style: TextStyle(
                      color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w700)),
              Text('$pct%',
                  style: const TextStyle(
                      color: Vibe.mint, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 12, color: Vibe.surfaceStrong),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0, 1),
                  child: Container(
                    height: 12,
                    decoration: const BoxDecoration(gradient: Vibe.coolGradient),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Keep it up — you\'re ahead of pace 🔥',
              style: TextStyle(color: Vibe.muted, fontSize: 12.5)),
        ],
      ),
    );
  }
}
