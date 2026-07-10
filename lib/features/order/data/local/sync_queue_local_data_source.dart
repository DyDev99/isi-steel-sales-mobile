import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_database.dart';
import 'package:sqflite/sqflite.dart';

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

class SyncQueueLocalDataSourceImpl implements SyncQueueLocalDataSource {
  const SyncQueueLocalDataSourceImpl(this._catalogDb);
  final CatalogDatabase _catalogDb;
  Database get _db => _catalogDb.db;

  static const _joinSql = '''
    SELECT sq.id, sq.quotation_id, sq.status, sq.attempt_count,
           sq.next_retry_at, sq.last_error, sq.error_code,
           sq.sap_document_number, sq.sap_message, sq.sap_timestamp,
           sq.sync_duration_ms, sq.created_at, sq.updated_at,
           q.shop_name AS shop_name, q.total AS q_total,
           q.lines_json AS lines_json
    FROM sync_queue sq
    LEFT JOIN quotations q ON q.id = sq.quotation_id
    ORDER BY sq.created_at ASC
  ''';

  @override
  Future<void> upsert(DataMap row) async {
    try {
      await _db.insert('sync_queue', row,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to write sync queue item: $e');
    }
  }

  @override
  Future<List<DataMap>> fetchAllJoined() async {
    try {
      return await _db.rawQuery(_joinSql);
    } catch (e) {
      throw CacheException(message: 'Failed to read sync queue: $e');
    }
  }

  @override
  Future<List<DataMap>> fetchReady(String nowIso) async {
    try {
      return await _db.query(
        'sync_queue',
        where: 'status = ? AND (next_retry_at IS NULL OR next_retry_at <= ?)',
        whereArgs: ['pendingSync', nowIso],
        orderBy: 'created_at ASC',
      );
    } catch (e) {
      throw CacheException(message: 'Failed to read ready sync items: $e');
    }
  }

  @override
  Future<DataMap?> getByQuotationId(String quotationId) async {
    try {
      final rows = await _db.query('sync_queue',
          where: 'quotation_id = ?', whereArgs: [quotationId], limit: 1);
      return rows.isEmpty ? null : rows.first;
    } catch (e) {
      throw CacheException(message: 'Failed to read sync item: $e');
    }
  }

  @override
  Future<Map<String, int>> countsByStatus() async {
    try {
      final rows = await _db.rawQuery(
          'SELECT status, COUNT(*) AS c FROM sync_queue GROUP BY status');
      return {
        for (final row in rows)
          row['status'] as String: (row['c'] as num).toInt(),
      };
    } catch (e) {
      throw CacheException(message: 'Failed to count sync queue: $e');
    }
  }

  @override
  Future<void> deleteByQuotationId(String quotationId) async {
    try {
      await _db.delete('sync_queue',
          where: 'quotation_id = ?', whereArgs: [quotationId]);
    } catch (e) {
      throw CacheException(message: 'Failed to remove sync item: $e');
    }
  }
}
