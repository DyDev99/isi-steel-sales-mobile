import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Loads and **caches** the fonts and imagery every ISI PDF needs, so the
/// (relatively expensive) asset-bundle reads happen once per app session
/// rather than on every export.
///
/// Registered as a lazy singleton in DI; [ensureLoaded] is idempotent and safe
/// to call before each generation.
///
/// Font strategy — bilingual rendering:
/// - Latin (English UI) is drawn with **Inter**.
/// - Khmer Unicode has no glyphs in Inter, so **Kantumruy** is supplied as a
///   [pw.ThemeData.fontFallback]; the PDF engine automatically falls back
///   glyph-by-glyph, which is what makes mixed "ISI Steel / ខ្មែរ" strings
///   render correctly in a single run.
class PdfAssets {
  PdfAssets();

  pw.Font? _base;
  pw.Font? _bold;
  pw.Font? _khmer;
  pw.Font? _khmerBold;
  Uint8List? _logo;
  bool _loaded = false;

  pw.Font get base => _base!;
  pw.Font get bold => _bold!;
  pw.Font get khmer => _khmer!;
  pw.Font get khmerBold => _khmerBold!;

  /// The ISI logo bytes, or `null` if the asset could not be read (the
  /// generator degrades gracefully to a text wordmark).
  Uint8List? get logo => _logo;

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() async {
    if (_loaded) return;

    _base = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter/static/Inter_18pt-Regular.ttf'),
    );
    _bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter/static/Inter_18pt-Bold.ttf'),
    );
    _khmer = pw.Font.ttf(
      await rootBundle.load(
          'assets/fonts/kantumruy_5.2.5/ttf/kantumruy-khmer-400-normal.ttf'),
    );
    _khmerBold = pw.Font.ttf(
      await rootBundle.load(
          'assets/fonts/kantumruy_5.2.5/ttf/kantumruy-khmer-700-normal.ttf'),
    );

    try {
      final data = await rootBundle.load('assets/logos/isi_steel_logo.png');
      _logo = data.buffer.asUint8List();
    } catch (_) {
      // Missing/renamed logo must never fail an export — fall back to wordmark.
      _logo = null;
    }

    _loaded = true;
  }

  /// The base document theme: Inter for Latin, Kantumruy as glyph fallback for
  /// Khmer across both regular and bold weights.
  pw.ThemeData buildTheme() => pw.ThemeData.withFont(
        base: _base!,
        bold: _bold!,
        fontFallback: [_khmer!, _khmerBold!],
      );
}
