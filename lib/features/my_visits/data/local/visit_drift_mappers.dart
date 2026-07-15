import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/visit_dao.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/check_in_record_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/check_out_record_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/visit_capture_models.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_collection.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_note.dart';

/// Drift row ↔ model mappers for visit captures (T1.5 cutover).
///
/// Mappers are the only code aware of Drift row/companion shapes (ADR-003
/// point 2). Two naming shifts are handled here and nowhere else:
/// `visit_notes.text` → `body` (it would shadow Drift's `text()` builder) and
/// `visit_photos.url` → `path` (the value is a filesystem reference, not a URL —
/// `docs/ARCHITECTURE.md` §3 Layer 4).
///
/// Enum decoding always falls back rather than throwing: a capture is a rep's
/// irreplaceable field observation, and a value this build doesn't recognise is
/// a reason to show it imperfectly, never a reason to lose it.

/// Maps the legacy table-name strings the sync repository still uses onto the
/// typed [VisitCaptureTable].
///
/// The push batch (`visit_push_batch.dart`) keys accepted ids by these names,
/// and that contract is shared with the (mocked) SAP payload — so it is not
/// this cutover's business to change. The unsafe part was the *DAO* taking a
/// raw string; that is now typed, and this is the one place the translation
/// happens.
VisitCaptureTable? visitCaptureTableFromLegacyName(String table) =>
    switch (table) {
      'checkins' => VisitCaptureTable.checkIns,
      'checkouts' => VisitCaptureTable.checkOuts,
      'visit_orders' => VisitCaptureTable.orderLines,
      'visit_stock_updates' => VisitCaptureTable.stockUpdates,
      'visit_returns' => VisitCaptureTable.returns,
      'visit_collections' => VisitCaptureTable.collections,
      'visit_notes' => VisitCaptureTable.notes,
      'visit_photos' => VisitCaptureTable.photos,
      _ => null,
    };

// ── Check-in / check-out ──────────────────────────────────────────────

extension VisitCheckInRowMapper on VisitCheckInRow {
  CheckInRecordModel toModel() => CheckInRecordModel(
        id: id,
        stopId: stopId,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracy,
        distanceFromCustomerMeters: distanceFromCustomer,
        isMocked: isMocked,
      );
}

extension CheckInRecordModelMapper on CheckInRecordModel {
  VisitCheckInsCompanion toCompanion() => VisitCheckInsCompanion.insert(
        id: id,
        stopId: stopId,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracyMeters,
        distanceFromCustomer: distanceFromCustomerMeters,
        isMocked: Value(isMocked),
      );
}

extension VisitCheckOutRowMapper on VisitCheckOutRow {
  CheckOutRecordModel toModel() => CheckOutRecordModel(
        id: id,
        stopId: stopId,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        durationMinutes: durationMinutes,
        visitSummary: visitSummary,
      );
}

extension CheckOutRecordModelMapper on CheckOutRecordModel {
  VisitCheckOutsCompanion toCompanion() => VisitCheckOutsCompanion.insert(
        id: id,
        stopId: stopId,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        durationMinutes: durationMinutes,
        visitSummary: visitSummary,
      );
}

// ── Order lines ───────────────────────────────────────────────────────

extension VisitOrderLineRowMapper on VisitOrderLineRow {
  VisitOrderLineModel toModel() => VisitOrderLineModel(
        id: id,
        stopId: stopId,
        productId: productId,
        productName: productName,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
      );
}

extension VisitOrderLineModelMapper on VisitOrderLineModel {
  VisitOrderLinesCompanion toCompanion() => VisitOrderLinesCompanion.insert(
        id: id,
        stopId: stopId,
        productId: productId,
        productName: productName,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
      );
}

// ── Stock updates ─────────────────────────────────────────────────────

extension VisitStockUpdateRowMapper on VisitStockUpdateRow {
  VisitStockUpdateModel toModel() => VisitStockUpdateModel(
        id: id,
        stopId: stopId,
        productId: productId,
        productName: productName,
        countedQuantity: countedQuantity,
        notes: notes,
      );
}

extension VisitStockUpdateModelMapper on VisitStockUpdateModel {
  VisitStockUpdatesCompanion toCompanion() => VisitStockUpdatesCompanion.insert(
        id: id,
        stopId: stopId,
        productId: productId,
        productName: productName,
        countedQuantity: countedQuantity,
        notes: Value(notes),
      );
}

// ── Returns ───────────────────────────────────────────────────────────

extension VisitReturnRowMapper on VisitReturnRow {
  VisitReturnModel toModel() => VisitReturnModel(
        id: id,
        stopId: stopId,
        productId: productId,
        productName: productName,
        quantity: quantity,
        reason: reason,
      );
}

extension VisitReturnModelMapper on VisitReturnModel {
  VisitReturnsCompanion toCompanion() => VisitReturnsCompanion.insert(
        id: id,
        stopId: stopId,
        productId: productId,
        productName: productName,
        quantity: quantity,
        reason: reason,
      );
}

// ── Collections ───────────────────────────────────────────────────────

extension VisitCollectionRowMapper on VisitCollectionRow {
  VisitCollectionModel toModel() => VisitCollectionModel(
        id: id,
        stopId: stopId,
        amount: amount,
        // Money that was physically collected. An unrecognised method must not
        // discard the record — the cash exists regardless of the label.
        method: CollectionMethod.values.asNameMap()[method] ??
            CollectionMethod.values.first,
        reference: reference,
        notes: notes,
      );
}

extension VisitCollectionModelMapper on VisitCollectionModel {
  VisitCollectionsCompanion toCompanion() => VisitCollectionsCompanion.insert(
        id: id,
        stopId: stopId,
        amount: amount,
        method: method.name,
        reference: Value(reference),
        notes: Value(notes),
      );
}

// ── Notes ─────────────────────────────────────────────────────────────

extension VisitNoteRowMapper on VisitNoteRow {
  VisitNoteModel toModel() => VisitNoteModel(
        id: id,
        stopId: stopId,
        type: VisitNoteType.values.asNameMap()[type] ??
            VisitNoteType.values.first,
        text: body,
        createdAt: createdAt,
      );
}

extension VisitNoteModelMapper on VisitNoteModel {
  VisitNotesCompanion toCompanion() => VisitNotesCompanion.insert(
        id: id,
        stopId: stopId,
        type: type.name,
        body: text,
        createdAt: createdAt,
      );
}

// ── Photos ────────────────────────────────────────────────────────────

extension VisitPhotoRowMapper on VisitPhotoRow {
  VisitPhotoModel toModel() => VisitPhotoModel(
        id: id,
        stopId: stopId,
        url: path,
        caption: caption,
        takenAt: takenAt,
        isSignature: isSignature,
      );
}

extension VisitPhotoModelMapper on VisitPhotoModel {
  VisitPhotosCompanion toCompanion() => VisitPhotosCompanion.insert(
        id: id,
        stopId: stopId,
        path: url,
        caption: Value(caption),
        takenAt: takenAt,
        isSignature: Value(isSignature),
      );
}
