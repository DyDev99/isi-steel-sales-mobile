import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_sync_status.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sap_submit_result.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_queue_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/quotation_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_queue_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/quotation_sap_service.dart';

/// Exponential-ish backoff between retries — 5s, 15s, 30s — after which the
/// item moves to `failed` and requires explicit user action (per spec).
const List<Duration> kSyncRetryBackoffs = [
  Duration(seconds: 5),
  Duration(seconds: 15),
  Duration(seconds: 30),
];

/// Drains the outbound SAP sync queue FIFO, applying the retry policy and
/// persisting every state transition so progress survives an app kill.
///
/// It is deliberately *not* a timer/loop that fires on its own — it only runs
/// when explicitly asked (user taps "Sync Now", or the connectivity observer
/// offers to sync and the user accepts). Nothing here ever navigates or
/// interrupts the user; it only mutates queue state.
class SyncQueueProcessor {
  SyncQueueProcessor({
    required SyncQueueRepository queue,
    required QuotationRepository quotations,
    required QuotationSapService sap,
    required NetworkInfo network,
  })  : _queue = queue,
        _quotations = quotations,
        _sap = sap,
        _network = network;

  final SyncQueueRepository _queue;
  final QuotationRepository _quotations;
  final QuotationSapService _sap;
  final NetworkInfo _network;

  bool _running = false;

  /// True while a drain is in progress — lets callers avoid overlapping runs.
  bool get isRunning => _running;

  /// Processes ready items oldest-first until the queue is drained or the
  /// device goes offline. Re-entrancy-guarded. Returns silently when offline —
  /// the queue simply stays put until the next attempt.
  Future<void> processAll() async {
    if (_running) return;
    _running = true;
    try {
      if (!await _network.isConnected) return;
      // Bounded by the number of ready items at the start plus a safety cap so
      // a persistently-rescheduling item can't spin the loop forever.
      var guard = 0;
      while (guard++ < 1000) {
        if (!await _network.isConnected) break;
        final ready = await _queue.readyItems();
        if (ready.isEmpty) break;
        await _processOne(ready.first);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _processOne(SyncQueueItem item) async {
    final startedAt = DateTime.now();
    await _queue.save(item.copyWith(
      status: QuotationSyncStatus.syncing,
      updatedAt: startedAt,
    ));

    final quotation = await _loadQuotation(item.quotationId);
    if (quotation == null) {
      // The draft is gone — nothing to sync; drop it from the queue.
      await _queue.remove(item.quotationId);
      return;
    }

    final attemptsMade = item.attemptCount + 1;
    final result = await _sap.submit(quotation, attempt: item.attemptCount);
    final durationMs = DateTime.now().difference(startedAt).inMilliseconds;

    switch (result) {
      case SapAccepted(:final documentNumber, :final message, :final timestamp):
        await _queue.save(item.copyWith(
          status: QuotationSyncStatus.accepted,
          attemptCount: attemptsMade,
          updatedAt: DateTime.now(),
          nextRetryAt: () => null,
          lastError: () => null,
          errorCode: () => null,
          sapDocumentNumber: () => documentNumber,
          sapMessage: () => message,
          sapTimestamp: () => timestamp,
          syncDurationMs: () => durationMs,
        ));
      case SapRejected(:final errorCode, :final message):
        await _queue.save(item.copyWith(
          status: QuotationSyncStatus.rejected,
          attemptCount: attemptsMade,
          updatedAt: DateTime.now(),
          nextRetryAt: () => null,
          lastError: () => message,
          errorCode: () => errorCode,
          syncDurationMs: () => durationMs,
        ));
      case SapConflict(:final message):
        await _queue.save(item.copyWith(
          status: QuotationSyncStatus.conflict,
          attemptCount: attemptsMade,
          updatedAt: DateTime.now(),
          nextRetryAt: () => null,
          lastError: () => message,
          syncDurationMs: () => durationMs,
        ));
      case SapTransportFailure(:final message):
        _applyRetryOrFail(item, attemptsMade, message, durationMs);
    }
  }

  Future<void> _applyRetryOrFail(
      SyncQueueItem item, int attemptsMade, String message, int durationMs) {
    // attemptsMade maps to backoff index: 1→5s, 2→15s, 3→30s; beyond → fail.
    if (attemptsMade > kSyncRetryBackoffs.length) {
      return _queue.save(item.copyWith(
        status: QuotationSyncStatus.failed,
        attemptCount: attemptsMade,
        updatedAt: DateTime.now(),
        nextRetryAt: () => null,
        lastError: () => message,
        syncDurationMs: () => durationMs,
      ));
    }
    final backoff = kSyncRetryBackoffs[attemptsMade - 1];
    return _queue.save(item.copyWith(
      status: QuotationSyncStatus.pendingSync,
      attemptCount: attemptsMade,
      updatedAt: DateTime.now(),
      nextRetryAt: () => DateTime.now().add(backoff),
      lastError: () => message,
      syncDurationMs: () => durationMs,
    ));
  }

  Future<Quotation?> _loadQuotation(String id) async {
    final result = await _quotations.getQuotationById(id);
    return result.when(success: (q) => q, failure: (_) => null);
  }
}
