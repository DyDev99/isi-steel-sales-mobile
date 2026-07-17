import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Persists generated PDF bytes to disk.
///
/// Security (SECURITY.md §3 / §10): documents contain customer data and
/// pricing, so they are written **only** inside the app sandbox
/// ([getApplicationDocumentsDirectory] — not a public/cache/Downloads folder),
/// under a dedicated `pdf/` subfolder. Filenames are sanitized and stamped to
/// the second, which both prevents path-injection via a caller-supplied prefix
/// and guarantees a new file per export (no silent overwrite of a prior
/// quotation).
abstract class PdfFileService {
  /// Saves [bytes] and returns the written [File]. [fileNamePrefix] is
  /// sanitized; a `_YYYYMMDD_HHmmss.pdf` suffix is always appended.
  Future<File> save(Uint8List bytes, {required String fileNamePrefix});
}

class PdfFileServiceImpl implements PdfFileService {
  const PdfFileServiceImpl();

  static final RegExp _unsafe = RegExp(r'[^A-Za-z0-9_-]');

  @override
  Future<File> save(Uint8List bytes, {required String fileNamePrefix}) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${docsDir.path}${Platform.pathSeparator}pdf');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final fileName = _buildFileName(fileNamePrefix);
    final file = File('${pdfDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _buildFileName(String prefix) {
    final safePrefix = prefix.replaceAll(_unsafe, '_');
    final effectivePrefix = safePrefix.isEmpty ? 'ISI_Document' : safePrefix;
    return '${effectivePrefix}_${_timestamp()}.pdf';
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
