import 'dart:math';

import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/mock/mock_route_data.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_plan_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_stop_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/route_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/route_sync_page.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_sync_scope.dart';

/// Simulates a route-planning backend: loads the generated
/// `assets/mock/routes.json` once (falling back to generating it in-memory
/// if the asset is ever missing), then serves scoped/paged syncs from it.
class MockRouteRemoteDataSource implements RouteRemoteDataSource {
  MockRouteRemoteDataSource();

  List<CustomerStopInfoModel>? _customers;
  List<Map<String, dynamic>>? _routeJson;

  Future<void> _ensureLoaded() async {
    if (_customers != null) return;
    // Generate the dataset in-memory each launch rather than reading the
    // pre-baked `assets/mock/routes.json`: the asset's `visitDate` is frozen to
    // its generation day, so the dashboard's strict "today" filter rejects all
    // of it once the date rolls over. `MockRouteData.generate()` stamps
    // `DateTime.now()`, so routes always land on the current day.
    final generated = MockRouteData.generate();
    _customers = (generated['customers'] as List)
        .map((e) => CustomerStopInfoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    _routeJson = (generated['routes'] as List).cast<Map<String, dynamic>>();
  }

  List<RoutePlanModel> _routesForScope(RouteSyncScope scope) {
    final customersById = {for (final c in _customers!) c.id: c};
    final scoped = _routeJson!.where((r) => r['territory'] == scope.territory).toList();

    return scoped.map((routeJson) {
      final stopsJson = (routeJson['stops'] as List).cast<Map<String, dynamic>>();
      final stops = stopsJson
          .where((s) => customersById.containsKey(s['customerId']))
          .map((s) => RouteStopModel.fromJson(s, customer: customersById[s['customerId']]!))
          .toList();
      return RoutePlanModel.fromJson(routeJson, stops: stops);
    }).toList();
  }

  @override
  Future<RouteSyncPage> fetchInitial({
    required RouteSyncScope scope,
    required int page,
    required int pageSize,
  }) async {
    try {
      await _ensureLoaded();
      final routes = _routesForScope(scope);
      final start = page * pageSize;
      if (start >= routes.length) {
        return RouteSyncPage(customers: _customers!, routes: const [], hasMore: false);
      }
      final end = min(start + pageSize, routes.length);
      // Customers are sent alongside every page — the dataset is small
      // enough (300ish) that per-page filtering isn't worth the complexity.
      return RouteSyncPage(customers: _customers!, routes: routes.sublist(start, end), hasMore: end < routes.length);
    } catch (e) {
      throw ServerException(message: 'Initial route sync failed: $e');
    }
  }

  @override
  Future<RouteSyncPage> fetchDelta({required RouteSyncScope scope, required DateTime since}) async {
    try {
      await _ensureLoaded();
      final routes = _routesForScope(scope);
      return RouteSyncPage(customers: _customers!, routes: routes, hasMore: false);
    } catch (e) {
      throw ServerException(message: 'Delta route sync failed: $e');
    }
  }
}
