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
/// Usage (e.g. behind a debug-only button or `kDebugMode` check):
/// ```dart
/// await seedIsiTowerTestRoute(sl<RouteLocalDataSource>());
/// ```
/// Then pull-to-refresh (or re-open) the Route Dashboard — the seeded route
/// shows up like any synced route since it's written through the same
/// `upsertCustomers` / `upsertRoutes` calls the sync engine uses.
///
/// Remove this file (or the call site) before shipping — it's a fixture,
/// not production code.
Future<void> seedIsiTowerTestRoute(RouteLocalDataSource localDataSource) async {
  final now = DateTime.now();

  final customer999Condo = CustomerStopInfoModel(
    id: 'test-cust-999-condo',
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
    id: 'test-cust-isi-tower',
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
    id: 'test-cust-kmall-veng-sreng',
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

  final route = RoutePlanModel(
    id: 'test-route-3-stops',
    name: 'Test Route — 3 Stops',
    repId: 'test-rep',
    repName: 'Test Rep',
    territory: 'Phnom Penh',
    visitDate: DateTime(now.year, now.month, now.day),
    plannedStart: now,
    plannedEnd: now.add(const Duration(hours: 2)),
    status: RouteStatus.published,
    stops: [stop1, stop2, stop3],
  );

  await localDataSource.upsertCustomers([
    customer999Condo,
    customerIsiTower,
    customerKMall,
  ]);
  await localDataSource.upsertRoutes([route]);
}
