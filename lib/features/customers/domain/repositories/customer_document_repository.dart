import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_document.dart';

/// One captured file waiting to be uploaded.
///
/// Deliberately a path and a timestamp rather than bytes: the file stays on
/// disk until the upload is confirmed, and `capturedAt` is stamped at photo
/// time so a queued upload is dated to the visit, not to whenever the
/// connection came back.
class PendingCustomerDocument {
  const PendingCustomerDocument({
    required this.type,
    required this.filePath,
    required this.capturedAt,
  });

  final CustomerDocumentType type;
  final String filePath;
  final DateTime capturedAt;
}

/// What happened to a batch of uploads.
///
/// [rejected] is kept apart from [failed] because the two demand opposite
/// responses: a 4xx will fail identically forever — a PDF sent to a photo slot,
/// a file over 10 MB — so retrying it wastes a rep's connection, while a 5xx or
/// a dropped link is worth another attempt.
class CustomerDocumentUploadOutcome {
  const CustomerDocumentUploadOutcome({
    this.uploaded = const [],
    this.failed = const [],
    this.rejected = const [],
  });

  final List<CustomerDocumentType> uploaded;
  final List<CustomerDocumentType> failed;
  final List<CustomerDocumentType> rejected;

  bool get isCompleteSuccess => failed.isEmpty && rejected.isEmpty;

  /// Slots the rep still needs to deal with, in a stable order so the message
  /// reads the same every time.
  List<CustomerDocumentType> get outstanding =>
      [...failed, ...rejected]..sort((a, b) => a.index.compareTo(b.index));
}

/// The customer's on-site evidence photographs.
///
/// Separate from the registration repository because the lifetime differs: the
/// documents outlive the draft and are edited from the customer's detail screen
/// long after registration closed.
abstract interface class CustomerDocumentRepository {
  /// What the server holds for [customerId], and what is still missing.
  ResultFuture<CustomerDocumentsState> fetch(String customerId);

  /// Uploads every captured file, one request each.
  ///
  /// **Never throws and never reports overall failure**, because a customer is
  /// not allowed to be lost to a photograph. The registration has already
  /// succeeded by the time this runs; HQ blocks approval on the server's own
  /// `isComplete` rather than the app refusing to save
  /// (`docs/feature/customer/mobile/customer-documents.md` §The checklist).
  ResultFuture<CustomerDocumentUploadOutcome> uploadAll({
    required String customerId,
    required List<PendingCustomerDocument> documents,
  });

  ResultFuture<void> delete({
    required String customerId,
    required String documentId,
  });
}
