import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/order_tables.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';

part 'order_dao.g.dart';

/// Scoped accessors for the Orders domain (**T1.5b**), one per aggregate as
/// ADR-004 requires.
///
/// ## Why these read and write raw [DataMap] rows
///
/// Same reason as `CartDao`: the Orders repositories already speak snake_case
/// row maps, and this port's contract is that nothing above the datasource
/// changes. `customSelect` hands back exactly the column names the old
/// `sqflite` queries produced, so the repositories cannot tell the difference.
///
/// Writes go through [_upsert], which builds an `INSERT OR REPLACE` from an
/// explicit column list rather than a typed companion. That is a deliberate
/// trade: a companion mapping would need ~60 lines of field-by-field code per
/// table to restate a contract the caller already satisfies, and every one of
/// those lines would be a chance to silently drop a column during the cutover.
/// The explicit column list keeps the row contract visible in one place and
/// makes a missing column a loud failure instead of a quiet null.
///
/// `INSERT OR REPLACE` reproduces `ConflictAlgorithm.replace` from the sqflite
/// original exactly — including its semantics on partial rows, where omitted
/// columns revert to defaults rather than retaining prior values.
mixin _RowUpsert on DatabaseAccessor<AppDatabase> {
  /// Writes [row] into [table], replacing any row with the same primary key.
  /// [columns] fixes both the order and the accepted key set.
  Future<void> upsertRow(
    String table,
    List<String> columns,
    DataMap row,
  ) async {
    final placeholders = List.filled(columns.length, '?').join(', ');
    await customInsert(
      'INSERT OR REPLACE INTO $table (${columns.join(', ')}) '
      'VALUES ($placeholders)',
      variables: [for (final c in columns) Variable(row[c])],
    );
  }
}

/// Quotations: create/update/delete plus the list read behind "My Quotations".
@DriftAccessor(tables: [Quotations])
class QuotationDao extends DatabaseAccessor<AppDatabase>
    with _$QuotationDaoMixin, _RowUpsert {
  QuotationDao(super.db);

  static const columns = <String>[
    'id',
    'customer_id',
    'shop_name',
    'lead_id',
    'lead_display_name',
    'lines_json',
    'subtotal',
    'discount',
    'tax',
    'total',
    'status',
    'off_visit_reason',
    'gps_lat',
    'gps_lng',
    'sap_draft_status',
    'valid_until',
    'created_at',
    'updated_at',
  ];

  Future<void> upsert(DataMap row) => upsertRow('quotations', columns, row);

  /// Partial update by primary key. Unlike [upsert] this preserves columns the
  /// caller did not supply, matching sqflite's `update` (which the quotation
  /// repository relies on when it patches only `status`/`updated_at`).
  Future<void> updateRow(DataMap row) async {
    final keys = row.keys.where((k) => k != 'id' && columns.contains(k));
    if (keys.isEmpty) return;
    final assignments = keys.map((k) => '$k = ?').join(', ');
    await customUpdate(
      'UPDATE quotations SET $assignments WHERE id = ?',
      variables: [
        for (final k in keys) Variable(row[k]),
        Variable(row['id']),
      ],
      updates: {quotations},
    );
  }

  Future<void> deleteById(String id) =>
      (delete(quotations)..where((t) => t.id.equals(id))).go();

  Future<DataMap?> getById(String id) async {
    final rows = await customSelect(
      'SELECT * FROM quotations WHERE id = ? LIMIT 1',
      variables: [Variable(id)],
      readsFrom: {quotations},
    ).get();
    return rows.isEmpty ? null : rows.first.data;
  }

  Future<List<DataMap>> fetchAll() async {
    final rows = await customSelect(
      'SELECT * FROM quotations ORDER BY created_at DESC',
      readsFrom: {quotations},
    ).get();
    return rows.map((r) => r.data).toList();
  }
}

/// Sales orders: insert-only from the app's side; SAP owns their lifecycle.
@DriftAccessor(tables: [SalesOrders])
class SalesOrderDao extends DatabaseAccessor<AppDatabase>
    with _$SalesOrderDaoMixin, _RowUpsert {
  SalesOrderDao(super.db);

  static const columns = <String>[
    'id',
    'quotation_id',
    'customer_id',
    'shop_name',
    'lead_id',
    'lead_display_name',
    'lines_json',
    'subtotal',
    'discount',
    'tax',
    'total',
    'status',
    'off_visit_reason',
    'sap_status',
    'created_at',
  ];

  Future<void> upsert(DataMap row) => upsertRow('sales_orders', columns, row);

  Future<DataMap?> getById(String id) async {
    final rows = await customSelect(
      'SELECT * FROM sales_orders WHERE id = ? LIMIT 1',
      variables: [Variable(id)],
      readsFrom: {salesOrders},
    ).get();
    return rows.isEmpty ? null : rows.first.data;
  }

  Future<List<DataMap>> fetchAll() async {
    final rows = await customSelect(
      'SELECT * FROM sales_orders ORDER BY created_at DESC',
      readsFrom: {salesOrders},
    ).get();
    return rows.map((r) => r.data).toList();
  }
}

/// The Orders feature's outbound sync queue.
///
/// Still the feature-local queue, not ADR-006's unified engine — see the note
/// on the [SyncQueue] table. Its move into the encrypted database is what makes
/// that later promotion a refactor rather than a second field-data migration.
@DriftAccessor(tables: [SyncQueue, Quotations])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin, _RowUpsert {
  SyncQueueDao(super.db);

  static const columns = <String>[
    'id',
    'quotation_id',
    'status',
    'attempt_count',
    'next_retry_at',
    'last_error',
    'error_code',
    'sap_document_number',
    'sap_message',
    'sap_timestamp',
    'sync_duration_ms',
    'created_at',
    'updated_at',
  ];

  /// Column list copied verbatim from the sqflite original: the joined shape is
  /// consumed positionally-by-name by the queue UI, so aliases matter.
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

  Future<void> upsert(DataMap row) => upsertRow('sync_queue', columns, row);

  Future<List<DataMap>> fetchAllJoined() async {
    final rows = await customSelect(
      _joinSql,
      readsFrom: {syncQueue, quotations},
    ).get();
    return rows.map((r) => r.data).toList();
  }

  /// Rows eligible now: `pendingSync` whose backoff has elapsed, FIFO.
  Future<List<DataMap>> fetchReady(String nowIso) async {
    final rows = await customSelect(
      'SELECT * FROM sync_queue '
      'WHERE status = ? AND (next_retry_at IS NULL OR next_retry_at <= ?) '
      'ORDER BY created_at ASC',
      variables: [Variable('pendingSync'), Variable(nowIso)],
      readsFrom: {syncQueue},
    ).get();
    return rows.map((r) => r.data).toList();
  }

  Future<DataMap?> getByQuotationId(String quotationId) async {
    final rows = await customSelect(
      'SELECT * FROM sync_queue WHERE quotation_id = ? LIMIT 1',
      variables: [Variable(quotationId)],
      readsFrom: {syncQueue},
    ).get();
    return rows.isEmpty ? null : rows.first.data;
  }

  Future<Map<String, int>> countsByStatus() async {
    final rows = await customSelect(
      'SELECT status, COUNT(*) AS c FROM sync_queue GROUP BY status',
      readsFrom: {syncQueue},
    ).get();
    return {
      for (final row in rows)
        row.data['status'] as String: (row.data['c'] as num).toInt(),
    };
  }

  Future<void> deleteByQuotationId(String quotationId) =>
      (delete(syncQueue)..where((t) => t.quotationId.equals(quotationId))).go();
}
