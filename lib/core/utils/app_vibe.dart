import 'package:flutter/material.dart';

/// App-wide design tokens — Blue & White enterprise CRM theme.
/// One source of truth for the whole UI (Salesforce/Dynamics/Fiori style:
/// bright, minimal, blue primary actions on white).
class Vibe {
  Vibe._();

  // ── Backgrounds ────────────────────────────────────────────────────
  static const bg = Color(0xFFFFFFFF); // main background
  static const bgSoft = Color(0xFFF8FAFC); // secondary background / sheets
  static const surface = Color(0xFFFFFFFF); // card background
  static const surfaceStrong = Color(0xFFDBEAFE); // primary-light tint (selected/active bg)

  // ── Borders ────────────────────────────────────────────────────────
  static const stroke = Color(0xFFE5E7EB); // border
  static const divider = Color(0xFFEDF2F7);

  // ── Text ───────────────────────────────────────────────────────────
  static const text = Color(0xFF1F2937); // primary text
  static const muted = Color(0xFF6B7280); // secondary text
  static const disabledText = Color(0xFF9CA3AF);

  // ── Brand / accents ────────────────────────────────────────────────
  static const violet = Color(0xFF2563EB); // primary blue (brand/primary accent)
  static const primaryHover = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFDBEAFE);
  static const pink = Color(0xFF3B82F6); // secondary blue accent
  static const mint = Color(0xFF0EA5E9); // info / teal-blue accent
  static const amber = Color(0xFFF59E0B); // warning
  static const danger = Color(0xFFEF4444); // error
  static const warning = Color(0xFFFBBF24); // warning
  static const success = Color(0xFF22C55E); // success

  // ── Legacy / secondary palette ─────────────────────────────────────
  // Colours that predate the token system and are still used verbatim by
  // the Home/Shell/Lead screens. Centralised here (identical pixels) so
  // there is a single source of truth instead of raw hex scattered across
  // widgets. NOTE: [brandNavy] is a *second* brand blue distinct from
  // [violet] — these should be unified once design confirms which is
  // canonical; kept separate here to preserve the current appearance.
  static const brandNavy = Color(0xFF00569B); // ISI corporate blue (shell)
  static const brandNavyDark = Color(0xFF0F2547); // dark gradient partner
  static const accentPurple = Color(0xFF7C3AED); // "Add Visit" action accent
  static const slate = Color(0xFF1E293B); // dark slate text (pipeline)
  static const canvas = Color(0xFFF3F5F7); // home/shell scaffold background

  static const radius = 16.0;

  static const cta = LinearGradient(
    colors: [violet, primaryHover],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const coolGradient = LinearGradient(
    colors: [pink, Color(0xFF60A5FA)], // secondary blue -> accent blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft elevation used by flat enterprise cards (white bg + thin border).
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1F2937).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
