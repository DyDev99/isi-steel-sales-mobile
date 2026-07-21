import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_plan_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_stop_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/territory_type.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

/// TEST-ONLY DATA. Seeds a single route with 3 stops (999 Condo, ISI Tower,
/// K Mall Veng Sreng) so the transit/check-in geofence flow can be exercised
/// on a real device without waiting for a backend sync.
///
/// ## Why this takes a [CustomerLocalDataSource] now
///
/// `customers` is SAP-controlled, single-source-of-truth as of the T1.5 Drift
/// cutover (ADR-001) — `RouteDriftLocalDataSource.upsertCustomers` only
/// *updates* an existing customer row's route-execution attributes
/// (territoryType, geofenceRadiusOverride); it can no longer insert one.
/// `route_stops.customer_id` is a real foreign key into that table. This used
/// to fabricate its own `test-cust-*` IDs, which don't exist there, so
/// `upsertRoutes` failed with `FOREIGN KEY constraint failed` the moment it
/// tried to write a stop pointing at one — `upsertCustomers` silently skips
/// unknown IDs rather than creating them, so there was nothing for the stop
/// to reference.
///
/// This version borrows the `id` of 3 real, already-synced customers instead,
/// so the FK resolves — everything else (the 999 Condo / ISI Tower / K Mall
/// labels, addresses, coordinates) is unchanged, since `route_stops` has no
/// columns for them anyway (only `customer_id`, confirmed from the schema).
///
/// **GPS caveat:** whatever the geofence/arrival flow actually checks
/// distance against almost certainly comes from the real customer's own
/// synced address, not the coordinates below — those never reached the DB
/// through this path even before the FK bug. If you need the walk-test to
/// land at these 3 specific buildings, replace the `browse()` call below with
/// 3 hardcoded real customer IDs that are actually near them.
///
/// Requires at least 3 customers already synced locally — run customer sync
/// first if this throws a [StateError].
///
/// Usage (e.g. behind a debug-only button or `kDebugMode` check):
/// ```dart
/// await seedIsiTowerTestRoute(
///   sl<RouteLocalDataSource>(),
///   sl<CustomerLocalDataSource>(),
/// );
/// ```
/// Then pull-to-refresh (or re-open) the Route Dashboard — the seeded route
/// shows up like any synced route since it's written through the same
/// `upsertCustomers` / `upsertRoutes` calls the sync engine uses.
///
/// Remove this file (or the call site) before shipping — it's a fixture,
/// not production code.
Future<void> seedIsiTowerTestRoute(
  RouteLocalDataSource routeLocalDataSource,
  CustomerLocalDataSource customerLocalDataSource,
) async {
  final now = DateTime.now();

  final realCustomers =
      await customerLocalDataSource.browse(page: 0, pageSize: 3);
  if (realCustomers.length < 3) {
    throw StateError(
      'seedIsiTowerTestRoute needs at least 3 customers already synced '
      'locally (found ${realCustomers.length}) — run customer sync first, '
      'then try seeding again.',
    );
  }

  final customer999Condo = CustomerStopInfoModel(
    id: realCustomers[0].id, // was 'test-cust-999-condo' — see doc comment
    name: '999 Condo (Test)',
    code: 'TEST-001',
    contact: 'Test Contact',
    phone: '+855 12 345 678',
    address: '999 Condo, Phnom Penh, Cambodia',
    territory: 'Phnom Penh',
    territoryType: TerritoryType.urban,
    latitude: 11.5315559,
    longitude: 104.9053922,
    geofenceRadiusOverride: 150,
  );

  final customerIsiTower = CustomerStopInfoModel(
    id: realCustomers[1].id, // was 'test-cust-isi-tower' — see doc comment
    name: 'ISI Tower (Test)',
    code: 'TEST-002',
    contact: 'Test Contact',
    phone: '+855 12 345 678',
    address:
        'ISI Tower, Sangkat Chom Chao 1, KMH Blvd Corner Street Chom Chao, '
        'Phnom Penh 120909, Cambodia',
    territory: 'Phnom Penh',
    territoryType: TerritoryType.urban,
    latitude: 11.5320691,
    longitude: 104.8677437,
    geofenceRadiusOverride: 150,
  );

  final customerKMall = CustomerStopInfoModel(
    id: realCustomers[2]
        .id, // was 'test-cust-kmall-veng-sreng' — see doc comment
    name: 'K Mall Veng Sreng (Test)',
    code: 'TEST-003',
    contact: 'Test Contact',
    phone: '+855 12 345 678',
    address: 'K Mall Veng Sreng, Phnom Penh, Cambodia',
    territory: 'Phnom Penh',
    territoryType: TerritoryType.urban,
    latitude: 11.5316949,
    longitude: 104.8671754,
    geofenceRadiusOverride: 150,
  );

  final stop1 = RouteStopModel(
    id: 'test-stop-999-condo',
    routeId: 'test-route-3-stops',
    customer: customer999Condo,
    sequence: 1,
    plannedArrival: now.add(const Duration(minutes: 5)),
    plannedDeparture: now.add(const Duration(minutes: 35)),
    status: VisitStatus.pending,
  );

  final stop2 = RouteStopModel(
    id: 'test-stop-isi-tower',
    routeId: 'test-route-3-stops',
    customer: customerIsiTower,
    sequence: 2,
    plannedArrival: now.add(const Duration(minutes: 45)),
    plannedDeparture: now.add(const Duration(minutes: 75)),
    status: VisitStatus.pending,
  );

  final stop3 = RouteStopModel(
    id: 'test-stop-kmall-veng-sreng',
    routeId: 'test-route-3-stops',
    customer: customerKMall,
    sequence: 3,
    plannedArrival: now.add(const Duration(minutes: 85)),
    plannedDeparture: now.add(const Duration(minutes: 115)),
    status: VisitStatus.pending,
  );

  // RouteDao.fetchRoutesForDay filters by the UTC calendar day (visit_date is
  // stored as UTC text). Anchoring to local midnight here would land on the
  // wrong UTC day in any positive-offset timezone (e.g. Cambodia UTC+7),
  // making the seeded route silently invisible to "today" — same class of
  // bug MockRouteRemoteDataSource._rebaseToToday() already guards against.
  final nowUtc = now.toUtc();

  final route = RoutePlanModel(
    id: 'test-route-3-stops',
    name: 'Test Route — 3 Stops',
    repId: 'test-rep',
    repName: 'Test Rep',
    territory: 'Phnom Penh',
    visitDate: DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day),
    plannedStart: now,
    plannedEnd: now.add(const Duration(hours: 2)),
    status: RouteStatus.published,
    stops: [stop1, stop2, stop3],
  );

  await routeLocalDataSource.upsertCustomers([
    customer999Condo,
    customerIsiTower,
    customerKMall,
  ]);
  await routeLocalDataSource.upsertRoutes([route]);
}
