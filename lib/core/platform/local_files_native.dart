import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Android/iOS implementations. Selected by the conditional export in
/// `local_files.dart` — never compiled on web.

bool localFileExists(String path) => File(path).existsSync();

Uint8List? readLocalFileSync(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsBytesSync() : null;
}

Image localFileImage(
  String path, {
  BoxFit? fit,
  double? width,
  double? height,
}) {
  return Image.file(File(path), fit: fit, width: width, height: height);
}
