import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/customers_table.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/syncable_table.dart';

/// Route plans (Blueprint Layer 1). Ported from the legacy **plaintext**
/// `routes.db` `routes` table into the single encrypted database (ADR-001,
/// `docs/MIGRATION_PLAN.md` T1.5).
///
/// Offline posture (`docs/OFFLINE_FIRST.md` §4): full offline, pull + push
/// telemetry — the plan is issued by SAP, while execution status is captured
/// locally and pushed.
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
/// [customerId] is a **real foreign key** to [Customers] — impossible under the
/// old three-database split, and one of the concrete integrity wins ADR-001 was
/// adopted for. Import must therefore reconcile orphans rather than blind-copy
/// (T1.5): a stop referencing an unknown customer is rejected by the FK.
@TableIndex(name: 'idx_route_stops_route', columns: {#routeId})
@TableIndex(name: 'idx_route_stops_customer', columns: {#customerId})
@DataClassName('RouteStopRow')
class RouteStops extends Table with SyncableTable {
  @override
  String get tableName => 'route_stops';

  TextColumn get routeId =>
      text().references(Routes, #id, onDelete: KeyAction.cascade)();
  TextColumn get customerId => text().references(Customers, #id)();
  IntColumn get sequence => integer()();
  DateTimeColumn get plannedArrival => dateTime()();
  DateTimeColumn get plannedDeparture => dateTime()();
  TextColumn get status => text()();
  DateTimeColumn get actualArrival => dateTime().nullable()();
  DateTimeColumn get actualDeparture => dateTime().nullable()();
}

/// GPS breadcrumb trail captured while a route is executed.
///
/// **Sensitive**: this is a location trace of a named employee. It sat in a
/// plaintext SQLite file until T1.5; moving it into the encrypted database is
/// the single highest-severity outcome of this migration
/// (`docs/SECURITY.md` §3, `docs/MIGRATION_PLAN.md` §9 risk register).
@TableIndex(name: 'idx_location_samples_route', columns: {#routeId})
@TableIndex(name: 'idx_location_samples_timestamp', columns: {#timestamp})
@DataClassName('LocationSampleRow')
class LocationSamples extends Table with SyncableTable {
  @override
  String get tableName => 'location_samples';

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
@TableIndex(name: 'idx_fraud_flags_route', columns: {#routeId})
@DataClassName('FraudFlagRow')
class FraudFlags extends Table with SyncableTable {
  @override
  String get tableName => 'fraud_flags';

  TextColumn get routeId =>
      text().references(Routes, #id, onDelete: KeyAction.cascade)();

  /// Nullable: a flag can belong to a whole route rather than one stop.
  TextColumn get stopId => text()
      .nullable()
      .references(RouteStops, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get detail => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get blocked => boolean().withDefault(const Constant(false))();
}

/// Delta-sync cursor for the route domain — mirrors the existing
/// `CustomerSyncMeta` / `CatalogSyncMeta` pattern.
///
/// A cursor table, not a syncable entity: it has nothing to push, so it
/// deliberately does not use [SyncableTable] (`docs/DATABASE_GUIDE.md` §3.1).
@DataClassName('RouteSyncMetaRow')
class RouteSyncMeta extends Table {
  @override
  String get tableName => 'route_sync_meta';

  TextColumn get entity => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {entity};
}
