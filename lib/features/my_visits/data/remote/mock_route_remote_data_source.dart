import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/mock/mock_route_data.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_plan_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_stop_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/route_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/route_sync_page.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_sync_scope.dart';

/// Simulates a route-planning backend: loads the generated
/// `assets/mock/routes.json` once (falling back to generating it in-memory if
/// the asset is ever missing), then serves scoped/paged syncs from it — shaped
/// exactly like a real paginated REST source, so swapping in a Dio-backed
/// implementation later is mechanical. Mirrors `MockProductRemoteDataSource`.
///
/// `routes.json` is the single **source of truth** for the My Visits demo:
/// edit it (statuses, stops, customers) and the change flows through the whole
/// pipeline. The one transform applied at load is [_rebaseToToday] — the asset
/// bakes a concrete `visitDate`, but routes are *day-scoped* (the dashboard
/// filters strictly to today), so the baked day is shifted onto the current
/// day. All relative offsets (planned↔actual, stop sequencing) are preserved;
/// only the anchor day moves, which is what keeps the asset from going stale at
/// midnight.
class MockRouteRemoteDataSource implements RouteRemoteDataSource {
  MockRouteRemoteDataSource();

  List<CustomerStopInfoModel>? _customers;
  List<Map<String, dynamic>>? _routeJson;

  Future<void> _ensureLoaded() async {
    if (_customers != null) return;
    try {
      final raw = await rootBundle.loadString('assets/mock/routes.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _customers = (decoded['customers'] as List)
          .map((e) => CustomerStopInfoModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _routeJson = _rebaseToToday(
          (decoded['routes'] as List).cast<Map<String, dynamic>>());
      if (kDebugMode) {
        debugPrint('[MockRouteRemote] loaded assets/mock/routes.json: '
            '${_routeJson!.length} routes, ${_customers!.length} customers '
            '(dates re-based to today, UTC)');
      }
    } catch (e) {
      // Asset missing/corrupt — generate an equivalent dataset in-memory. Run
      // it through the same re-base so its (locally-stamped) dates land on the
      // UTC day the DAO's "today" query selects, exactly like the asset path.
      final generated = MockRouteData.generate();
      _customers = (generated['customers'] as List)
          .map((e) => CustomerStopInfoModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _routeJson = _rebaseToToday(
          (generated['routes'] as List).cast<Map<String, dynamic>>());
      if (kDebugMode) {
        debugPrint('[MockRouteRemote] routes.json unavailable ($e) — '
            'generated ${_routeJson!.length} routes in-memory');
      }
    }
  }

  /// Shifts the dataset's baked calendar dates onto **today (UTC)** so the
  /// dashboard's strict "today" filter always has routes to show, however long
  /// ago the asset was generated.
  ///
  /// Timezone correctness matters here: `visit_date` is persisted as UTC text
  /// and `RouteDao.watchRoutesForDay` selects the **UTC** calendar day of
  /// `DateTime.now().toUtc()`. Anchoring on the *local* day (as the raw asset
  /// and generator do) makes local-midnight land on the previous UTC day in any
  /// positive-offset zone (e.g. Cambodia UTC+7) — the routes then fall outside
  /// the query window and the screen reads empty. So the naive asset timestamps
  /// are reinterpreted as UTC and re-anchored to UTC-today; only the anchor day
  /// moves, every relative offset (planned↔actual, stop sequencing) is kept.
  List<Map<String, dynamic>> _rebaseToToday(List<Map<String, dynamic>> routes) {
    if (routes.isEmpty) return routes;
    // Reinterpret a naive "wall clock" ISO string as UTC, dropping any device
    // timezone from the equation entirely.
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
      // Customers are sent alongside every page — the dataset is small
      // enough (300ish) that per-page filtering isn't worth the complexity.
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
