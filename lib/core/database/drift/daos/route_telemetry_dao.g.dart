// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_telemetry_dao.dart';

// ignore_for_file: type=lint
mixin _$RouteTelemetryDaoMixin on DatabaseAccessor<AppDatabase> {
  $RoutesTable get routes => attachedDatabase.routes;
  $LocationSamplesTable get locationSamples => attachedDatabase.locationSamples;
  $CustomersTable get customers => attachedDatabase.customers;
  $RouteStopsTable get routeStops => attachedDatabase.routeStops;
  $FraudFlagsTable get fraudFlags => attachedDatabase.fraudFlags;
  RouteTelemetryDaoManager get managers => RouteTelemetryDaoManager(this);
}

class RouteTelemetryDaoManager {
  final _$RouteTelemetryDaoMixin _db;
  RouteTelemetryDaoManager(this._db);
  $$RoutesTableTableManager get routes =>
      $$RoutesTableTableManager(_db.attachedDatabase, _db.routes);
  $$LocationSamplesTableTableManager get locationSamples =>
      $$LocationSamplesTableTableManager(
          _db.attachedDatabase, _db.locationSamples);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$RouteStopsTableTableManager get routeStops =>
      $$RouteStopsTableTableManager(_db.attachedDatabase, _db.routeStops);
  $$FraudFlagsTableTableManager get fraudFlags =>
      $$FraudFlagsTableTableManager(_db.attachedDatabase, _db.fraudFlags);
}
