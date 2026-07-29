// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_dao.dart';

// ignore_for_file: type=lint
mixin _$VisitDaoMixin on DatabaseAccessor<AppDatabase> {
  $RoutesTable get routes => attachedDatabase.routes;
  $CustomersTable get customers => attachedDatabase.customers;
  $RouteStopsTable get routeStops => attachedDatabase.routeStops;
  $VisitCheckInsTable get visitCheckIns => attachedDatabase.visitCheckIns;
  $VisitCheckOutsTable get visitCheckOuts => attachedDatabase.visitCheckOuts;
  $VisitOrderLinesTable get visitOrderLines => attachedDatabase.visitOrderLines;
  $VisitStockUpdatesTable get visitStockUpdates =>
      attachedDatabase.visitStockUpdates;
  $VisitReturnsTable get visitReturns => attachedDatabase.visitReturns;
  $VisitCollectionsTable get visitCollections =>
      attachedDatabase.visitCollections;
  $VisitNotesTable get visitNotes => attachedDatabase.visitNotes;
  $VisitPhotosTable get visitPhotos => attachedDatabase.visitPhotos;
  VisitDaoManager get managers => VisitDaoManager(this);
}

class VisitDaoManager {
  final _$VisitDaoMixin _db;
  VisitDaoManager(this._db);
  $$RoutesTableTableManager get routes =>
      $$RoutesTableTableManager(_db.attachedDatabase, _db.routes);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$RouteStopsTableTableManager get routeStops =>
      $$RouteStopsTableTableManager(_db.attachedDatabase, _db.routeStops);
  $$VisitCheckInsTableTableManager get visitCheckIns =>
      $$VisitCheckInsTableTableManager(_db.attachedDatabase, _db.visitCheckIns);
  $$VisitCheckOutsTableTableManager get visitCheckOuts =>
      $$VisitCheckOutsTableTableManager(
          _db.attachedDatabase, _db.visitCheckOuts);
  $$VisitOrderLinesTableTableManager get visitOrderLines =>
      $$VisitOrderLinesTableTableManager(
          _db.attachedDatabase, _db.visitOrderLines);
  $$VisitStockUpdatesTableTableManager get visitStockUpdates =>
      $$VisitStockUpdatesTableTableManager(
          _db.attachedDatabase, _db.visitStockUpdates);
  $$VisitReturnsTableTableManager get visitReturns =>
      $$VisitReturnsTableTableManager(_db.attachedDatabase, _db.visitReturns);
  $$VisitCollectionsTableTableManager get visitCollections =>
      $$VisitCollectionsTableTableManager(
          _db.attachedDatabase, _db.visitCollections);
  $$VisitNotesTableTableManager get visitNotes =>
      $$VisitNotesTableTableManager(_db.attachedDatabase, _db.visitNotes);
  $$VisitPhotosTableTableManager get visitPhotos =>
      $$VisitPhotosTableTableManager(_db.attachedDatabase, _db.visitPhotos);
}
