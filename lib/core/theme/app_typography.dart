import 'package:flutter/material.dart';

/// App-wide typography — single source of truth for the [fontFamily] and
/// the [TextTheme] every screen inherits via `Theme.of(context).textTheme`.
///
/// The family is locale-aware: the English (Latin) UI renders in **Inter**,
/// while Khmer renders in **Kantumruy** (which ships Khmer glyphs Inter lacks).
/// Only a subset of weights ships for each family — text styles that ask for a
/// weight in between (e.g. [FontWeight.w600]) still render fine, because Skia
/// snaps to the nearest weight registered for the family in pubspec.yaml.
class AppTypography {
  AppTypography._();

  /// Latin/English UI font (pubspec: `family: Inter`, weights 300–900).
  static const String latinFontFamily = 'Inter';

  /// Khmer UI font (pubspec: `family: Kantumruy`, weights 300/400/700).
  static const String khmerFontFamily = 'Kantumruy';

  /// Back-compat alias — defaults to the Latin family.
  static const String fontFamily = latinFontFamily;

  /// Picks the font family for [locale]: Kantumruy for Khmer (`km`), Inter for
  /// English and any other Latin-script locale.
  static String fontFamilyForLocale(Locale locale) =>
      locale.languageCode == 'km' ? khmerFontFamily : latinFontFamily;

  /// Full Material type scale rendered in [fontFamily]. Built from Flutter's
  /// default Material 3 scale so every predefined [TextTheme] slot keeps its
  /// standard size/weight and only the [fontFamily] and text color change.
  static TextTheme textTheme(
    Color color, {
    String fontFamily = latinFontFamily,
  }) =>
      Typography.material2021(platform: TargetPlatform.android).black.apply(
          fontFamily: fontFamily,
          bodyColor: color,
          displayColor: color,
          decorationColor: color);
}
