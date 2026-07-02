import 'package:flutter/material.dart';

/// Gen-Z visual tokens for the auth screens: dark canvas, glassy surfaces,
/// vivid gradient accents. Kept tiny and local so widgets stay decoupled.
class Vibe {
  Vibe._();

  static const bg = Color(0xFF0D0B1F); // deep indigo canvas
  static const surface = Color(0x14FFFFFF); // 8% white — glass fill
  static const surfaceStrong = Color(0x1FFFFFFF);
  static const stroke = Color(0x24FFFFFF); // hairline glass border
  static const text = Color(0xFFF6F4FF);
  static const muted = Color(0xFFAAA3CC);

  static const violet = Color(0xFF7C4DFF);
  static const pink = Color(0xFFFF63C1);
  static const mint = Color(0xFF3DE0C8);
  static const danger = Color(0xFFFF5A72);
  static const success = Color(0xFF3EE599);

  static const radius = 22.0;

  static const cta = LinearGradient(
    colors: [violet, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
