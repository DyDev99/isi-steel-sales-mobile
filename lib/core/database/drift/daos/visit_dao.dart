import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/syncable_table.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/visit_tables.dart';

part 'visit_dao.g.dart';

/// The visit-capture tables, as a typed enum rather than raw table-name strings.
///
/// The legacy data source took a `String table` for `markSynced`, which a typo
/// turns into a silent no-op — the rows stay `dirty` and get pushed forever, or
/// worse, the wrong table gets marked. Making the set closed means the compiler
/// checks it (ADR-004's whole rationale).
enum VisitCaptureTable {
  checkIns,
  checkOuts,
  orderLines,
  stockUpdates,
  returns,
  collections,
  notes,
  photos,
}

/// Everything a rep records at a stop.
///
/// Replaces the hand-written SQL in
/// `my_visits/data/local/visit_local_data_source.dart` (ADR-004).
///
/// **These rows are the most valuable data in the app**: a capture that never
/// reaches SAP is a lost order or an uncollected payment. Two rules follow, and
/// every method here is shaped by them:
///
/// 1. Nothing is marked `synced` until the server confirms it
///    (`docs/SYNC_ENGINE.md` §3) — never speculatively.
/// 2. Writes are transaction-composable so the repository can wrap the mutation
///    and its sync-queue row in one transaction (ADR-006, ADR-003 point 3). The
///    DAO does not decide sync policy.
@DriftAccessor(
  tables: [
    VisitCheckIns,
    VisitCheckOuts,
    VisitOrderLines,
    VisitStockUpdates,
    VisitReturns,
    VisitCollections,
    VisitNotes,
    VisitPhotos,
  ],
)
class VisitDao extends DatabaseAccessor<AppDatabase> with _$VisitDaoMixin {
  VisitDao(super.db);

  // ── Check-in / check-out (one per stop, enforced by a unique index) ──

  Future<void> upsertCheckIn(VisitCheckInsCompanion record) =>
      into(visitCheckIns).insertOnConflictUpdate(record);

  Future<void> upsertCheckOut(VisitCheckOutsCompanion record) =>
      into(visitCheckOuts).insertOnConflictUpdate(record);

  Future<VisitCheckInRow?> getCheckIn(String stopId) =>
      (select(visitCheckIns)..where((t) => t.stopId.equals(stopId)))
          .getSingleOrNull();

  Future<VisitCheckOutRow?> getCheckOut(String stopId) =>
      (select(visitCheckOuts)..where((t) => t.stopId.equals(stopId)))
          .getSingleOrNull();

  // ── Captures: insert ────────────────────────────────────────────────

  Future<void> insertOrderLine(VisitOrderLinesCompanion line) =>
      into(visitOrderLines).insertOnConflictUpdate(line);

  Future<void> insertStockUpdate(VisitStockUpdatesCompanion update) =>
      into(visitStockUpdates).insertOnConflictUpdate(update);

  Future<void> insertReturn(VisitReturnsCompanion item) =>
      into(visitReturns).insertOnConflictUpdate(item);

  Future<void> insertCollection(VisitCollectionsCompanion collection) =>
      into(visitCollections).insertOnConflictUpdate(collection);

  Future<void> insertNote(VisitNotesCompanion note) =>
      into(visitNotes).insertOnConflictUpdate(note);

  Future<void> insertPhoto(VisitPhotosCompanion photo) =>
      into(visitPhotos).insertOnConflictUpdate(photo);

  // ── Captures: read by stop ──────────────────────────────────────────

  Future<List<VisitOrderLineRow>> fetchOrderLines(String stopId) =>
      (select(visitOrderLines)
            ..where((t) => t.stopId.equals(stopId))
            ..where((t) => t.deleted.equals(false)))
          .get();

  Future<List<VisitStockUpdateRow>> fetchStockUpdates(String stopId) =>
      (select(visitStockUpdates)
            ..where((t) => t.stopId.equals(stopId))
            ..where((t) => t.deleted.equals(false)))
          .get();

  Future<List<VisitReturnRow>> fetchReturns(String stopId) =>
      (select(visitReturns)
            ..where((t) => t.stopId.equals(stopId))
            ..where((t) => t.deleted.equals(false)))
          .get();

  Future<List<VisitCollectionRow>> fetchCollections(String stopId) =>
      (select(visitCollections)
            ..where((t) => t.stopId.equals(stopId))
            ..where((t) => t.deleted.equals(false)))
          .get();

  Future<List<VisitNoteRow>> fetchNotes(String stopId) => (select(visitNotes)
        ..where((t) => t.stopId.equals(stopId))
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();

  Future<List<VisitPhotoRow>> fetchPhotos(String stopId) => (select(visitPhotos)
        ..where((t) => t.stopId.equals(stopId))
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]))
      .get();

  // ── Push batch: pending rows ────────────────────────────────────────

  // Each query is spelled out with a typed `where` rather than routed through a
  // generic helper. A helper would need `(row as dynamic).syncState`, which
  // throws away exactly the compile-time checking ADR-004 adopted Drift for —
  // and `dynamic` where a typed model exists is prohibited outright
  // (`.claude/CLAUDE.md`). Repetition is the cheaper trade.
  //
  // Soft-deleted rows are **included** everywhere here: a delete still has to be
  // pushed before the row may be dropped (`docs/DATABASE_GUIDE.md` §3.1).

  Future<List<VisitCheckInRow>> fetchPendingCheckIns() => (select(visitCheckIns)
        ..where((t) => t.syncState.equals(SyncStates.dirty)))
      .get();

  Future<List<VisitCheckOutRow>> fetchPendingCheckOuts() =>
      (select(visitCheckOuts)
            ..where((t) => t.syncState.equals(SyncStates.dirty)))
          .get();

  Future<List<VisitOrderLineRow>> fetchPendingOrderLines() =>
      (select(visitOrderLines)
            ..where((t) => t.syncState.equals(SyncStates.dirty)))
          .get();

  Future<List<VisitStockUpdateRow>> fetchPendingStockUpdates() =>
      (select(visitStockUpdates)
            ..where((t) => t.syncState.equals(SyncStates.dirty)))
          .get();

  Future<List<VisitReturnRow>> fetchPendingReturns() =>
      (select(visitReturns)..where((t) => t.syncState.equals(SyncStates.dirty)))
          .get();

  Future<List<VisitCollectionRow>> fetchPendingCollections() =>
      (select(visitCollections)
            ..where((t) => t.syncState.equals(SyncStates.dirty)))
          .get();

  Future<List<VisitNoteRow>> fetchPendingNotes() =>
      (select(visitNotes)..where((t) => t.syncState.equals(SyncStates.dirty)))
          .get();

  Future<List<VisitPhotoRow>> fetchPendingPhotos() =>
      (select(visitPhotos)..where((t) => t.syncState.equals(SyncStates.dirty)))
          .get();

  // ── Post-push bookkeeping ───────────────────────────────────────────

  /// Flips [ids] in [table] to `synced`. Called only after the server confirms.
  ///
  /// Typed by [VisitCaptureTable] instead of a table-name string so an invalid
  /// target is a compile error rather than a silently-skipped update.
  Future<void> markSynced(VisitCaptureTable table, List<String> ids) {
    if (ids.isEmpty) return Future.value();
    const synced = Value(SyncStates.synced);
    const clean = Value(false);

    return switch (table) {
      VisitCaptureTable.checkIns =>
        (update(visitCheckIns)..where((t) => t.id.isIn(ids))).write(
          const VisitCheckInsCompanion(syncState: synced, dirty: clean),
        ),
      VisitCaptureTable.checkOuts =>
        (update(visitCheckOuts)..where((t) => t.id.isIn(ids))).write(
          const VisitCheckOutsCompanion(syncState: synced, dirty: clean),
        ),
      VisitCaptureTable.orderLines =>
        (update(visitOrderLines)..where((t) => t.id.isIn(ids))).write(
          const VisitOrderLinesCompanion(syncState: synced, dirty: clean),
        ),
      VisitCaptureTable.stockUpdates =>
        (update(visitStockUpdates)..where((t) => t.id.isIn(ids))).write(
          const VisitStockUpdatesCompanion(syncState: synced, dirty: clean),
        ),
      VisitCaptureTable.returns =>
        (update(visitReturns)..where((t) => t.id.isIn(ids))).write(
          const VisitReturnsCompanion(syncState: synced, dirty: clean),
        ),
      VisitCaptureTable.collections =>
        (update(visitCollections)..where((t) => t.id.isIn(ids))).write(
          const VisitCollectionsCompanion(syncState: synced, dirty: clean),
        ),
      VisitCaptureTable.notes =>
        (update(visitNotes)..where((t) => t.id.isIn(ids))).write(
          const VisitNotesCompanion(syncState: synced, dirty: clean),
        ),
      VisitCaptureTable.photos =>
        (update(visitPhotos)..where((t) => t.id.isIn(ids))).write(
          const VisitPhotosCompanion(syncState: synced, dirty: clean),
        ),
    };
  }

  /// Total unsynced captures across every table — drives the pending-sync
  /// badge (`docs/OFFLINE_FIRST.md` §5).
  ///
  /// One `UNION ALL` round trip rather than eight queries (`playbook` §9).
  Future<int> countPendingVisitRecords() async {
    const tables = [
      'visit_check_ins',
      'visit_check_outs',
      'visit_order_lines',
      'visit_stock_updates',
      'visit_returns',
      'visit_collections',
      'visit_notes',
      'visit_photos',
    ];
    // Raw SQL is the documented exception here (`docs/DATABASE_GUIDE.md` §4):
    // Drift's builder has no cross-table UNION, and eight separate COUNT
    // queries to render one badge is the N+1 pattern `playbook` §9 rejects.
    // Table names are compile-time constants — no user input reaches this.
    final unions = tables
        .map((t) => 'SELECT COUNT(*) AS c FROM $t WHERE sync_state = ?')
        .join(' UNION ALL ');
    final rows = await customSelect(
      'SELECT SUM(c) AS total FROM ($unions);',
      variables: [
        for (var i = 0; i < tables.length; i++) Variable(SyncStates.dirty)
      ],
    ).getSingle();
    return (rows.data['total'] as int?) ?? 0;
  }
}
