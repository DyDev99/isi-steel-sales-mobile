import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_sync_status.dart';

/// One quotation's slot in the outbound SAP sync queue. Ordered FIFO by
/// [createdAt]. Sync state lives here (not on the quotation row) so the queue
/// is fully decoupled from quotation persistence.
///
/// The optional [shopName]/[itemCount]/[total] are display fields hydrated by a
/// join with the `quotations` table when listing the Pending Sync center — they
/// are null on the bare row read during processing.
class SyncQueueItem extends Equatable {
  const SyncQueueItem({
    required this.id,
    required this.quotationId,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    required this.updatedAt,
    this.nextRetryAt,
    this.lastError,
    this.errorCode,
    this.sapDocumentNumber,
    this.sapMessage,
    this.sapTimestamp,
    this.syncDurationMs,
    this.shopName,
    this.itemCount,
    this.total,
  });

  final String id;
  final String quotationId;
  final QuotationSyncStatus status;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Earliest time this item may be retried (backoff). Null = eligible now.
  final DateTime? nextRetryAt;
  final String? lastError;
  final String? errorCode;

  // ── SAP response (persisted per spec) ─────────────────────────────────
  final String? sapDocumentNumber;
  final String? sapMessage;
  final DateTime? sapTimestamp;
  final int? syncDurationMs;

  // ── Display join fields (nullable) ────────────────────────────────────
  final String? shopName;
  final int? itemCount;
  final double? total;

  /// Ready to be picked up by the FIFO processor right now.
  bool isReady(DateTime now) =>
      status == QuotationSyncStatus.pendingSync &&
      (nextRetryAt == null || !nextRetryAt!.isAfter(now));

  SyncQueueItem copyWith({
    QuotationSyncStatus? status,
    int? attemptCount,
    DateTime? updatedAt,
    DateTime? Function()? nextRetryAt,
    String? Function()? lastError,
    String? Function()? errorCode,
    String? Function()? sapDocumentNumber,
    String? Function()? sapMessage,
    DateTime? Function()? sapTimestamp,
    int? Function()? syncDurationMs,
  }) {
    return SyncQueueItem(
      id: id,
      quotationId: quotationId,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextRetryAt: nextRetryAt != null ? nextRetryAt() : this.nextRetryAt,
      lastError: lastError != null ? lastError() : this.lastError,
      errorCode: errorCode != null ? errorCode() : this.errorCode,
      sapDocumentNumber: sapDocumentNumber != null
          ? sapDocumentNumber()
          : this.sapDocumentNumber,
      sapMessage: sapMessage != null ? sapMessage() : this.sapMessage,
      sapTimestamp: sapTimestamp != null ? sapTimestamp() : this.sapTimestamp,
      syncDurationMs:
          syncDurationMs != null ? syncDurationMs() : this.syncDurationMs,
      shopName: shopName,
      itemCount: itemCount,
      total: total,
    );
  }

  @override
  List<Object?> get props => [
        id,
        quotationId,
        status,
        attemptCount,
        createdAt,
        updatedAt,
        nextRetryAt,
        lastError,
        errorCode,
        sapDocumentNumber,
        sapMessage,
        sapTimestamp,
        syncDurationMs,
        shopName,
        itemCount,
        total,
      ];
}

/// Aggregate counts for the Pending Sync badge/center — one cheap GROUP BY.
class SyncQueueCounts extends Equatable {
  const SyncQueueCounts({
    this.pending = 0,
    this.failed = 0,
    this.conflict = 0,
    this.accepted = 0,
  });

  final int pending;
  final int failed;
  final int conflict;
  final int accepted;

  /// What the MainShell badge shows — everything still demanding attention.
  int get outstanding => pending + failed + conflict;

  @override
  List<Object?> get props => [pending, failed, conflict, accepted];
}
