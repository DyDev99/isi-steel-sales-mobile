import 'package:flutter/material.dart';

/// Paints the dimming scrim with a rounded-rectangle "hole" punched out around
/// the spotlighted widget, plus an animated glow ring on its edge.
///
/// Purely visual — it never handles hit-testing (the overlay uses separate
/// absorbing panels so taps fall through the hole to the real widget).
class HighlightPainter extends CustomPainter {
  const HighlightPainter({
    required this.hole,
    required this.radius,
    required this.scrimColor,
    required this.glowColor,
    required this.glow,
  });

  /// Cutout bounds in overlay-local coordinates, or null for a full scrim.
  final Rect? hole;
  final double radius;
  final Color scrimColor;
  final Color glowColor;

  /// 0..1 pulse used for the ring width/opacity (0 when reduced-motion).
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final scrim = Paint()..color = scrimColor;

    if (hole == null) {
      canvas.drawRect(full, scrim);
      return;
    }

    final rrect = RRect.fromRectAndRadius(hole!, Radius.circular(radius));

    // Scrim everywhere except the hole (even-odd punches the rounded rect out).
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(full)
      ..addRRect(rrect);
    canvas.drawPath(path, scrim);

    // Animated glow ring hugging the cutout.
    if (glow > 0) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + 2 * glow
        ..color = glowColor.withValues(alpha: 0.25 + 0.45 * glow);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            hole!.inflate(2 + 2 * glow), Radius.circular(radius + 2)),
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(HighlightPainter old) =>
      old.hole != hole ||
      old.glow != glow ||
      old.scrimColor != scrimColor ||
      old.glowColor != glowColor ||
      old.radius != radius;
}
