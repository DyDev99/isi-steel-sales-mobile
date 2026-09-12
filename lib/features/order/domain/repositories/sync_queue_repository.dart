import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_queue_item.dart';

/// The outbound SAP sync queue — the single source of truth for what work is
/// waiting to reach SAP. Event-driven (a live [watchQueue] stream) rather than
/// `Result`-wrapped: the sync subsystem is internal plumbing, and callers react
/// to the stream rather than one-shot success/failure.
abstract interface class SyncQueueRepository {
  /// Live, FIFO-ordered queue (initial snapshot then updates on every change).
  Stream<List<SyncQueueItem>> watchQueue();

  /// Enqueues [quotationId] as `pendingSync`. If it is already queued in a
  /// non-accepted state, it is reset to `pendingSync` (attempt 0) — e.g. the
  /// user re-submitting a previously failed quotation.
  Future<void> enqueue(String quotationId);

  /// Items eligible to process right now (FIFO), backoff respected.
  Future<List<SyncQueueItem>> readyItems();

  /// Persists a state transition produced by the processor.
  Future<void> save(SyncQueueItem item);

  /// Aggregate counts for the pending badge.
  Future<SyncQueueCounts> counts();

  /// Removes a quotation from the queue (e.g. draft discarded).
  Future<void> remove(String quotationId);
}
