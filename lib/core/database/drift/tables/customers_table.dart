import 'package:drift/drift.dart';

/// Offline customer directory (Blueprint Layer 1). Ported from the legacy
/// `customers.db` `customers` table into the single encrypted database, using
/// idiomatic Drift column types (DateTime/bool/int) instead of the old
/// text/int-encoded columns.
///
/// SAP-controlled: overwritten wholesale on every sync, never merged locally
/// (reps have no write path to these columns), so the sync strategy is a plain
/// upsert keyed by [id] with [sapCustomerId] uniquely indexed.
@TableIndex(name: 'idx_customers_territory', columns: {#territory})
@TableIndex(name: 'idx_customers_rep', columns: {#assignedRepId})
@TableIndex(name: 'idx_customers_status', columns: {#status})
class Customers extends Table {
  @override
  String get tableName => 'customers';

  TextColumn get id => text()();
  TextColumn get sapCustomerId => text().unique()();
  TextColumn get customerCode => text()();
  TextColumn get shopName => text()();
  TextColumn get ownerName => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get address => text()();
  TextColumn get province => text()();
  TextColumn get district => text()();

  // ── SAP-unavailable attributes (schema v9) ──────────────────────────
  // The SAP business-partner payload does not carry these. `GetDetail`/
  // `GetPaging` return customer number, names, sales area, address, phone,
  // payment terms, credit limit and sales employee — there is no geolocation,
  // no CRM-style status, and no territory in the app's sense of the word
  // (`SapAPI_Technical_Document_v1_BP.docx` §5.2).
  //
  // They were `NOT NULL`, which was tenable only while the sole writer was a
  // mock that invented values. Against the real customer master a mapper cannot
  // populate them, and the alternatives were both worse: writing sentinel
  // coordinates would place every customer at 0°,0° on the map, and dropping
  // the columns would discard data the route/visit features do use once it has
  // been captured by other means.
  //
  // Nullable states the truth — "SAP has not told us" — and lets the UI render
  // an explicit unknown instead of a plausible-looking lie.
  TextColumn get territory => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get assignedRepId => text().nullable()();
  TextColumn get assignedRepName => text().nullable()();

  RealColumn get creditLimit => real()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get originLeadId => text().nullable()();
  TextColumn get productsPurchased => text().withDefault(const Constant(''))();
  DateTimeColumn get lastOrderDate => dateTime().nullable()();
  DateTimeColumn get lastVisitDate => dateTime().nullable()();
  RealColumn get lifetimeValue => real().withDefault(const Constant(0))();
  IntColumn get openOpportunityCount =>
      integer().withDefault(const Constant(0))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  // ── Route-execution attributes (T1.5, schema v7) ────────────────────
  // Absorbed from the legacy plaintext `routes.db.customers` table, which was a
  // denormalised copy of this one plus these two fields. Rather than import
  // that copy — which would resurrect stale PII and clobber the SAP-controlled
  // columns above — the two genuinely-unique fields are added here and the
  // legacy copy is dropped. This table stays the single source of truth for a
  // customer (ADR-001).
  //
  // Both are nullable because rows created before v7 have no value, and because
  // only customers that appear on a route ever carry them.

  /// Urban / rural / etc. — drives visit-planning rules.
  TextColumn get territoryType => text().nullable()();

  /// Per-customer geofence radius in metres, overriding the global policy when
  /// a site is unusually large (a depot yard) or tight (a stall in a market).
  RealColumn get geofenceRadiusOverride => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
