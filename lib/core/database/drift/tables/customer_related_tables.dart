import 'package:drift/drift.dart';

/// Child tables of the customer directory, ported from `customers.db` into the
/// single encrypted database (T2). Split by ownership:
///   * server-controlled, replaced on sync: [CustomerContacts]
///   * rep-owned, queued for push: [CustomerNotes], [CustomerActivities]
///   * local UI state: [CustomerFavorites], [CustomerRecent]
///   * sync bookkeeping: [CustomerSyncMeta]
///
/// ## No foreign keys to `customers` (ADR-011, schema v18)
///
/// [customerId] is a plain column, not a foreign key. The backend owns
/// referential integrity for customer data and has already enforced it before
/// the row reaches the device; these tables are a **flat local mirror** whose
/// only job is to store what arrived and render it.
///
/// Re-declaring the constraint here bought nothing and cost real data: rows
/// arrive from independently-paged endpoints in an order the server never
/// promised, so a child row whose parent has not been pulled yet aborted the
/// whole write transaction rather than landing harmlessly. An orphan here is
/// invisible (every read filters by `customer_id`) and self-heals on the next
/// sync — which is strictly better than losing the batch.
///
/// See `docs/adr/ADR011localmirrornorelations.md`.

@TableIndex(name: 'idx_customer_contacts_customer', columns: {#customerId})
class CustomerContacts extends Table {
  @override
  String get tableName => 'customer_contacts';

  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_customer_notes_customer', columns: {#customerId})
class CustomerNotes extends Table {
  @override
  String get tableName => 'customer_notes';

  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_customer_activities_customer', columns: {#customerId})
class CustomerActivities extends Table {
  @override
  String get tableName => 'customer_activities';

  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get type => text()();
  TextColumn get summary => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class CustomerFavorites extends Table {
  @override
  String get tableName => 'customer_favorites';

  TextColumn get customerId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {customerId};
}

class CustomerRecent extends Table {
  @override
  String get tableName => 'customer_recent';

  TextColumn get customerId => text()();
  DateTimeColumn get viewedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {customerId};
}

class CustomerSyncMeta extends Table {
  @override
  String get tableName => 'customer_sync_meta';

  TextColumn get entity => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {entity};
}
