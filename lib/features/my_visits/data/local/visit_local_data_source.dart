import 'package:isi_steel_sales_mobile/features/my_visits/data/models/check_in_record_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/check_out_record_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/visit_capture_models.dart';

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

// ─────────────────────────────────────────────────────────────────────────────
// The legacy sqflite `VisitLocalDataSourceImpl` was removed by T1.5b.
//
// It had been retained-but-unregistered as a rollback path after the T1.5 Drift
// cutover. T1.5b removes the last reader of the plaintext `routes.db`, so the
// rollback target no longer exists — and because it imported `sqflite`, which
// has no web implementation, keeping dead code here would have blocked the web
// target permanently (`docs/blueprint/web-architecture.md`).
//
// The live implementation is `VisitDriftLocalDataSource`, registered in
// `my_visits_injection.dart`. The deleted class remains in git history.
// ─────────────────────────────────────────────────────────────────────────────
