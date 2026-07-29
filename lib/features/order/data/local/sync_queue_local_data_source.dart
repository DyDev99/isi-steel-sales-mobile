import 'package:isi_steel_sales_mobile/core/database/drift/daos/order_dao.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';

/// Raw CRUD over the `sync_queue` table (row maps in, row maps out — the
/// repository owns entity mapping, mirroring [QuotationLocalDataSourceImpl]).
abstract interface class SyncQueueLocalDataSource {
  Future<void> upsert(DataMap row);

  /// All queue rows joined with their quotation for display, FIFO order.
  Future<List<DataMap>> fetchAllJoined();

  /// Rows eligible for processing now: `pendingSync` whose backoff has elapsed,
  /// oldest first (FIFO).
  Future<List<DataMap>> fetchReady(String nowIso);

  Future<DataMap?> getByQuotationId(String quotationId);

  /// `status -> count`, for the pending badge.
  Future<Map<String, int>> countsByStatus();

  Future<void> deleteByQuotationId(String quotationId);
}

/// Drift-backed sync queue (**T1.5b**), replacing the plaintext `catalog.db`
/// implementation.
///
/// Moving this table into the encrypted database matters more than the others:
/// queue rows carry the full quotation payload awaiting push, so until now the
/// most business-sensitive data in the app sat unencrypted the longest —
/// precisely while offline and waiting to sync.
///
/// Still the Orders-local queue, **not** ADR-006's unified engine. The
/// promotion into `core/sync/` is Phase 4 and is deliberately not attempted
/// here; doing the move first means that promotion is a refactor rather than a
/// second migration of live field data.
class SyncQueueLocalDataSourceImpl implements SyncQueueLocalDataSource {
  const SyncQueueLocalDataSourceImpl(this._dao);
  final SyncQueueDao _dao;

  @override
  Future<void> upsert(DataMap row) async {
    try {
      await _dao.upsert(row);
    } catch (e) {
      throw CacheException(message: 'Failed to write sync queue item: $e');
    }
  }

  @override
  Future<List<DataMap>> fetchAllJoined() async {
    try {
      return await _dao.fetchAllJoined();
    } catch (e) {
      throw CacheException(message: 'Failed to read sync queue: $e');
    }
  }

  @override
  Future<List<DataMap>> fetchReady(String nowIso) async {
    try {
      return await _dao.fetchReady(nowIso);
    } catch (e) {
      throw CacheException(message: 'Failed to read ready sync items: $e');
    }
  }

  @override
  Future<DataMap?> getByQuotationId(String quotationId) async {
    try {
      return await _dao.getByQuotationId(quotationId);
    } catch (e) {
      throw CacheException(message: 'Failed to read sync item: $e');
    }
  }

  @override
  Future<Map<String, int>> countsByStatus() async {
    try {
      return await _dao.countsByStatus();
    } catch (e) {
      throw CacheException(message: 'Failed to count sync queue: $e');
    }
  }

  @override
  Future<void> deleteByQuotationId(String quotationId) async {
    try {
      await _dao.deleteByQuotationId(quotationId);
    } catch (e) {
      throw CacheException(message: 'Failed to remove sync item: $e');
    }
  }
}
