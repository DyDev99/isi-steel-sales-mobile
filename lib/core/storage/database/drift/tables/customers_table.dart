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
  TextColumn get territory => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get creditLimit => real()();
  TextColumn get status => text()();
  TextColumn get assignedRepId => text()();
  TextColumn get assignedRepName => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get originLeadId => text().nullable()();
  TextColumn get productsPurchased => text().withDefault(const Constant(''))();
  DateTimeColumn get lastOrderDate => dateTime().nullable()();
  DateTimeColumn get lastVisitDate => dateTime().nullable()();
  RealColumn get lifetimeValue => real().withDefault(const Constant(0))();
  IntColumn get openOpportunityCount =>
      integer().withDefault(const Constant(0))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
