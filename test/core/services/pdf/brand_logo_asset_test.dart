import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// Guards the two ISI Group wordmark SVGs that `BrandLogo` and the quotation
/// PDF header draw.
///
/// Both failure modes here are silent. A malformed or unsupported SVG renders
/// as *nothing* — an export with a blank header still saves fine and still
/// reaches the customer — and swapping the two ink variants produces a mark
/// the same colour as the surface behind it, which is equally invisible and
/// equally undetectable from a green test run.
void main() {
  const darkPath = 'assets/logos/ISI-Group-Logo-Dark.svg';
  const lightPath = 'assets/logos/ISI-Group-Logo-Light.svg';

  test('both ink variants exist and are declared under a bundled directory',
      () {
    expect(File(darkPath).existsSync(), isTrue, reason: '$darkPath is missing');
    expect(File(lightPath).existsSync(), isTrue,
        reason: '$lightPath is missing');
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/logos/'),
      reason: 'assets/logos/ must stay in the pubspec assets list',
    );
  });

  test('the ink variants are not swapped', () {
    // If these two ever trade places, every surface in the app shows the mark
    // in the colour of the surface behind it.
    expect(File(darkPath).readAsStringSync(), contains('#15213A'));
    expect(File(lightPath).readAsStringSync(), contains('#E0E4EE'));
  });

  test('the dark variant renders through the PDF SVG engine', () async {
    // `PdfAssets` loads this exact file for the quotation header and
    // `quotation_pdf_generator` draws it with `pw.SvgImage`. The pdf package
    // implements a *subset* of SVG, so "flutter_svg can draw it" is not
    // evidence the export can.
    final svg = File(darkPath).readAsStringSync();

    Future<int> lengthOf(pw.Widget child) async {
      final doc = pw.Document();
      doc.addPage(pw.Page(build: (_) => child));
      return (await doc.save()).length;
    }

    final empty = await lengthOf(pw.SizedBox());
    final drawn = await lengthOf(pw.SvgImage(svg: svg, height: 34));

    // Measured against an empty page rather than asserting `isNotEmpty`: a
    // document whose SVG silently drew nothing still saves, and still carries
    // ~500 bytes of PDF scaffolding. Only the delta says the six paths in the
    // wordmark actually reached the content stream.
    expect(drawn, greaterThan(empty + 500),
        reason: 'the wordmark emitted no geometry into the PDF');
  });
}
