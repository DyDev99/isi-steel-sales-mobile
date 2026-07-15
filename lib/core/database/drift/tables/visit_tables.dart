import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/route_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/syncable_table.dart';

/// Visit captures — everything a rep records at a stop. Ported from the legacy
/// plaintext `routes.db` into the single encrypted database (ADR-001, T1.5).
///
/// All of these are **first-hand field captures**, which
/// `docs/SYNC_ENGINE.md` §5 classifies as *client-authoritative*: the server has
/// no competing version of an observation the rep made, so they push rather than
/// merge. They still carry the full §3.1 column set because they participate in
/// sync — a capture that never reaches SAP is a lost sale, and losing one is the
/// failure mode the whole offline design exists to prevent.
///
/// Every table cascades from [RouteStops]: a stop's captures are meaningless
/// without the stop, and the FK makes that structural rather than conventional.

/// Arrival at a stop. Unique per stop — a rep checks in once.
@TableIndex(name: 'idx_visit_check_ins_stop', columns: {#stopId}, unique: true)
@DataClassName('VisitCheckInRow')
class VisitCheckIns extends Table with SyncableTable {
  @override
  String get tableName => 'visit_check_ins';

  TextColumn get stopId =>
      text().references(RouteStops, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real()();

  /// Metres between the rep and the customer's registered location — the input
  /// to the geofence rule, retained for audit.
  RealColumn get distanceFromCustomer => real()();
  BoolColumn get isMocked => boolean().withDefault(const Constant(false))();
}

/// Departure from a stop. Unique per stop.
@TableIndex(name: 'idx_visit_check_outs_stop', columns: {#stopId}, unique: true)
@DataClassName('VisitCheckOutRow')
class VisitCheckOuts extends Table with SyncableTable {
  @override
  String get tableName => 'visit_check_outs';

  TextColumn get stopId =>
      text().references(RouteStops, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get durationMinutes => integer()();
  TextColumn get visitSummary => text()();
}

/// Order lines captured during a visit.
///
/// [unitPrice] is denormalised deliberately: it records the price *as quoted at
/// the visit*, which must not silently change if the catalog is re-synced
/// afterwards. Server-side divergence on price is a conflict routed to
/// Action-Required, never an in-place overwrite (`docs/SYNC_ENGINE.md` §5).
@TableIndex(name: 'idx_visit_order_lines_stop', columns: {#stopId})
@DataClassName('VisitOrderLineRow')
class VisitOrderLines extends Table with SyncableTable {
  @override
  String get tableName => 'visit_order_lines';

  TextColumn get stopId =>
      text().references(RouteStops, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text()();

  /// Denormalised at capture time so a historical line still renders if the
  /// product is later delisted from the catalog.
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  RealColumn get unitPrice => real()();
}

/// Shelf/stock counts taken at a stop.
@TableIndex(name: 'idx_visit_stock_updates_stop', columns: {#stopId})
@DataClassName('VisitStockUpdateRow')
class VisitStockUpdates extends Table with SyncableTable {
  @override
  String get tableName => 'visit_stock_updates';

  TextColumn get stopId =>
      text().references(RouteStops, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get countedQuantity => real()();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

/// Goods returned by the customer during a visit.
@TableIndex(name: 'idx_visit_returns_stop', columns: {#stopId})
@DataClassName('VisitReturnRow')
class VisitReturns extends Table with SyncableTable {
  @override
  String get tableName => 'visit_returns';

  TextColumn get stopId =>
      text().references(RouteStops, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  TextColumn get reason => text()();
}

/// Cash/cheque collected at a stop. Financial data — server-authoritative on
/// conflict (`docs/SYNC_ENGINE.md` §5).
@TableIndex(name: 'idx_visit_collections_stop', columns: {#stopId})
@DataClassName('VisitCollectionRow')
class VisitCollections extends Table with SyncableTable {
  @override
  String get tableName => 'visit_collections';

  TextColumn get stopId =>
      text().references(RouteStops, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  TextColumn get method => text()();
  TextColumn get reference => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

/// Free-text notes recorded at a stop.
@TableIndex(name: 'idx_visit_notes_stop', columns: {#stopId})
@DataClassName('VisitNoteRow')
class VisitNotes extends Table with SyncableTable {
  @override
  String get tableName => 'visit_notes';

  TextColumn get stopId =>
      text().references(RouteStops, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();

  /// The note itself. Named [body] in Dart because `text` would shadow Drift's
  /// own `text()` column builder; `.named('text')` keeps the SQL column name
  /// identical to the legacy sqflite table so the T1.5 import maps 1:1.
  TextColumn get body => text().named('text')();
  DateTimeColumn get createdAt => dateTime()();
}

/// Photo / signature evidence captured at a stop.
///
/// **Layer 4 boundary** (`docs/ARCHITECTURE.md` §3): this table stores only a
/// filesystem [path] — never the binary. Encrypting the referenced file itself
/// is the `core/database/files/encrypted_file_store.dart` deliverable
/// (`docs/MIGRATION_PLAN.md` §8, P0), so until that lands the *reference* is
/// encrypted here while the file on disk is not.
@TableIndex(name: 'idx_visit_photos_stop', columns: {#stopId})
@DataClassName('VisitPhotoRow')
class VisitPhotos extends Table with SyncableTable {
  @override
  String get tableName => 'visit_photos';

  TextColumn get stopId =>
      text().references(RouteStops, #id, onDelete: KeyAction.cascade)();

  /// Filesystem path or remote URL. Legacy column was named `url`.
  // TODO(release-gate): the referenced file is not yet encrypted at rest —
  // blocked on the encrypted file store (MIGRATION_PLAN.md §8). Must not ship
  // to production as-is (SECURITY.md §11 release checklist).
  TextColumn get path => text()();
  TextColumn get caption => text().withDefault(const Constant(''))();
  DateTimeColumn get takenAt => dateTime()();
  BoolColumn get isSignature => boolean().withDefault(const Constant(false))();
}
