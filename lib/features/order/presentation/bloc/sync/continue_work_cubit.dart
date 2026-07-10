import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_status.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_queue_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_queue_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/delete_quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_quotations.dart';

class ContinueWorkState extends Equatable {
  const ContinueWorkState({this.drafts = const [], this.loaded = false});

  /// Resumable drafts, most-recently-edited first.
  final List<Quotation> drafts;
  final bool loaded;

  Quotation? get mostRecent => drafts.isEmpty ? null : drafts.first;
  bool get hasMultiple => drafts.length > 1;

  ContinueWorkState copyWith({List<Quotation>? drafts, bool? loaded}) =>
      ContinueWorkState(
        drafts: drafts ?? this.drafts,
        loaded: loaded ?? this.loaded,
      );

  @override
  List<Object?> get props => [drafts, loaded];
}

/// Feeds the floating "Continue Previous Work" card. A *draft* is a saved,
/// still-editable quotation that has **not** been handed to the sync queue —
/// once submitted it belongs to the Pending Sync center instead, so those are
/// excluded here. Purely surfaces state; it never auto-navigates or discards.
class ContinueWorkCubit extends Cubit<ContinueWorkState> {
  ContinueWorkCubit({
    required WatchQuotations watchQuotations,
    required SyncQueueRepository syncQueue,
    required DeleteQuotation deleteQuotation,
  })  : _syncQueue = syncQueue,
        _deleteQuotation = deleteQuotation,
        super(const ContinueWorkState()) {
    _quotationsSub = watchQuotations(const NoParams()).listen(_onQuotations);
    _queueSub = syncQueue.watchQueue().listen(_onQueue);
  }

  final SyncQueueRepository _syncQueue;
  final DeleteQuotation _deleteQuotation;
  late final StreamSubscription<List<Quotation>> _quotationsSub;
  late final StreamSubscription<List<SyncQueueItem>> _queueSub;

  /// Permanently discards a draft (deletes the quotation and any queue entry).
  Future<void> discard(String quotationId) async {
    await _deleteQuotation(QuotationIdParams(quotationId));
    await _syncQueue.remove(quotationId);
  }

  List<Quotation> _quotations = const [];
  Set<String> _queuedIds = const {};

  void _onQuotations(List<Quotation> quotations) {
    _quotations = quotations;
    _recompute();
  }

  void _onQueue(List<SyncQueueItem> items) {
    _queuedIds = items.map((i) => i.quotationId).toSet();
    _recompute();
  }

  void _recompute() {
    final drafts = _quotations
        .where((q) =>
            q.status == QuotationStatus.saved && !_queuedIds.contains(q.id))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    emit(ContinueWorkState(drafts: drafts, loaded: true));
  }

  @override
  Future<void> close() {
    _quotationsSub.cancel();
    _queueSub.cancel();
    return super.close();
  }
}
