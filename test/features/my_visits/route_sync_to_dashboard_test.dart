import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/api_route_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/route_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/route_sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_sync_scope.dart';

import 'route_feed_fixture.dart';

/// End-to-end from the route feed to what the Visit dashboards actually read.
///
/// Every other route test in this folder seeds the DAO directly, which skips
/// the path that broke in the field: the rep opens My Visits and gets empty
/// screens. A test that hands the database its rows can never catch that, so
/// this one starts where the app does — at the remote feed, and drives the
/// real [ApiRouteRemoteDataSource] over a scripted transport so the JSON the
/// backend actually sends is parsed on the way through.
class _AlwaysOnline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

void main() {
  late AppDatabase db;
  late RouteDriftLocalDataSource local;
  late CustomerDriftLocalDataSource customers;
  late RouteSyncRepositoryImpl sync;
  late RouteRepositoryImpl routes;

  const logger = ConsoleAppLogger(verbose: false);
  const scope = RouteSyncScope(repId: 'rep-1', territory: 'Phnom Penh');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    customers = CustomerDriftLocalDataSource(db.customerDao);
    local = RouteDriftLocalDataSource(db.routeDao, logger);
    // Resolved per request, so the feed names whatever customers the test
    // seeded — `route_stops.customer_id` is a live FK.
    sync = RouteSyncRepositoryImpl(
      remote: ApiRouteRemoteDataSource(
        scriptedRouteFeed(
          customerIds: () async =>
              (await customers.browse(page: 0, pageSize: 12))
                  .map((c) => c.id)
                  .toList(),
        ),
      ),
      local: local,
      network: _AlwaysOnline(),
    );
    routes = RouteRepositoryImpl(local);
  });
  tearDown(() => db.close());

  /// The route feed rebases its stops onto the rep's real customer directory
  /// (`route_stops.customer_id` is a live FK), so the directory has to exist
  /// before any route can be pulled.
  Future<void> seedCustomers({int count = 12}) async {
    final now = DateTime.now().toUtc();
    for (var i = 0; i < count; i++) {
      await db.into(db.customers).insert(
            CustomersCompanion.insert(
              id: 'cust-$i',
              sapCustomerId: Value('SAP-$i'),
              customerCode: 'C-$i',
              shopName: 'ISI Hardware $i',
              ownerName: 'Sok Dara',
              phone: '012345678',
              address: 'St 271',
              province: 'Phnom Penh',
              district: 'TK',
              territory: 'Phnom Penh',
              latitude: 11.55,
              longitude: 104.91,
              creditLimit: 5000,
              status: 'active',
              assignedRepId: 'rep-1',
              assignedRepName: 'Rep One',
              updatedAt: now,
              territoryType: const Value('industrial'),
            ),
          );
    }
  }

  test('route sync with no customers fails loudly rather than silently empty',
      () async {
    // The feed cannot invent customers, so with an empty directory this has to
    // surface as a failure the UI can render — not an exception escaping the
    // repository, and not a success that leaves the dashboards blank with no
    // explanation of why.
    final unsatisfiable = RouteSyncRepositoryImpl(
      remote: ApiRouteRemoteDataSource(unsatisfiableRouteFeed()),
      local: local,
      network: _AlwaysOnline(),
    );

    final result = await unsatisfiable.runInitialSync(scope);

    expect(result.when(success: (_) => false, failure: (_) => true), isTrue,
        reason: 'an unsatisfiable sync must report failure');
  });

  test('today routes reach the dashboard after a sync', () async {
    await seedCustomers();

    final result = await sync.runInitialSync(scope);
    final upserted = result.when(success: (r) => r.upserted, failure: (_) => 0);
    expect(upserted, greaterThan(0), reason: 'the feed produced no routes');

    final today = (await routes.fetchTodayRoutes())
        .when(success: (r) => r, failure: (_) => const []);

    expect(today, isNotEmpty,
        reason: 'this is the empty Visit dashboard: sync reported routes, so '
            "today's list must return them");
  });

  test('synced routes carry stops with customer information', () async {
    await seedCustomers();
    await sync.runInitialSync(scope);

    final today = (await routes.fetchTodayRoutes())
        .when(success: (r) => r, failure: (_) => const []);

    expect(today.any((r) => r.stops.isNotEmpty), isTrue,
        reason: 'a route with no stops renders as an empty Stop Dashboard');

    final stop = today.firstWhere((r) => r.stops.isNotEmpty).stops.first;
    expect(stop.customer.name.trim(), isNotEmpty);
  });
}
