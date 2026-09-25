// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_dao.dart';

// ignore_for_file: type=lint
mixin _$RouteDaoMixin on DatabaseAccessor<AppDatabase> {
  $RoutesTable get routes => attachedDatabase.routes;
  $RouteStopsTable get routeStops => attachedDatabase.routeStops;
  $RouteDepotsTable get routeDepots => attachedDatabase.routeDepots;
  $RouteSyncMetaTable get routeSyncMeta => attachedDatabase.routeSyncMeta;
  $DepotsTable get depots => attachedDatabase.depots;
  RouteDaoManager get managers => RouteDaoManager(this);
}

class RouteDaoManager {
  final _$RouteDaoMixin _db;
  RouteDaoManager(this._db);
  $$RoutesTableTableManager get routes =>
      $$RoutesTableTableManager(_db.attachedDatabase, _db.routes);
  $$RouteStopsTableTableManager get routeStops =>
      $$RouteStopsTableTableManager(_db.attachedDatabase, _db.routeStops);
  $$RouteDepotsTableTableManager get routeDepots =>
      $$RouteDepotsTableTableManager(_db.attachedDatabase, _db.routeDepots);
  $$RouteSyncMetaTableTableManager get routeSyncMeta =>
      $$RouteSyncMetaTableTableManager(_db.attachedDatabase, _db.routeSyncMeta);
  $$DepotsTableTableManager get depots =>
      $$DepotsTableTableManager(_db.attachedDatabase, _db.depots);
}
