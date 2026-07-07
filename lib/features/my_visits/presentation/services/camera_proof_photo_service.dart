import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/proof_photo_service.dart';

/// Real camera-backed proof photo: captures via `image_picker` (which handles
/// the native camera permission prompt), then stamps the timestamp + GPS onto
/// the pixels on a background isolate (`compute`) so the UI thread never jank.
class CameraProofPhotoService implements ProofPhotoService {
  const CameraProofPhotoService();

  @override
  Future<ProofPhotoResult?> captureStamped({required double latitude, required double longitude}) async {
    final XFile? shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70, // in-picker compression
      maxWidth: 1600,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (shot == null) return null; // user backed out of the camera

    final takenAt = DateTime.now();
    final bytes = await shot.readAsBytes();

    final stamped = await compute(
      _stampImage,
      _StampRequest(
        bytes: bytes,
        lines: [
          _formatTimestamp(takenAt),
          'GPS ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
        ],
      ),
    );

    // Persist alongside the picker's own file (a writable app cache dir).
    final dir = File(shot.path).parent.path;
    final outPath = '$dir/proof_${takenAt.microsecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(stamped, flush: true);

    return ProofPhotoResult(filePath: outPath, takenAt: takenAt);
  }

  static String _formatTimestamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

class _StampRequest {
  const _StampRequest({required this.bytes, required this.lines});
  final Uint8List bytes;
  final List<String> lines;
}

/// Runs inside a background isolate. Draws a translucent bar across the bottom
/// of the photo and writes the stamp lines onto it, then re-encodes as JPEG.
Uint8List _stampImage(_StampRequest req) {
  final decoded = img.decodeImage(req.bytes);
  if (decoded == null) return req.bytes;

  final font = img.arial24;
  const lineHeight = 30;
  const paddingX = 14;
  final barHeight = req.lines.length * lineHeight + 18;
  final top = decoded.height - barHeight;

  img.fillRect(
    decoded,
    x1: 0,
    y1: top,
    x2: decoded.width,
    y2: decoded.height,
    color: img.ColorRgba8(0, 0, 0, 140),
  );

  var y = top + 8;
  for (final line in req.lines) {
    img.drawString(decoded, line, font: font, x: paddingX, y: y, color: img.ColorRgb8(255, 255, 255));
    y += lineHeight;
  }

  return Uint8List.fromList(img.encodeJpg(decoded, quality: 80));
}
