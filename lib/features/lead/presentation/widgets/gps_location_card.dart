import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// Static placeholder "map" — no maps package is wired up (out of scope for
/// this demo), so this just renders the captured coordinates over a
/// decorative grid with a pin, which is enough to show the GPS field exists.
class GpsLocationCard extends StatelessWidget {
  const GpsLocationCard(
      {super.key,
      required this.latitude,
      required this.longitude,
      required this.address});
  final double latitude;
  final double longitude;
  final String address;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Vibe.violet.withValues(alpha: 0.25),
              Vibe.mint.withValues(alpha: 0.18)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size.infinite, painter: _GridPainter()),
            const Icon(Icons.location_on_rounded, color: Vibe.pink, size: 34),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Vibe.bg.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)} · $address',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Vibe.text, fontSize: 11.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
