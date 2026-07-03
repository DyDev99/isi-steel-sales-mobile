import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/local/routes_database.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/models/check_in_record_model.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/models/check_out_record_model.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/models/visit_capture_models.dart';
import 'package:sqflite/sqflite.dart';

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
}

class VisitLocalDataSourceImpl implements VisitLocalDataSource {
  const VisitLocalDataSourceImpl(this._routesDb);
  final RoutesDatabase _routesDb;
  Database get _db => _routesDb.db;

  @override
  Future<void> insertCheckIn(CheckInRecordModel record) async {
    try {
      await _db.insert('checkins', record.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save check-in: $e');
    }
  }

  @override
  Future<void> insertCheckOut(CheckOutRecordModel record) async {
    try {
      await _db.insert('checkouts', record.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save check-out: $e');
    }
  }

  @override
  Future<void> insertOrderLine(VisitOrderLineModel line) async {
    try {
      await _db.insert('visit_orders', line.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save order: $e');
    }
  }

  @override
  Future<void> insertStockUpdate(VisitStockUpdateModel update) async {
    try {
      await _db.insert('visit_stock_updates', update.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save stock update: $e');
    }
  }

  @override
  Future<void> insertReturn(VisitReturnModel returnItem) async {
    try {
      await _db.insert('visit_returns', returnItem.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save return: $e');
    }
  }

  @override
  Future<void> insertCollection(VisitCollectionModel collection) async {
    try {
      await _db.insert('visit_collections', collection.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save collection: $e');
    }
  }

  @override
  Future<void> insertNote(VisitNoteModel note) async {
    try {
      await _db.insert('visit_notes', note.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save note: $e');
    }
  }

  @override
  Future<void> insertPhoto(VisitPhotoModel photo) async {
    try {
      await _db.insert('visit_photos', photo.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save photo: $e');
    }
  }

  @override
  Future<List<VisitOrderLineModel>> fetchOrderLines(String stopId) async {
    try {
      final rows = await _db.query('visit_orders', where: 'stop_id = ?', whereArgs: [stopId]);
      return rows.map(VisitOrderLineModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load orders: $e');
    }
  }

  @override
  Future<List<VisitStockUpdateModel>> fetchStockUpdates(String stopId) async {
    try {
      final rows = await _db.query('visit_stock_updates', where: 'stop_id = ?', whereArgs: [stopId]);
      return rows.map(VisitStockUpdateModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load stock updates: $e');
    }
  }

  @override
  Future<List<VisitReturnModel>> fetchReturns(String stopId) async {
    try {
      final rows = await _db.query('visit_returns', where: 'stop_id = ?', whereArgs: [stopId]);
      return rows.map(VisitReturnModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load returns: $e');
    }
  }

  @override
  Future<List<VisitCollectionModel>> fetchCollections(String stopId) async {
    try {
      final rows = await _db.query('visit_collections', where: 'stop_id = ?', whereArgs: [stopId]);
      return rows.map(VisitCollectionModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load collections: $e');
    }
  }

  @override
  Future<List<VisitNoteModel>> fetchNotes(String stopId) async {
    try {
      final rows = await _db.query('visit_notes', where: 'stop_id = ?', whereArgs: [stopId], orderBy: 'created_at DESC');
      return rows.map(VisitNoteModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load notes: $e');
    }
  }

  @override
  Future<List<VisitPhotoModel>> fetchPhotos(String stopId) async {
    try {
      final rows = await _db.query('visit_photos', where: 'stop_id = ?', whereArgs: [stopId], orderBy: 'taken_at DESC');
      return rows.map(VisitPhotoModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load photos: $e');
    }
  }
}
