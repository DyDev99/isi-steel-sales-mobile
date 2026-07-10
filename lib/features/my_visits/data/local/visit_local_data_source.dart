import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/routes_database.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/check_in_record_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/check_out_record_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/visit_capture_models.dart';
import 'package:sqflite/sqflite.dart';

/// Tables that carry a `sync_status` column (added in the routes.db v1->v2
/// migration) — every visit-capture table except the sync watermark/route
/// tables. Used by [VisitLocalDataSourceImpl.countPendingVisitRecords].
const visitCaptureSyncTables = [
  'checkins',
  'checkouts',
  'visit_orders',
  'visit_stock_updates',
  'visit_returns',
  'visit_collections',
  'visit_notes',
  'visit_photos',
];

abstract interface class VisitLocalDataSource {
  Future<void> insertCheckIn(CheckInRecordModel record);
  Future<void> insertCheckOut(CheckOutRecordModel record);

  Future<void> insertOrderLine(VisitOrderLineModel line);
  Future<void> insertStockUpdate(VisitStockUpdateModel update);
  Future<void> insertReturn(VisitReturnModel returnItem);
  Future<void> insertCollection(VisitCollectionModel collection);
  Future<void> insertNote(VisitNoteModel note);
  Future<void> insertPhoto(VisitPhotoModel photo);

  Future<List<VisitOrderLineModel>> fetchOrderLines(String stopId);
  Future<List<VisitStockUpdateModel>> fetchStockUpdates(String stopId);
  Future<List<VisitReturnModel>> fetchReturns(String stopId);
  Future<List<VisitCollectionModel>> fetchCollections(String stopId);
  Future<List<VisitNoteModel>> fetchNotes(String stopId);
  Future<List<VisitPhotoModel>> fetchPhotos(String stopId);

  /// One `sync_status = 'pending'` query per table — used to build a push
  /// batch. Kept per-table-typed (not a generic row list) since the sync
  /// repository needs real models to build the [VisitPushBatch] DTO.
  Future<List<CheckInRecordModel>> fetchPendingCheckIns();
  Future<List<CheckOutRecordModel>> fetchPendingCheckOuts();
  Future<List<VisitOrderLineModel>> fetchPendingOrderLines();
  Future<List<VisitStockUpdateModel>> fetchPendingStockUpdates();
  Future<List<VisitReturnModel>> fetchPendingReturns();
  Future<List<VisitCollectionModel>> fetchPendingCollections();
  Future<List<VisitNoteModel>> fetchPendingNotes();
  Future<List<VisitPhotoModel>> fetchPendingPhotos();

  /// Flips `sync_status` to `'synced'` for the given row [ids] in [table].
  /// Generic-by-table-name since the update itself is table-agnostic.
  Future<void> markSynced({required String table, required List<String> ids});

  /// Total row count with `sync_status = 'pending'` across every
  /// visit-capture table — drives the debug pending-sync indicator.
  Future<int> countPendingVisitRecords();
}

class VisitLocalDataSourceImpl implements VisitLocalDataSource {
  const VisitLocalDataSourceImpl(this._routesDb);
  final RoutesDatabase _routesDb;
  Database get _db => _routesDb.db;

  @override
  Future<void> insertCheckIn(CheckInRecordModel record) async {
    try {
      await _db.insert('checkins', record.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save check-in: $e');
    }
  }

  @override
  Future<void> insertCheckOut(CheckOutRecordModel record) async {
    try {
      await _db.insert('checkouts', record.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save check-out: $e');
    }
  }

  @override
  Future<void> insertOrderLine(VisitOrderLineModel line) async {
    try {
      await _db.insert('visit_orders', line.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save order: $e');
    }
  }

  @override
  Future<void> insertStockUpdate(VisitStockUpdateModel update) async {
    try {
      await _db.insert('visit_stock_updates', update.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save stock update: $e');
    }
  }

  @override
  Future<void> insertReturn(VisitReturnModel returnItem) async {
    try {
      await _db.insert('visit_returns', returnItem.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save return: $e');
    }
  }

  @override
  Future<void> insertCollection(VisitCollectionModel collection) async {
    try {
      await _db.insert('visit_collections', collection.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save collection: $e');
    }
  }

  @override
  Future<void> insertNote(VisitNoteModel note) async {
    try {
      await _db.insert('visit_notes', note.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save note: $e');
    }
  }

  @override
  Future<void> insertPhoto(VisitPhotoModel photo) async {
    try {
      await _db.insert('visit_photos', photo.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save photo: $e');
    }
  }

  @override
  Future<List<VisitOrderLineModel>> fetchOrderLines(String stopId) async {
    try {
      final rows = await _db
          .query('visit_orders', where: 'stop_id = ?', whereArgs: [stopId]);
      return rows.map(VisitOrderLineModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load orders: $e');
    }
  }

  @override
  Future<List<VisitStockUpdateModel>> fetchStockUpdates(String stopId) async {
    try {
      final rows = await _db.query('visit_stock_updates',
          where: 'stop_id = ?', whereArgs: [stopId]);
      return rows.map(VisitStockUpdateModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load stock updates: $e');
    }
  }

  @override
  Future<List<VisitReturnModel>> fetchReturns(String stopId) async {
    try {
      final rows = await _db
          .query('visit_returns', where: 'stop_id = ?', whereArgs: [stopId]);
      return rows.map(VisitReturnModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load returns: $e');
    }
  }

  @override
  Future<List<VisitCollectionModel>> fetchCollections(String stopId) async {
    try {
      final rows = await _db.query('visit_collections',
          where: 'stop_id = ?', whereArgs: [stopId]);
      return rows.map(VisitCollectionModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load collections: $e');
    }
  }

  @override
  Future<List<VisitNoteModel>> fetchNotes(String stopId) async {
    try {
      final rows = await _db.query('visit_notes',
          where: 'stop_id = ?',
          whereArgs: [stopId],
          orderBy: 'created_at DESC');
      return rows.map(VisitNoteModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load notes: $e');
    }
  }

  @override
  Future<List<VisitPhotoModel>> fetchPhotos(String stopId) async {
    try {
      final rows = await _db.query('visit_photos',
          where: 'stop_id = ?', whereArgs: [stopId], orderBy: 'taken_at DESC');
      return rows.map(VisitPhotoModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load photos: $e');
    }
  }

  Future<List<Map<String, Object?>>> _fetchPendingRows(String table) =>
      _db.query(table, where: "sync_status = 'pending'");

  @override
  Future<List<CheckInRecordModel>> fetchPendingCheckIns() async {
    try {
      final rows = await _fetchPendingRows('checkins');
      return rows.map(CheckInRecordModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load pending check-ins: $e');
    }
  }

  @override
  Future<List<CheckOutRecordModel>> fetchPendingCheckOuts() async {
    try {
      final rows = await _fetchPendingRows('checkouts');
      return rows.map(CheckOutRecordModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load pending check-outs: $e');
    }
  }

  @override
  Future<List<VisitOrderLineModel>> fetchPendingOrderLines() async {
    try {
      final rows = await _fetchPendingRows('visit_orders');
      return rows.map(VisitOrderLineModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load pending orders: $e');
    }
  }

  @override
  Future<List<VisitStockUpdateModel>> fetchPendingStockUpdates() async {
    try {
      final rows = await _fetchPendingRows('visit_stock_updates');
      return rows.map(VisitStockUpdateModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load pending stock updates: $e');
    }
  }

  @override
  Future<List<VisitReturnModel>> fetchPendingReturns() async {
    try {
      final rows = await _fetchPendingRows('visit_returns');
      return rows.map(VisitReturnModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load pending returns: $e');
    }
  }

  @override
  Future<List<VisitCollectionModel>> fetchPendingCollections() async {
    try {
      final rows = await _fetchPendingRows('visit_collections');
      return rows.map(VisitCollectionModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load pending collections: $e');
    }
  }

  @override
  Future<List<VisitNoteModel>> fetchPendingNotes() async {
    try {
      final rows = await _fetchPendingRows('visit_notes');
      return rows.map(VisitNoteModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load pending notes: $e');
    }
  }

  @override
  Future<List<VisitPhotoModel>> fetchPendingPhotos() async {
    try {
      final rows = await _fetchPendingRows('visit_photos');
      return rows.map(VisitPhotoModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load pending photos: $e');
    }
  }

  @override
  Future<void> markSynced(
      {required String table, required List<String> ids}) async {
    if (ids.isEmpty) return;
    try {
      final placeholders = List.filled(ids.length, '?').join(',');
      await _db.update(
        table,
        {'sync_status': 'synced'},
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to mark rows synced in $table: $e');
    }
  }

  @override
  Future<int> countPendingVisitRecords() async {
    try {
      var total = 0;
      for (final table in visitCaptureSyncTables) {
        final result = await _db.rawQuery(
            "SELECT COUNT(*) AS c FROM $table WHERE sync_status = 'pending'");
        total += (result.first['c'] as int?) ?? 0;
      }
      return total;
    } catch (e) {
      throw CacheException(
          message: 'Failed to count pending visit records: $e');
    }
  }
}
