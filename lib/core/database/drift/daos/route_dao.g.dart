// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_dao.dart';

// ignore_for_file: type=lint
mixin _$RouteDaoMixin on DatabaseAccessor<AppDatabase> {
  $RoutesTable get routes => attachedDatabase.routes;
  $CustomersTable get customers => attachedDatabase.customers;
  $RouteStopsTable get routeStops => attachedDatabase.routeStops;
  $RouteSyncMetaTable get routeSyncMeta => attachedDatabase.routeSyncMeta;
  RouteDaoManager get managers => RouteDaoManager(this);
}

class RouteDaoManager {
  final _$RouteDaoMixin _db;
  RouteDaoManager(this._db);
  $$RoutesTableTableManager get routes =>
      $$RoutesTableTableManager(_db.attachedDatabase, _db.routes);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$RouteStopsTableTableManager get routeStops =>
      $$RouteStopsTableTableManager(_db.attachedDatabase, _db.routeStops);
  $$RouteSyncMetaTableTableManager get routeSyncMeta =>
      $$RouteSyncMetaTableTableManager(_db.attachedDatabase, _db.routeSyncMeta);
}
