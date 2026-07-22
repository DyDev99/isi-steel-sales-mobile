import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/mock/mock_route_data.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_plan_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_stop_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/route_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/route_sync_page.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_sync_scope.dart';

/// Simulates a route-planning backend: loads the generated
/// `assets/mock/routes.json` once (falling back to generating it in-memory if
/// the asset is ever missing), then serves scoped/paged syncs from it.
///
/// **T1.5 Architecture Update:** To satisfy `route_stops.customer_id` FK 
/// constraints against the SAP-controlled `customers` table, this mock source 
/// now requires [CustomerLocalDataSource]. Before serving data, it fetches real 
/// synced customers and dynamically overwrites the mock IDs. Customer Sync MUST 
/// be run before Route Sync.
class MockRouteRemoteDataSource implements RouteRemoteDataSource {
  MockRouteRemoteDataSource(this._customerLocal);

  final CustomerLocalDataSource _customerLocal;

  List<CustomerStopInfoModel>? _customers;
  List<Map<String, dynamic>>? _routeJson;

  Future<void> _ensureLoaded() async {
    if (_customers != null) return;

    // 1. Fetch real synced customer IDs from local database (ADR-001 FK resolution)
    final realCustomers = await _customerLocal.browse(page: 0, pageSize: 300);
    if (realCustomers.isEmpty) {
      throw StateError(
        '[MockRouteRemote] needs at least one customer already synced '
        'locally to satisfy route_stops FK constraints. Run Customer Sync first.',
      );
    }
    final realCustomerIds = realCustomers.map((c) => c.id).toList();

    try {
      final raw = await rootBundle.loadString('assets/mock/routes.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      
      final jsonCustomers = (decoded['customers'] as List).cast<Map<String, dynamic>>();
      final jsonRoutes = (decoded['routes'] as List).cast<Map<String, dynamic>>();

      // 2. Patch the JSON payload dynamically to swap fake IDs with real synced IDs.
      final fakeToReal = <String, String>{};
      var cursor = 0;
      
      for (final cust in jsonCustomers) {
        final fakeId = cust['id'] as String;
        final realId = realCustomerIds[cursor++ % realCustomerIds.length];
        fakeToReal[fakeId] = realId;
        cust['id'] = realId; // Update JSON customer ID
      }

      for (final route in jsonRoutes) {
        final stops = (route['stops'] as List).cast<Map<String, dynamic>>();
        for (final stop in stops) {
           final fakeId = stop['customerId'] as String;
           if (fakeToReal.containsKey(fakeId)) {
             stop['customerId'] = fakeToReal[fakeId];
           }
        }
      }

      _customers = jsonCustomers
          .map((e) => CustomerStopInfoModel.fromJson(e))
          .toList();
      _routeJson = _rebaseToToday(jsonRoutes);
      
      if (kDebugMode) {
        debugPrint('[MockRouteRemote] loaded assets/mock/routes.json: '
            '${_routeJson!.length} routes, ${_customers!.length} customers '
            '(dates re-based to today, UTC, FKs patched)');
      }
    } catch (e) {
      // Asset missing/corrupt — generate an equivalent dataset in-memory. 
      // Pass the real IDs into the generator so it can fulfill FK constraints.
      final generated = MockRouteData.generate(realCustomerIds);
      _customers = (generated['customers'] as List)
          .map((e) => CustomerStopInfoModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _routeJson = _rebaseToToday(
          (generated['routes'] as List).cast<Map<String, dynamic>>());
      
      if (kDebugMode) {
        debugPrint('[MockRouteRemote] routes.json unavailable ($e) — '
            'generated ${_routeJson!.length} routes in-memory (FKs patched)');
      }
    }
  }

  /// Shifts the dataset's baked calendar dates onto **today (UTC)** so the
  /// dashboard's strict "today" filter always has routes to show, however long
  /// ago the asset was generated.
  List<Map<String, dynamic>> _rebaseToToday(List<Map<String, dynamic>> routes) {
    if (routes.isEmpty) return routes;
    
    DateTime asUtc(String iso) {
      final d = DateTime.parse(iso);
      return DateTime.utc(
          d.year, d.month, d.day, d.hour, d.minute, d.second, d.millisecond);
    }

    final firstVisit = asUtc(routes.first['visitDate'] as String);
    final assetDay =
        DateTime.utc(firstVisit.year, firstVisit.month, firstVisit.day);
    final nowUtc = DateTime.now().toUtc();
    final today = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final shift = today.difference(assetDay);

    String? bump(String? iso) =>
        iso == null ? null : asUtc(iso).add(shift).toIso8601String();

    return routes.map((route) {
      final shifted = Map<String, dynamic>.from(route)
        ..['visitDate'] = bump(route['visitDate'] as String)
        ..['plannedStart'] = bump(route['plannedStart'] as String)
        ..['plannedEnd'] = bump(route['plannedEnd'] as String);
      shifted['stops'] =
          (route['stops'] as List).cast<Map<String, dynamic>>().map((stop) {
        final s = Map<String, dynamic>.from(stop)
          ..['plannedArrival'] = bump(stop['plannedArrival'] as String)
          ..['plannedDeparture'] = bump(stop['plannedDeparture'] as String);
        if (stop['actualArrival'] != null) {
          s['actualArrival'] = bump(stop['actualArrival'] as String);
        }
        if (stop['actualDeparture'] != null) {
          s['actualDeparture'] = bump(stop['actualDeparture'] as String);
        }
        return s;
      }).toList();
      return shifted;
    }).toList();
  }

  List<RoutePlanModel> _routesForScope(RouteSyncScope scope) {
    final customersById = {for (final c in _customers!) c.id: c};
    final scoped =
        _routeJson!.where((r) => r['territory'] == scope.territory).toList();

    final mapped = scoped.map((routeJson) {
      final stopsJson =
          (routeJson['stops'] as List).cast<Map<String, dynamic>>();
      final stops = stopsJson
          .where((s) => customersById.containsKey(s['customerId']))
          .map((s) => RouteStopModel.fromJson(s,
              customer: customersById[s['customerId']]!))
          .toList();
      return RoutePlanModel.fromJson(routeJson, stops: stops);
    }).toList();

    if (kDebugMode) {
      debugPrint('[MockRouteRemote] scope "${scope.territory}": '
          '${mapped.length} routes mapped');
    }
    return mapped;
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
        return RouteSyncPage(
            customers: _customers!, routes: const [], hasMore: false);
      }
      final end = min(start + pageSize, routes.length);
      return RouteSyncPage(
          customers: _customers!,
          routes: routes.sublist(start, end),
          hasMore: end < routes.length);
    } catch (e) {
      throw ServerException(message: 'Initial route sync failed: $e');
    }
  }

  @override
  Future<RouteSyncPage> fetchDelta(
      {required RouteSyncScope scope, required DateTime since}) async {
    try {
      await _ensureLoaded();
      final routes = _routesForScope(scope);
      return RouteSyncPage(
          customers: _customers!, routes: routes, hasMore: false);
    } catch (e) {
      throw ServerException(message: 'Delta route sync failed: $e');
    }
  }
}