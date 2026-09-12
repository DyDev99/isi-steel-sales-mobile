/// Orders domain tables, ported from the plaintext `catalog.db` (**T1.5b**).
///
/// These three tables were the last business data outside the encrypted
/// database. Porting them completes the T1.5 purge started for `routes.db`:
/// quotation pricing, customer identifiers, and the sync queue's payloads now
/// live encrypted at rest on mobile like everything else (ADR-001).
///
/// ## Column shapes are copied verbatim, on purpose
///
/// Every column keeps the exact name, type, and nullability it had in
/// `catalog.db`. The repositories above these tables read and write raw
/// `DataMap` rows with snake_case keys, so an "improvement" here — tightening a
/// nullable column, renaming `lines_json`, converting an ISO string to a
/// `DateTimeColumn` — would silently break a repository that this port is
/// meant to leave untouched. Widen the schema in a later, deliberate migration
/// if it needs widening; the cutover itself changes nothing above the DAO.
///
/// The ISO-8601 `TextColumn` timestamps are the clearest case: they look like
/// they want to be `DateTimeColumn`s, and they are deliberately not, because
/// `created_at DESC` string ordering is what the existing queries rely on.
library;

import 'package:drift/drift.dart';

/// A saved quotation. Local-first: created offline, pushed to SAP through
/// [SyncQueue].
class Quotations extends Table {
  @override
  String get tableName => 'quotations';

  TextColumn get id => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get shopName => text().nullable()();
  TextColumn get leadId => text().nullable()();
  TextColumn get leadDisplayName => text().nullable()();

  /// JSON array of quotation lines. Free-form so line shape can evolve without
  /// a schema change — mirrors `cart_items.customization_json`.
  TextColumn get linesJson => text()();

  RealColumn get subtotal => real()();
  RealColumn get discount => real()();
  RealColumn get tax => real()();
  RealColumn get total => real()();
  TextColumn get status => text()();
  TextColumn get offVisitReason => text().nullable()();

  /// Capture location. Nullable because a quotation can legitimately be written
  /// with location unavailable (indoors, permission denied) — offline capture
  /// must never be blocked on a GPS fix (ADR-002).
  RealColumn get gpsLat => real().nullable()();
  RealColumn get gpsLng => real().nullable()();

  TextColumn get sapDraftStatus => text()();
  TextColumn get validUntil => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A confirmed sales order, produced from a [Quotations] row.
class SalesOrders extends Table {
  @override
  String get tableName => 'sales_orders';

  TextColumn get id => text()();
  TextColumn get quotationId => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get shopName => text().nullable()();
  TextColumn get leadId => text().nullable()();
  TextColumn get leadDisplayName => text().nullable()();
  TextColumn get linesJson => text()();
  RealColumn get subtotal => real()();
  RealColumn get discount => real()();
  RealColumn get tax => real()();
  RealColumn get total => real()();
  TextColumn get status => text()();
  TextColumn get offVisitReason => text().nullable()();
  TextColumn get sapStatus => text()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The Orders feature's outbound sync queue.
///
/// Note this is the *feature-local* queue that exists today, ported as-is. It
/// is **not** yet the unified `core/sync/` queue ADR-006 specifies — that
/// generalization is Phase 4 and deliberately not attempted here. Moving the
/// table into the encrypted database first is what makes that later promotion
/// a refactor rather than a second migration of live field data.
///
/// `quotation_id` is intentionally left without a foreign key to `quotations`.
/// The legacy table had none, and adding one would change delete semantics for
/// rows this port must not alter in behaviour.
class SyncQueue extends Table {
  @override
  String get tableName => 'sync_queue';

  TextColumn get id => text()();
  TextColumn get quotationId => text()();
  TextColumn get status => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// Backoff gate: null means "eligible now".
  TextColumn get nextRetryAt => text().nullable()();

  TextColumn get lastError => text().nullable()();
  TextColumn get errorCode => text().nullable()();
  TextColumn get sapDocumentNumber => text().nullable()();
  TextColumn get sapMessage => text().nullable()();
  TextColumn get sapTimestamp => text().nullable()();
  IntColumn get syncDurationMs => integer().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
