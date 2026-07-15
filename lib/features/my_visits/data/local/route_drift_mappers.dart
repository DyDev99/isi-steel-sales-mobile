import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/route_dao.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_plan_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_stop_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/territory_type.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

/// Drift row ↔ model mappers for the route aggregate (T1.5 cutover).
///
/// Mirrors `customer_drift_mappers.dart`. Mappers are the only code aware of
/// Drift row/companion shapes (ADR-003 point 2).

/// The geofence radius used when a customer's territory type is unknown.
///
/// **This is a fail-closed choice, not a convenience default.** `territory_type`
/// is nullable in `customers` (added in schema v7) and is populated by route
/// sync, so null means "route sync has not seen this customer yet". The value
/// drives the geofence radius, which is a fraud control
/// (`docs/SYNC_ENGINE.md` §5 classifies check-ins as first-hand captures the
/// server cannot re-verify).
///
/// [TerritoryType.urban] is the **tightest** radius (50 m), so an unknown
/// territory rejects a check-in that a looser default would have waved through.
/// A wrongly-blocked rep is visible and recoverable in seconds; a wrongly-
/// accepted fraudulent check-in is neither.
const TerritoryType kUnknownTerritoryFallback = TerritoryType.urban;

extension CustomerRowStopInfoMapper on Customer {
  /// Projects the customer directory row onto the slice route execution needs.
  ///
  /// Field names differ because the two tables were written years apart: the
  /// legacy `routes.db` copy called them `name`/`contact`, the directory calls
  /// them `shopName`/`ownerName`. Same data, and the directory is authoritative.
  CustomerStopInfoModel toStopInfo() => CustomerStopInfoModel(
        id: id,
        name: shopName,
        code: customerCode,
        contact: ownerName,
        phone: phone,
        address: address,
        territory: territory,
        territoryType: territoryType == null
            ? kUnknownTerritoryFallback
            : TerritoryType.values.asNameMap()[territoryType!] ??
                kUnknownTerritoryFallback,
        latitude: latitude,
        longitude: longitude,
        geofenceRadiusOverride: geofenceRadiusOverride,
      );
}

extension RouteStopWithCustomerMapper on RouteStopWithCustomer {
  RouteStopModel toModel() => RouteStopModel(
        id: stop.id,
        routeId: stop.routeId,
        customer: customer.toStopInfo(),
        sequence: stop.sequence,
        plannedArrival: stop.plannedArrival,
        plannedDeparture: stop.plannedDeparture,
        // An unrecognised status means a build downgrade or a corrupt row.
        // Falling back to `pending` keeps the stop visible and actionable
        // rather than crashing the whole route screen.
        status: VisitStatus.values.asNameMap()[stop.status] ??
            VisitStatus.values.first,
        actualArrival: stop.actualArrival,
        actualDeparture: stop.actualDeparture,
      );
}

extension RouteRowMapper on RouteRow {
  RoutePlanModel toModel(List<RouteStop> stops) => RoutePlanModel(
        id: id,
        name: name,
        repId: repId,
        repName: repName,
        territory: territory,
        visitDate: visitDate,
        plannedStart: plannedStart,
        plannedEnd: plannedEnd,
        status:
            RouteStatus.values.asNameMap()[status] ?? RouteStatus.values.first,
        stops: stops,
      );
}

extension RoutePlanModelMapper on RoutePlanModel {
  RoutesCompanion toCompanion() => RoutesCompanion.insert(
        id: id,
        name: name,
        repId: repId,
        repName: repName,
        territory: territory,
        visitDate: visitDate,
        plannedStart: plannedStart,
        plannedEnd: plannedEnd,
        status: status.name,
        // A plan arriving from SAP is already in step with the server; it is not
        // a local capture awaiting a push. Only local mutations mark dirty.
        syncState: const Value('synced'),
        dirty: const Value(false),
      );

  List<RouteStopsCompanion> toStopCompanions() =>
      stops.map((s) => s.toCompanion(id)).toList();
}

extension RouteStopEntityMapper on RouteStop {
  RouteStopsCompanion toCompanion(String routeId) => RouteStopsCompanion.insert(
        id: id,
        routeId: routeId,
        customerId: customer.id,
        sequence: sequence,
        plannedArrival: plannedArrival,
        plannedDeparture: plannedDeparture,
        status: status.name,
        actualArrival: Value(actualArrival),
        actualDeparture: Value(actualDeparture),
        syncState: const Value('synced'),
        dirty: const Value(false),
      );
}
