// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomerDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTable get customers => attachedDatabase.customers;
  $CustomerContactsTable get customerContacts =>
      attachedDatabase.customerContacts;
  $CustomerNotesTable get customerNotes => attachedDatabase.customerNotes;
  $CustomerActivitiesTable get customerActivities =>
      attachedDatabase.customerActivities;
  $CustomerFavoritesTable get customerFavorites =>
      attachedDatabase.customerFavorites;
  $CustomerRecentTable get customerRecent => attachedDatabase.customerRecent;
  $CustomerSyncMetaTable get customerSyncMeta =>
      attachedDatabase.customerSyncMeta;
  CustomerDaoManager get managers => CustomerDaoManager(this);
}

class CustomerDaoManager {
  final _$CustomerDaoMixin _db;
  CustomerDaoManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$CustomerContactsTableTableManager get customerContacts =>
      $$CustomerContactsTableTableManager(
          _db.attachedDatabase, _db.customerContacts);
  $$CustomerNotesTableTableManager get customerNotes =>
      $$CustomerNotesTableTableManager(_db.attachedDatabase, _db.customerNotes);
  $$CustomerActivitiesTableTableManager get customerActivities =>
      $$CustomerActivitiesTableTableManager(
          _db.attachedDatabase, _db.customerActivities);
  $$CustomerFavoritesTableTableManager get customerFavorites =>
      $$CustomerFavoritesTableTableManager(
          _db.attachedDatabase, _db.customerFavorites);
  $$CustomerRecentTableTableManager get customerRecent =>
      $$CustomerRecentTableTableManager(
          _db.attachedDatabase, _db.customerRecent);
  $$CustomerSyncMetaTableTableManager get customerSyncMeta =>
      $$CustomerSyncMetaTableTableManager(
          _db.attachedDatabase, _db.customerSyncMeta);
}
