import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';

/// Presents a generated PDF to the user: on-device preview, native
/// print/share, or opening the saved file in an external viewer.
///
/// Fully offline — [Printing] and [OpenFilex] operate on local bytes/paths and
/// make no network calls, which keeps the whole export flow airplane-mode safe
/// (STEP 9). Kept behind an interface so the UI/Cubit never touch the printing
/// plugin directly and so it can be faked in widget tests.
abstract class PdfShareService {
  /// Opens the OS print/preview sheet for [bytes]. On both Android and iOS this
  /// same sheet exposes preview, print, and "Share/Save to Files", so it is the
  /// primary post-generation action. [documentName] labels the print job.
  Future<void> previewAndPrint(Uint8List bytes, {required String documentName});

  /// Opens the native share sheet with the PDF attached as [fileName].
  Future<void> share(Uint8List bytes, {required String fileName});

  /// Opens an already-saved [file] in the platform's default PDF viewer.
  Future<void> openFile(File file);
}

class PdfShareServiceImpl implements PdfShareService {
  const PdfShareServiceImpl();

  @override
  Future<void> previewAndPrint(
    Uint8List bytes, {
    required String documentName,
  }) {
    return Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: documentName,
    );
  }

  @override
  Future<void> share(Uint8List bytes, {required String fileName}) {
    return Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  @override
  Future<void> openFile(File file) async {
    await OpenFilex.open(file.path);
  }
}
