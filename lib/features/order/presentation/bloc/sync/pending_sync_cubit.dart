import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_sync_status.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_queue_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_queue_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/sync_queue_processor.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_state.dart';

/// Drives the Pending Sync badge/center. Subscribes to the live queue and
/// exposes the only two user-initiated actions the spec allows — **Sync Now**
/// and **Retry** — plus **discard**. It never syncs on its own; the user is
/// always in control.
class PendingSyncCubit extends Cubit<PendingSyncState> {
  PendingSyncCubit({
    required SyncQueueRepository repository,
    required SyncQueueProcessor processor,
  })  : _repository = repository,
        _processor = processor,
        super(const PendingSyncState()) {
    _subscription = _repository.watchQueue().listen(_onQueue);
  }

  final SyncQueueRepository _repository;
  final SyncQueueProcessor _processor;
  late final StreamSubscription<List<SyncQueueItem>> _subscription;

  void _onQueue(List<SyncQueueItem> items) {
    emit(state.copyWith(items: items, counts: _countsOf(items), loaded: true));
  }

  /// Drains the queue now (user tapped "Sync Now" / accepted the reconnect
  /// snackbar). Safe to call repeatedly — the processor guards re-entrancy.
  Future<void> syncNow() async {
    if (state.isSyncing) return;
    emit(state.copyWith(isSyncing: true));
    try {
      await _processor.processAll();
    } finally {
      emit(state.copyWith(isSyncing: false));
    }
  }

  /// Submits a draft into the queue as `pendingSync` **without** auto-syncing —
  /// the user still decides when to push (Sync Now / reconnect snackbar).
  Future<void> enqueue(String quotationId) => _repository.enqueue(quotationId);

  /// Re-queues a failed/rejected/conflict item and immediately tries again.
  Future<void> retry(String quotationId) async {
    await _repository.enqueue(quotationId);
    await syncNow();
  }

  /// Removes an item from the queue entirely (user chose not to sync it).
  Future<void> discard(String quotationId) => _repository.remove(quotationId);

  static SyncQueueCounts _countsOf(List<SyncQueueItem> items) {
    var pending = 0, failed = 0, conflict = 0, accepted = 0;
    for (final item in items) {
      switch (item.status) {
        case QuotationSyncStatus.pendingSync:
        case QuotationSyncStatus.syncing:
        case QuotationSyncStatus.submitted:
          pending++;
        case QuotationSyncStatus.failed:
        case QuotationSyncStatus.rejected:
          failed++;
        case QuotationSyncStatus.conflict:
          conflict++;
        case QuotationSyncStatus.accepted:
          accepted++;
        case QuotationSyncStatus.draft:
        case QuotationSyncStatus.readyToSubmit:
          break;
      }
    }
    return SyncQueueCounts(
      pending: pending,
      failed: failed,
      conflict: conflict,
      accepted: accepted,
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
