import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';

/// App-wide design tokens — Blue & White enterprise CRM theme.
///
/// This class is now a thin backward-compatible facade: every value here
/// delegates to [AppColors] (lib/core/utils/colors.dart), the single
/// source of truth for the app's color palette. Existing call sites
/// (`Vibe.text`, `Vibe.violet`, ...) keep working unchanged; new code
/// should prefer [AppColors] directly.
class Vibe {
  Vibe._();

  // ── Backgrounds ────────────────────────────────────────────────────
  static const bg = AppColors.background; // main background
  static const bgSoft =
      AppColors.backgroundSoft; // secondary background / sheets
  static const surface = AppColors.surface; // card background
  static const surfaceStrong =
      AppColors.surfaceStrong; // primary-light tint (selected/active bg)

  // ── Borders ────────────────────────────────────────────────────────
  static const stroke = AppColors.border; // border
  static const divider = AppColors.divider;

  // ── Text ───────────────────────────────────────────────────────────
  static const text = AppColors.textPrimary; // primary text
  static const muted = AppColors.textSecondary; // secondary text
  static const disabledText = AppColors.textDisabled;

  // ── Brand / accents ────────────────────────────────────────────────
  static const violet =
      AppColors.primary; // primary blue (brand/primary accent)
  static const primaryHover = AppColors.primaryHover;
  static const primaryLight = AppColors.primaryLight;
  static const pink = AppColors.secondary; // secondary blue accent
  static const mint = AppColors.info; // info / teal-blue accent
  static const amber = AppColors.warning; // warning
  static const danger = AppColors.error; // error
  static const warning = AppColors
      .warningAlt; // warning (legacy near-duplicate shade — see AppColors note)
  static const success = AppColors.success; // success

  // ── Legacy / secondary palette ─────────────────────────────────────
  // Colours that predate the token system and are still used verbatim by
  // the Home/Shell/Lead screens. Centralised here (identical pixels) so
  // there is a single source of truth instead of raw hex scattered across
  // widgets. NOTE: [brandNavy] is a *second* brand blue distinct from
  // [violet] — these should be unified once design confirms which is
  // canonical; kept separate here to preserve the current appearance.
  static const brandNavy = AppColors.brandNavy; // ISI corporate blue (shell)
  static const brandNavyDark = AppColors.brandNavyDark; // dark gradient partner
  static const accentPurple =
      AppColors.accentPurple; // "Add Visit" action accent
  static const slate = AppColors.slate; // dark slate text (pipeline)
  static const canvas = AppColors.canvas; // home/shell scaffold background

  static const radius = AppColors.radius;

  static const cta = AppColors.ctaGradient;
  static const coolGradient = AppColors.coolGradient;

  /// Soft elevation used by flat enterprise cards (white bg + thin border).
  static List<BoxShadow> get cardShadow => AppColors.cardShadow;
}
