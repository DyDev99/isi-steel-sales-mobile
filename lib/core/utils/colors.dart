import 'package:flutter/material.dart';

/// Single source of truth for every color used in the app.
///
/// This is the canonical token set — [lib/core/utils/app_vibe.dart]'s
/// `Vibe` (used by ~110 presentation files) and
/// [lib/core/theme/auth_vibe.dart]'s `Vibe` (used by the auth/splash/login
/// flow) both now delegate their constants to this file instead of
/// declaring their own hex literals, so a color only ever has one
/// definition. Both `Vibe` classes are kept as thin backward-compatible
/// facades — existing call sites (`Vibe.text`, `Vibe.violet`, ...) keep
/// working unchanged; new/updated code should reference [AppColors]
/// directly.
class AppColors {
  AppColors._();

  // ── Brand / Primary ───────────────────────────────────────────────
  static const primary = Color(0xFF2563EB); // brand blue — primary actions
  static const primaryHover = Color(0xFF1D4ED8); // pressed/hover state
  static const primaryLight = Color(0xFFDBEAFE); // tint bg for selected/active
  static const secondary = Color(0xFF3B82F6); // secondary blue accent
  static const secondaryLight = Color(0xFF60A5FA); // secondary gradient partner

  // ── Surfaces / Backgrounds ───────────────────────────────────────
  static const background = Color(0xFFFFFFFF); // main app background
  static const backgroundSoft =
      Color(0xFFF8FAFC); // secondary background / sheets
  static const scaffoldBackground = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF); // card / sheet surface
  static const surfaceStrong = Color(0xFFDBEAFE); // primary-light tint surface
  static const card = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF3F5F7); // home/shell scaffold background

  // ── Border / Divider / Shadow ─────────────────────────────────────
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFEDF2F7);
  static const shadow = Color(0xFF1F2937);

  // ── Status ─────────────────────────────────────────────────────────
  static const success = Color.fromARGB(255, 47, 199, 103);
  static const warning = Color(
      0xFFF59E0B); // canonical warning (existing "amber" token, 50+ call sites)
  static const warningAlt = Color(
      0xFFFBBF24); // legacy near-duplicate warning shade — see README note
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);

  // ── Text ───────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);
  static const textDisabled = Color(0xFF9CA3AF);
  static const textInverse = Color(0xFFFFFFFF);

  // ── Buttons ──────────────────────────────────────────────────────
  static const buttonPrimary = primary;
  static const buttonSecondary = primaryLight;
  static const buttonText = Color(0xFFFFFFFF);

  // ── Icons / Interaction states ────────────────────────────────────
  static const icon = Color(0xFF1F2937);
  static const iconMuted = Color(0xFF6B7280);
  static const selected = primary;
  static const unselected = Color(0xFF9CA3AF);
  static const overlay = Color(0x991F2937); // modal/scrim overlay
  static const transparent = Colors.transparent;

  // ── Legacy / secondary palette ─────────────────────────────────────
  // Colours that predate the token system and are still used verbatim by
  // the Home/Shell/Lead screens. NOTE: [brandNavy] is a *second* brand
  // blue distinct from [primary] — kept separate to preserve current
  // appearance until design confirms which is canonical.
  static const brandNavy = Color(0xFF00569B);
  static const brandNavyDark = Color(0xFF0F2547);
  static const accentPurple = Color(0xFF7C3AED);
  static const slate = Color(0xFF1E293B);

  static const double radius = 16.0;

  static const ctaGradient = LinearGradient(
    colors: [primary, primaryHover],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const coolGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft elevation used by flat enterprise cards (white bg + thin border).
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadow.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
