import 'package:flutter/material.dart';

/// App-wide typography — single source of truth for the [fontFamily], its
/// script fallback, and the [TextTheme] every screen inherits via
/// `Theme.of(context).textTheme`.
///
/// ## Two complementary families, never one
///
/// The app ships **ABC Ginto** (Latin) and **MiSans Khmer** (Khmer). Unlike the
/// previous Inter/Kantumruy pair, neither family covers the other's script at
/// all: ABC Ginto has no codepoint in U+1780–17FF, and MiSans Khmer covers no
/// ASCII beyond the space. Selecting one family per locale is therefore not
/// enough — a Khmer screen would render every price, SKU and date as tofu, and
/// an English screen would do the same for the Khmer half of bilingual master
/// data.
///
/// So the locale picks the *primary* family and the other family is always
/// supplied as [fontFamilyFallbackForLocale]; Flutter resolves the fallback
/// per glyph, so mixed "ISI Steel · ខ្មែរ · 12,500kg" runs render in one pass.
///
/// ## Weights
///
/// ABC Ginto ships 400/500/700 and MiSans Khmer 100–700 + 900 (see the mapping
/// note in `pubspec.yaml`). A style asking for a weight in between still renders
/// — Flutter snaps to the nearest weight registered for the family — so w600
/// resolves to Ginto Medium on Latin and to MiSans Semibold on Khmer.
class AppTypography {
  AppTypography._();

  /// Latin/English UI font (pubspec: `family: ABC Ginto`, weights 400/500/700).
  static const String latinFontFamily = 'ABC Ginto';

  /// Khmer UI font (pubspec: `family: MiSans Khmer`, weights 100–700, 900).
  static const String khmerFontFamily = 'MiSans Khmer';

  /// Back-compat alias — defaults to the Latin family.
  static const String fontFamily = latinFontFamily;

  /// Picks the primary font family for [locale]: MiSans Khmer for Khmer (`km`),
  /// ABC Ginto for English and any other Latin-script locale.
  static String fontFamilyForLocale(Locale locale) =>
      locale.languageCode == 'km' ? khmerFontFamily : latinFontFamily;

  /// The glyph fallback chain for [locale] — always the *other* family, so text
  /// outside the primary family's script still renders. See the class doc.
  static List<String> fontFamilyFallbackForLocale(Locale locale) =>
      fallbackFor(fontFamilyForLocale(locale));

  /// The fallback chain for an already-resolved [family]. Kept separate from
  /// [fontFamilyFallbackForLocale] so callers holding only the family string
  /// (e.g. `AppTheme.light(fontFamily)`) do not have to re-derive the locale.
  static List<String> fallbackFor(String family) => family == khmerFontFamily
      ? const [latinFontFamily]
      : const [khmerFontFamily];

  /// Full Material type scale rendered in [fontFamily]. Built from Flutter's
  /// default Material 3 scale so every predefined [TextTheme] slot keeps its
  /// standard size/weight and only the family and text color change.
  ///
  /// [fontFamilyFallback] defaults to the counterpart script family, which is
  /// what makes bilingual strings render in the default text theme.
  static TextTheme textTheme(
    Color color, {
    String fontFamily = latinFontFamily,
    List<String>? fontFamilyFallback,
  }) =>
      Typography.material2021(platform: TargetPlatform.android).black.apply(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamilyFallback ?? fallbackFor(fontFamily),
            bodyColor: color,
            displayColor: color,
            decorationColor: color,
          );
}
