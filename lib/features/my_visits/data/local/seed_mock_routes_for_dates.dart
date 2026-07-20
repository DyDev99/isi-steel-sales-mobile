import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_plan_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_stop_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/territory_type.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

const _stopsPerRoute = 3;

/// (UTC calendar day, route count) for the two-day mock spread requested for
/// exercising the dashboard's calendar date filtering.
final _plan = <(DateTime, int)>[
  (DateTime.utc(2026, 7, 20), 5),
  (DateTime.utc(2026, 7, 21), 4),
];

/// TEST-ONLY DATA. Seeds a fixed multi-day mock route calendar (5 routes on
/// 2026-07-20, 4 on 2026-07-21, [_stopsPerRoute] stops each) so the
/// dashboard's calendar/date filtering can be exercised without waiting for a
/// backend sync.
///
/// Mirrors `seedIsiTowerTestRoute`: borrows real, already-synced customers
/// (id + their own directory data) so `route_stops.customer_id` FKs resolve
/// (ADR-001) — `upsertCustomers` only *updates* an existing customer row, it
/// cannot create one. `visitDate` is anchored to UTC (`RouteDao
/// .fetchRoutesForDay` filters by the UTC calendar day, not local) — the same
/// pitfall documented on `seedIsiTowerTestRoute`'s own `visitDate`.
///
/// Requires at least `_stopsPerRoute * totalRoutes` customers already synced
/// locally, else throws a [StateError].
///
/// Remove this file (or the call site) before shipping — it's a fixture, not
/// production code.
Future<void> seedMockRoutesForDates(
  RouteLocalDataSource routeLocalDataSource,
  CustomerLocalDataSource customerLocalDataSource,
) async {
  // Pull whatever the directory has (the mock ships only a handful). A demo
  // customer may legitimately appear on more than one stop/route — the
  // route_stops FK only needs its customer_id to resolve, and its PK is the
  // stop id — so we reuse the pool cyclically rather than demanding one
  // distinct customer per stop (which the 6-customer mock can never satisfy).
  final customers =
      await customerLocalDataSource.browse(page: 0, pageSize: 100);
  if (customers.isEmpty) {
    throw StateError(
      'seedMockRoutesForDates needs at least one customer already synced '
      'locally (found none) — run customer sync first, then try seeding again.',
    );
  }

  CustomerStopInfoModel toStopInfo(Customer c) => CustomerStopInfoModel(
        id: c.id,
        name: c.shopName,
        code: c.customerCode,
        contact: c.ownerName,
        phone: c.phone,
        address: c.address,
        territory: c.territory,
        territoryType: TerritoryType.urban,
        latitude: c.latitude,
        longitude: c.longitude,
        geofenceRadiusOverride: 150,
      );

  var cursor = 0;
  final routes = <RoutePlanModel>[];
  for (final (visitDate, routeCount) in _plan) {
    for (var r = 0; r < routeCount; r++) {
      final routeId =
          'test-route-${visitDate.year}${visitDate.month}${visitDate.day}-$r';
      var stopCursor = visitDate.add(const Duration(hours: 8));
      final stops = <RouteStopModel>[];
      for (var s = 0; s < _stopsPerRoute; s++) {
        final arrival = stopCursor;
        final departure = arrival.add(const Duration(minutes: 30));
        stops.add(RouteStopModel(
          id: '$routeId-stop-$s',
          routeId: routeId,
          // Cycle through the available pool — reuse is fine (see above).
          customer: toStopInfo(customers[cursor++ % customers.length]),
          sequence: s + 1,
          plannedArrival: arrival,
          plannedDeparture: departure,
          status: VisitStatus.pending,
        ));
        stopCursor = departure.add(const Duration(minutes: 20));
      }
      routes.add(RoutePlanModel(
        id: routeId,
        name: 'Test Route ${visitDate.year}-${visitDate.month}-'
            '${visitDate.day} #${r + 1}',
        repId: 'test-rep',
        repName: 'Test Rep',
        territory: 'Phnom Penh',
        visitDate: visitDate,
        plannedStart: visitDate.add(const Duration(hours: 8)),
        plannedEnd: stopCursor,
        status: RouteStatus.published,
        stops: stops,
      ));
    }
  }

  await routeLocalDataSource.upsertCustomers(routes
      .expand((r) => r.stops)
      .map((s) => s.customer as CustomerStopInfoModel)
      .toList());
  await routeLocalDataSource.upsertRoutes(routes);
}
