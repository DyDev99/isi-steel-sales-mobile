import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';

/// Fills the screen with the dark canvas and three soft gradient glows.
/// Uses radial gradients that fade to transparent (not BackdropFilter),
/// so it's basically free to paint.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Vibe.bg,
      child: Stack(
        children: [
          _Glow(color: Vibe.violet, top: -80, left: -60, size: 280),
          _Glow(color: Vibe.pink, top: 120, right: -90, size: 260),
          _Glow(color: Vibe.mint, bottom: -100, left: -40, size: 300),
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
  return const ColoredBox(
    color: Colors.white, // Changed from Vibe.bg to white
    child: Stack(
      children: [
        _Glow(color: Vibe.violet, top: -80, left: -60, size: 280),
        _Glow(color: Vibe.pink, top: 120, right: -90, size: 260),
        _Glow(color: Vibe.mint, bottom: -100, left: -40, size: 300),
      ],
    ),
  );
}
}
