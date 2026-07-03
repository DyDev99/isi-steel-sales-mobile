import 'package:flutter/material.dart';

/// Auth-screen visual tokens — kept as a small local class so the login
/// widgets stay decoupled, but synced to the same Blue & White palette as
/// [Vibe] (lib/core/utils/app_vibe.dart) so the whole app reads as one
/// consistent theme.
class Vibe {
  Vibe._();

  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceStrong = Color(0xFFDBEAFE);
  static const stroke = Color(0xFFE5E7EB);
  static const text = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);

  static const violet = Color(0xFF2563EB);
  static const pink = Color(0xFF3B82F6);
  static const mint = Color(0xFF0EA5E9);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);

  static const radius = 16.0;

  static const cta = LinearGradient(
    colors: [violet, Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
