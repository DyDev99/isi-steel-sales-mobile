// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_dao.dart';

// ignore_for_file: type=lint
mixin _$RouteDaoMixin on DatabaseAccessor<AppDatabase> {
  $RoutesTable get routes => attachedDatabase.routes;
  $RouteStopsTable get routeStops => attachedDatabase.routeStops;
  $RouteCustomersTable get routeCustomers => attachedDatabase.routeCustomers;
  $RouteSyncMetaTable get routeSyncMeta => attachedDatabase.routeSyncMeta;
  $CustomersTable get customers => attachedDatabase.customers;
  RouteDaoManager get managers => RouteDaoManager(this);
}

class RouteDaoManager {
  final _$RouteDaoMixin _db;
  RouteDaoManager(this._db);
  $$RoutesTableTableManager get routes =>
      $$RoutesTableTableManager(_db.attachedDatabase, _db.routes);
  $$RouteStopsTableTableManager get routeStops =>
      $$RouteStopsTableTableManager(_db.attachedDatabase, _db.routeStops);
  $$RouteCustomersTableTableManager get routeCustomers =>
      $$RouteCustomersTableTableManager(
          _db.attachedDatabase, _db.routeCustomers);
  $$RouteSyncMetaTableTableManager get routeSyncMeta =>
      $$RouteSyncMetaTableTableManager(_db.attachedDatabase, _db.routeSyncMeta);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
}
