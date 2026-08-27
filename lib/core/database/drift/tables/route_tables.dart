import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/syncable_table.dart';

/// Route plans (Blueprint Layer 1). Ported from the legacy **plaintext**
/// `routes.db` `routes` table into the single encrypted database (ADR-001,
/// `docs/blueprint/migration-plan.md` T1.5).
///
/// Offline posture (`docs/blueprint/offline-architecture.md` §4): full offline, pull + push
/// telemetry — the plan is issued by the backend, while execution status is
/// captured locally and pushed.
@TableIndex(name: 'idx_routes_rep', columns: {#repId})
@TableIndex(name: 'idx_routes_visit_date', columns: {#visitDate})
@DataClassName('RouteRow')
class Routes extends Table with SyncableTable {
  @override
  String get tableName => 'routes';

  TextColumn get name => text()();
  TextColumn get repId => text()();
  TextColumn get repName => text()();
  TextColumn get territory => text()();
  DateTimeColumn get visitDate => dateTime()();
  DateTimeColumn get plannedStart => dateTime()();
  DateTimeColumn get plannedEnd => dateTime()();
  TextColumn get status => text()();
}

/// Stops on a [Routes] plan. Legacy table name was `stops`; renamed to match the
/// `RouteStop` domain entity.
///
/// ## No foreign keys (ADR-011, schema v18)
///
/// [routeId] and [customerId] are plain columns. Both constraints were removed
/// after they were shown to destroy data rather than protect it:
///
///   * `customer_id -> customers` aborted the *entire* route write when any one
///     stop referenced a customer the directory had not pulled yet. The route
///     feed and the customer feed page independently and the backend never
///     promised an arrival order, so a five-stop day persisted zero stops and
///     zero routes. The rep lost the whole day, not one stop.
///   * `route_id -> routes ON DELETE CASCADE` is unnecessary for the same
///     reason: the two always arrive in one payload, and nothing hard-deletes
///     a route.
///
/// The stop's own customer details are stored flat in [RouteCustomers], so a
/// stop renders from the route feed alone and never depends on the customer
/// directory having synced first.
@TableIndex(name: 'idx_route_stops_route', columns: {#routeId})
@TableIndex(name: 'idx_route_stops_customer', columns: {#customerId})
@DataClassName('RouteStopRow')
class RouteStops extends Table with SyncableTable {
  @override
  String get tableName => 'route_stops';

  TextColumn get routeId => text()();
  TextColumn get customerId => text()();
  IntColumn get sequence => integer()();
  DateTimeColumn get plannedArrival => dateTime()();
  DateTimeColumn get plannedDeparture => dateTime()();
  TextColumn get status => text()();
  DateTimeColumn get actualArrival => dateTime().nullable()();
  DateTimeColumn get actualDeparture => dateTime().nullable()();
}

/// The customer details carried by the **route feed itself**
/// (`docs/feature/my-visits/api.md` §7.1 `CustomerStopInfo`) — a flat,
/// de-duplicated mirror, one row per customer appearing on a route.
///
/// ## Why this exists rather than joining the directory (ADR-011)
///
/// T1.5 deleted the legacy denormalised copy and made route stops join
/// `customers` instead, on the reasoning that the directory is the single
/// source of truth. That reasoning was sound for *ownership* and wrong for
/// *availability*: the two feeds are separate endpoints with separate scopes,
/// so a stop routinely references a customer the directory does not have, and
/// the join then hid the stop from the rep standing outside the shop.
///
/// This table restores the payload's own copy without resurrecting the old
/// confusion: it is explicitly the *route feed's* view, used only to render
/// stops. It never feeds the Customers screen, and the directory never reads
/// it. That also removes `my_visits`' dependency on the customer feature's
/// tables, which `CLAUDE.md` §4 forbids anyway.
///
/// Server-owned and replaced wholesale on every route sync, so it carries no
/// sync state of its own.
@DataClassName('RouteCustomerRow')
class RouteCustomers extends Table {
  @override
  String get tableName => 'route_customers';

  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Khmer shop name. `''` is the documented "no Khmer name" value, so the
  /// column defaults rather than being nullable — `LocalizedText` falls back
  /// to [name] and a stop card is never blank.
  TextColumn get nameKh => text().withDefault(const Constant(''))();
  TextColumn get code => text()();
  TextColumn get contact => text()();
  TextColumn get phone => text()();
  TextColumn get address => text()();
  TextColumn get territory => text()();
  TextColumn get territoryType => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  /// Metres; falls back to the territory-type default when absent.
  RealColumn get geofenceRadiusOverride => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// GPS breadcrumb trail captured while a route is executed.
///
/// **Sensitive**: this is a location trace of a named employee. It sat in a
/// plaintext SQLite file until T1.5; moving it into the encrypted database is
/// the single highest-severity outcome of this migration
/// (`docs/skills/security.md` §3, `docs/blueprint/migration-plan.md` §9 risk register).
///
/// Keeps its `route_id` foreign key (ADR-011 kept the constraints that have no
/// data-loss path): nothing hard-deletes a route — route sync upserts — so the
/// cascade never fires during normal operation, and it still gives correct
/// cleanup if a route is ever purged.
@TableIndex(name: 'idx_location_samples_route', columns: {#routeId})
@TableIndex(name: 'idx_location_samples_timestamp', columns: {#timestamp})
@DataClassName('LocationSampleRow')
class LocationSamples extends Table with SyncableTable {
  @override
  String get tableName => 'location_samples';

  // Restored explicitly: drift_dev 2.31.0 + analyzer 10.2.0 silently emit no
  // foreign keys from `references()` (docs/blueprint/web-architecture.md section 8).
  // The `references()` call is kept — it still drives drift's Dart-side
  // relation API — but the SQL constraint now comes from here. Remove this
  // override once the generator is fixed, and verify with the FK tests.
  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (route_id) REFERENCES routes (id) ON DELETE CASCADE',
      ];

  TextColumn get routeId =>
      text().references(Routes, #id, onDelete: KeyAction.cascade)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real()();
  RealColumn get speed => real()();
  RealColumn get heading => real()();
  RealColumn get altitude => real()();
  DateTimeColumn get timestamp => dateTime()();

  /// True when the OS reported the fix as mock/simulated — an anti-fraud signal,
  /// never silently dropped.
  BoolColumn get isMocked => boolean().withDefault(const Constant(false))();
}

/// Fraud signals raised during route execution (geofence breach, mocked GPS).
///
/// Keeps `route_id` (see [LocationSamples]) but **not** `stop_id` (ADR-011):
/// route sync replaces a route's stops on every run, and the cascade from
/// `route_stops` silently deleted compliance evidence the rep had captured and
/// not yet pushed. Losing a fraud flag because a route refreshed is precisely
/// the outcome the flag exists to prevent.
@TableIndex(name: 'idx_fraud_flags_route', columns: {#routeId})
@DataClassName('FraudFlagRow')
class FraudFlags extends Table with SyncableTable {
  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (route_id) REFERENCES routes (id) ON DELETE CASCADE',
      ];

  @override
  String get tableName => 'fraud_flags';

  TextColumn get routeId =>
      text().references(Routes, #id, onDelete: KeyAction.cascade)();

  /// Nullable: a flag can belong to a whole route rather than one stop.
  TextColumn get stopId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get detail => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get blocked => boolean().withDefault(const Constant(false))();
}

/// Delta-sync cursor for the route domain — mirrors the existing
/// `CustomerSyncMeta` / `CatalogSyncMeta` pattern.
///
/// A cursor table, not a syncable entity: it has nothing to push, so it
/// deliberately does not use [SyncableTable] (`docs/blueprint/local-storage-architecture.md` §3.1).
@DataClassName('RouteSyncMetaRow')
class RouteSyncMeta extends Table {
  @override
  String get tableName => 'route_sync_meta';

  TextColumn get entity => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {entity};
}
