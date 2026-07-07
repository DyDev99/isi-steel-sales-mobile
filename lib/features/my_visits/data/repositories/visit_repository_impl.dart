import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/visit_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/check_in_record_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/check_out_record_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/visit_capture_models.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/check_in_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/check_out_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_collection.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_note.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_order_line.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_return.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_stock_update.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_repository.dart';

class VisitRepositoryImpl implements VisitRepository {
  const VisitRepositoryImpl(this._local);
  final VisitLocalDataSource _local;

  @override
  ResultFuture<CheckInRecord> checkIn(CheckInRecord record) async {
    try {
      final model = CheckInRecordModel.fromEntity(record);
      await _local.insertCheckIn(model);
      return Success(model);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<CheckOutRecord> checkOut(CheckOutRecord record) async {
    try {
      final model = CheckOutRecordModel.fromEntity(record);
      await _local.insertCheckOut(model);
      return Success(model);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> addOrderLine(VisitOrderLine line) async {
    try {
      await _local.insertOrderLine(VisitOrderLineModel(
        id: line.id,
        stopId: line.stopId,
        productId: line.productId,
        productName: line.productName,
        quantity: line.quantity,
        unit: line.unit,
        unitPrice: line.unitPrice,
      ));
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> addStockUpdate(VisitStockUpdate update) async {
    try {
      await _local.insertStockUpdate(VisitStockUpdateModel(
        id: update.id,
        stopId: update.stopId,
        productId: update.productId,
        productName: update.productName,
        countedQuantity: update.countedQuantity,
        notes: update.notes,
      ));
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> addReturn(VisitReturn returnItem) async {
    try {
      await _local.insertReturn(VisitReturnModel(
        id: returnItem.id,
        stopId: returnItem.stopId,
        productId: returnItem.productId,
        productName: returnItem.productName,
        quantity: returnItem.quantity,
        reason: returnItem.reason,
      ));
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> addCollection(VisitCollection collection) async {
    try {
      await _local.insertCollection(VisitCollectionModel(
        id: collection.id,
        stopId: collection.stopId,
        amount: collection.amount,
        method: collection.method,
        reference: collection.reference,
        notes: collection.notes,
      ));
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> addNote(VisitNote note) async {
    try {
      await _local.insertNote(VisitNoteModel(
        id: note.id,
        stopId: note.stopId,
        type: note.type,
        text: note.text,
        createdAt: note.createdAt,
      ));
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> addPhoto(VisitPhoto photo) async {
    try {
      await _local.insertPhoto(VisitPhotoModel(
        id: photo.id,
        stopId: photo.stopId,
        url: photo.url,
        caption: photo.caption,
        takenAt: photo.takenAt,
        isSignature: photo.isSignature,
      ));
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<VisitOrderLine>> fetchOrderLines(String stopId) async {
    try {
      return Success(await _local.fetchOrderLines(stopId));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<VisitStockUpdate>> fetchStockUpdates(String stopId) async {
    try {
      return Success(await _local.fetchStockUpdates(stopId));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<VisitReturn>> fetchReturns(String stopId) async {
    try {
      return Success(await _local.fetchReturns(stopId));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<VisitCollection>> fetchCollections(String stopId) async {
    try {
      return Success(await _local.fetchCollections(stopId));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<VisitNote>> fetchNotes(String stopId) async {
    try {
      return Success(await _local.fetchNotes(stopId));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<VisitPhoto>> fetchPhotos(String stopId) async {
    try {
      return Success(await _local.fetchPhotos(stopId));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }
}
