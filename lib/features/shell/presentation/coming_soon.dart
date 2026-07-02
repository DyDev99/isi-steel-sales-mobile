import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/ui/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/ui/aurora_background.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, required this.emoji});
  final String title;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(title,
                      style: const TextStyle(
                          color: Vibe.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('Coming soon',
                      style: TextStyle(color: Vibe.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
