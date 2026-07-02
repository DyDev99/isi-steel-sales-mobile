import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/ui/app_vibe.dart';

/// Dark canvas + soft radial glow blobs. Cheap (no blur filter).
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Vibe.bg,
      child: Stack(
        children: [
          _Glow(color: Vibe.violet, top: -90, left: -60, size: 300),
          _Glow(color: Vibe.pink, top: 140, right: -100, size: 260),
          _Glow(color: Vibe.mint, bottom: -110, left: -50, size: 320),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.color,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final Color color;
  final double size;
  final double? top, left, right, bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
