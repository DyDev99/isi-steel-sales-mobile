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
/// - Latin (English UI) is drawn with **ABC Ginto**.
/// - Khmer Unicode has no glyphs in ABC Ginto, so **MiSans Khmer** is supplied
///   as a [pw.ThemeData.fontFallback]; the PDF engine automatically falls back
///   glyph-by-glyph, which is what makes mixed "ISI Steel / ខ្មែរ" strings
///   render correctly in a single run.
///
/// Both families are loaded from the `.ttf` conversions rather than the vendor
/// drops (`.woff2` for Ginto, CFF `.otf` for MiSans): [pw.Font.ttf] parses the
/// `glyf` table only, so neither original format can be read here. See the
/// `fonts:` note in `pubspec.yaml`.
class PdfAssets {
  PdfAssets();

  pw.Font? _base;
  pw.Font? _bold;
  pw.Font? _khmer;
  pw.Font? _khmerBold;
  String? _logoSvg;
  bool _loaded = false;

  pw.Font get base => _base!;
  pw.Font get bold => _bold!;
  pw.Font get khmer => _khmer!;
  pw.Font get khmerBold => _khmerBold!;

  /// The ISI Group wordmark as raw SVG source, or `null` if the asset could
  /// not be read (the generator degrades gracefully to a text wordmark).
  ///
  /// Vector rather than the old `isi_steel_logo.png`: a quotation is printed
  /// and re-scaled by whoever receives it, which is precisely where a 34pt
  /// bitmap header shows its pixels. The **dark** ink variant is the only
  /// correct one here — the document is drawn on white paper.
  String? get logoSvg => _logoSvg;

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() async {
    if (_loaded) return;

    _base = pw.Font.ttf(
      await rootBundle.load('assets/fonts/ABCGinto-Regular.ttf'),
    );
    _bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/ABCGinto-Bold.ttf'),
    );
    _khmer = pw.Font.ttf(
      await rootBundle.load('assets/fonts/khmer/MiSansKhmer-Regular.ttf'),
    );
    _khmerBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/khmer/MiSansKhmer-Bold.ttf'),
    );

    try {
      _logoSvg =
          await rootBundle.loadString('assets/logos/ISI-Group-Logo-Dark.svg');
    } catch (_) {
      // Missing/renamed logo must never fail an export — fall back to wordmark.
      _logoSvg = null;
    }

    _loaded = true;
  }

  /// The base document theme: ABC Ginto for Latin, MiSans Khmer as glyph
  /// fallback for Khmer across both regular and bold weights.
  pw.ThemeData buildTheme() => pw.ThemeData.withFont(
        base: _base!,
        bold: _bold!,
        fontFallback: [_khmer!, _khmerBold!],
      );
}
