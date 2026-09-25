import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/sync_queue_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_sync_status.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_queue_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_queue_repository.dart';

class SyncQueueRepositoryImpl implements SyncQueueRepository {
  SyncQueueRepositoryImpl(this._local);
  final SyncQueueLocalDataSource _local;

  final StreamController<List<SyncQueueItem>> _controller =
      StreamController<List<SyncQueueItem>>.broadcast();

  @override
  Stream<List<SyncQueueItem>> watchQueue() async* {
    yield await _loadAll();
    yield* _controller.stream;
  }

  Future<List<SyncQueueItem>> _loadAll() async {
    final rows = await _local.fetchAllJoined();
    return rows.map(_fromJoinedRow).toList();
  }

  Future<void> _emit() async {
    if (!_controller.hasListener) return;
    _controller.add(await _loadAll());
  }

  @override
  Future<void> enqueue(String quotationId) async {
    final now = DateTime.now();
    final existing = await _local.getByQuotationId(quotationId);
    final SyncQueueItem item;
    if (existing != null) {
      // Re-submit: reuse the row, reset retry bookkeeping.
      item = _fromRow(existing).copyWith(
        status: QuotationSyncStatus.pendingSync,
        attemptCount: 0,
        updatedAt: now,
        nextRetryAt: () => null,
        lastError: () => null,
        errorCode: () => null,
      );
    } else {
      item = SyncQueueItem(
        id: _newId(),
        quotationId: quotationId,
        status: QuotationSyncStatus.pendingSync,
        attemptCount: 0,
        createdAt: now,
        updatedAt: now,
      );
    }
    await _local.upsert(_toRow(item));
    await _emit();
  }

  @override
  Future<List<SyncQueueItem>> readyItems() async {
    final rows = await _local.fetchReady(DateTime.now().toIso8601String());
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> save(SyncQueueItem item) async {
    await _local.upsert(_toRow(item));
    await _emit();
  }

  @override
  Future<SyncQueueCounts> counts() async {
    final byStatus = await _local.countsByStatus();
    int sum(List<QuotationSyncStatus> statuses) =>
        statuses.fold(0, (acc, status) => acc + (byStatus[status.name] ?? 0));
    return SyncQueueCounts(
      pending: sum([
        QuotationSyncStatus.pendingSync,
        QuotationSyncStatus.syncing,
        QuotationSyncStatus.submitted,
      ]),
      failed: byStatus[QuotationSyncStatus.failed.name] ?? 0,
      conflict: byStatus[QuotationSyncStatus.conflict.name] ?? 0,
      accepted: byStatus[QuotationSyncStatus.accepted.name] ?? 0,
    );
  }

  @override
  Future<void> remove(String quotationId) async {
    await _local.deleteByQuotationId(quotationId);
    await _emit();
  }

  // ── Mapping ────────────────────────────────────────────────────────────
  DataMap _toRow(SyncQueueItem item) => {
        'id': item.id,
        'quotation_id': item.quotationId,
        'status': item.status.name,
        'attempt_count': item.attemptCount,
        'next_retry_at': item.nextRetryAt?.toIso8601String(),
        'last_error': item.lastError,
        'error_code': item.errorCode,
        'sap_document_number': item.sapDocumentNumber,
        'sap_message': item.sapMessage,
        'sap_timestamp': item.sapTimestamp?.toIso8601String(),
        'sync_duration_ms': item.syncDurationMs,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': item.updatedAt.toIso8601String(),
      };

  SyncQueueItem _fromRow(DataMap row) => SyncQueueItem(
        id: row['id'] as String,
        quotationId: row['quotation_id'] as String,
        status: QuotationSyncStatus.fromName(row['status'] as String?),
        attemptCount: (row['attempt_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        nextRetryAt: _parseDate(row['next_retry_at']),
        lastError: row['last_error'] as String?,
        errorCode: row['error_code'] as String?,
        sapDocumentNumber: row['sap_document_number'] as String?,
        sapMessage: row['sap_message'] as String?,
        sapTimestamp: _parseDate(row['sap_timestamp']),
        syncDurationMs: (row['sync_duration_ms'] as num?)?.toInt(),
      );

  SyncQueueItem _fromJoinedRow(DataMap row) {
    final base = _fromRow(row);
    final linesJson = row['lines_json'] as String?;
    int? itemCount;
    if (linesJson != null) {
      try {
        itemCount = (jsonDecode(linesJson) as List).length;
      } catch (_) {
        itemCount = null;
      }
    }
    return SyncQueueItem(
      id: base.id,
      quotationId: base.quotationId,
      status: base.status,
      attemptCount: base.attemptCount,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      nextRetryAt: base.nextRetryAt,
      lastError: base.lastError,
      errorCode: base.errorCode,
      sapDocumentNumber: base.sapDocumentNumber,
      sapMessage: base.sapMessage,
      sapTimestamp: base.sapTimestamp,
      syncDurationMs: base.syncDurationMs,
      shopName: row['shop_name'] as String?,
      itemCount: itemCount,
      total: (row['q_total'] as num?)?.toDouble(),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static String _newId() =>
      'SQ-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';
}
