import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/customers_table.dart';

/// Child tables of the customer directory, ported from `customers.db` into the
/// single encrypted database (T2). Split by ownership:
///   * SAP-controlled, replaced on sync: [CustomerContacts]
///   * rep-owned, queued for push: [CustomerNotes], [CustomerActivities]
///   * local UI state: [CustomerFavorites], [CustomerRecent]
///   * sync bookkeeping: [CustomerSyncMeta]
///
/// Foreign keys reference [Customers.id] (enforced — `PRAGMA foreign_keys=ON`).

@TableIndex(name: 'idx_customer_contacts_customer', columns: {#customerId})
class CustomerContacts extends Table {
  @override
  String get tableName => 'customer_contacts';

  // Restored explicitly: drift_dev 2.31.0 + analyzer 10.2.0 silently emit no
  // foreign keys from `references()` above (docs/flutter-web.md section 8).
  // The `references()` calls are kept — they still drive drift's Dart-side
  // relation API — but the SQL constraint now comes from here. Remove this
  // override once the generator is fixed, and verify with the FK tests.
  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (customer_id) REFERENCES customers (id)',
      ];

  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
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

  // Restored explicitly: drift_dev 2.31.0 + analyzer 10.2.0 silently emit no
  // foreign keys from `references()` above (docs/flutter-web.md section 8).
  // The `references()` calls are kept — they still drive drift's Dart-side
  // relation API — but the SQL constraint now comes from here. Remove this
  // override once the generator is fixed, and verify with the FK tests.
  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (customer_id) REFERENCES customers (id)',
      ];

  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
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

  // Restored explicitly: drift_dev 2.31.0 + analyzer 10.2.0 silently emit no
  // foreign keys from `references()` above (docs/flutter-web.md section 8).
  // The `references()` calls are kept — they still drive drift's Dart-side
  // relation API — but the SQL constraint now comes from here. Remove this
  // override once the generator is fixed, and verify with the FK tests.
  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (customer_id) REFERENCES customers (id)',
      ];

  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
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

  // Restored explicitly: drift_dev 2.31.0 + analyzer 10.2.0 silently emit no
  // foreign keys from `references()` above (docs/flutter-web.md section 8).
  // The `references()` calls are kept — they still drive drift's Dart-side
  // relation API — but the SQL constraint now comes from here. Remove this
  // override once the generator is fixed, and verify with the FK tests.
  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (customer_id) REFERENCES customers (id)',
      ];

  TextColumn get customerId => text().references(Customers, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {customerId};
}

class CustomerRecent extends Table {
  @override
  String get tableName => 'customer_recent';

  // Restored explicitly: drift_dev 2.31.0 + analyzer 10.2.0 silently emit no
  // foreign keys from `references()` above (docs/flutter-web.md section 8).
  // The `references()` calls are kept — they still drive drift's Dart-side
  // relation API — but the SQL constraint now comes from here. Remove this
  // override once the generator is fixed, and verify with the FK tests.
  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (customer_id) REFERENCES customers (id)',
      ];

  TextColumn get customerId => text().references(Customers, #id)();
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
