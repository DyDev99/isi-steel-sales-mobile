import 'package:flutter/material.dart';

/// App-wide Gen-Z design tokens. One source of truth for the whole UI.
class Vibe {
  Vibe._();

  static const bg = Color(0xFF0D0B1F);
  static const bgSoft = Color(0xFF14112B);
  static const surface = Color(0x14FFFFFF);
  static const surfaceStrong = Color(0x1FFFFFFF);
  static const stroke = Color(0x24FFFFFF);
  static const text = Color(0xFFF6F4FF);
  static const muted = Color(0xFFAAA3CC);

  static const violet = Color(0xFF7C4DFF);
  static const pink = Color(0xFFFF63C1);
  static const mint = Color(0xFF3DE0C8);
  static const amber = Color(0xFFFFC15E);
  static const danger = Color(0xFFFF5A72);
  static const success = Color(0xFF3EE599);

  static const radius = 22.0;

  static const cta = LinearGradient(
    colors: [violet, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const coolGradient = LinearGradient(
    colors: [violet, mint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
