import 'dart:io';

import 'package:equatable/equatable.dart';

/// State of a single PDF export attempt. Owned by [PdfGenerationCubit];
/// document-type agnostic so the same states drive quotation, invoice, and
/// report exports.
abstract class PdfGenerationState extends Equatable {
  const PdfGenerationState();

  @override
  List<Object?> get props => [];
}

/// Idle — nothing generated yet in this screen.
class PdfInitial extends PdfGenerationState {
  const PdfInitial();
}

/// Bytes are being built and written. UI shows a blocking-free spinner.
class PdfGenerating extends PdfGenerationState {
  const PdfGenerating();
}

/// The document was written to the app sandbox and the preview/share sheet was
/// offered. [file] points at the saved PDF inside app documents.
class PdfGenerated extends PdfGenerationState {
  const PdfGenerated(this.file);

  final File file;

  @override
  List<Object?> get props => [file.path];
}

/// Generation failed. [messageKey] is a localization key (already resolvable
/// via `.tr`) suitable for a snackbar.
class PdfGenerationFailed extends PdfGenerationState {
  const PdfGenerationFailed(this.messageKey);

  final String messageKey;

  @override
  List<Object?> get props => [messageKey];
}
