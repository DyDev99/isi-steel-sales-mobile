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
// Both back a hot-path `WHERE` in `CustomerDao.browse` once the Sales
// Organization / Division filters are selectable, so they are indexed per
// DATABASE_GUIDE.md §3.
@TableIndex(name: 'idx_customers_sales_org', columns: {#salesOrg})
@TableIndex(name: 'idx_customers_division', columns: {#division})
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

  // ── SAP sales-area & commercial attributes (schema v9) ──────────────
  // Names deliberately mirror the SAP Customer (BP) API field names documented
  // in `SapAPI_Technical_Document_v1_BP.docx` §5, so swapping the mock remote
  // datasource for a real SAP one is a mapper change, not a schema change
  // (ADR-009 decision 4).
  //
  // All are nullable or defaulted: `addColumn` must supply a value for rows
  // that already exist at v8, and SAP itself leaves most of these blank for
  // prospects that have no sales area assigned yet.

  /// Sales area — the three fields SAP uses together to scope a customer.
  TextColumn get salesOrg => text().nullable()();
  TextColumn get division => text().nullable()();
  TextColumn get distributionChannel => text().nullable()();

  /// Commercial classification.
  TextColumn get customerGroup => text().nullable()();
  TextColumn get priceGroup => text().nullable()();

  /// Latin and Khmer legal names. `shopName` stays the display name; these are
  /// the SAP `name1` / `name3` equivalents used for search and documents.
  TextColumn get enName => text().nullable()();
  TextColumn get khName => text().nullable()();

  /// Credit position. `creditLimit` already exists above; the balance is the
  /// currently-consumed portion, so available credit is limit − balance.
  RealColumn get creditBalance => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();

  /// VAT / tax identification number (SAP `taxNumber`).
  TextColumn get taxNumber => text().nullable()();

  /// Lifetime order count. `lifetimeValue` above is the matching money figure.
  IntColumn get totalOrders => integer().withDefault(const Constant(0))();

  /// When SAP first created the record. `updatedAt` already covers the
  /// modification side.
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// Per-row sync state — `synced` / `dirty` / `syncing` / `conflict`
  /// (SYNC_ENGINE.md §5). Adding it here closes part of the standard
  /// syncable-column gap in DATABASE_GUIDE.md §3.1; `server_revision` and
  /// `dirty` remain outstanding and belong with the sync-engine work rather
  /// than this feature change.
  TextColumn get syncState => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
