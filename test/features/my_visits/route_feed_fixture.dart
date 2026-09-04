import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/api_route_remote_data_source.dart';

/// A stand-in for the live route feed, for tests that need routes to arrive
/// the way the app actually receives them.
///
/// This replaced `MockRouteRemoteDataSource`, which was deleted along with the
/// rest of the bundled route fixtures. The substitution is deliberate rather
/// than mechanical: the old mock built [RouteSyncPage] objects directly, so
/// every test using it skipped the JSON the real app has to parse. Scripting
/// the transport instead means these tests now exercise
/// [ApiRouteRemoteDataSource] end to end — envelope, field names, enum
/// strings, the customer/stop join — which is the layer most likely to drift
/// away from the backend contract.
///
/// [customerIds] is resolved *per request*, not once at construction: a caller
/// that syncs its customer directory first cannot know the ids until that has
/// run, and `route_stops.customer_id` is a live FK, so the feed has to name
/// customers that really exist locally.
Dio scriptedRouteFeed({
  required Future<List<String>> Function() customerIds,
  String territory = 'Phnom Penh',
  int stopsPerRoute = 3,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://routes.test'));
  dio.httpClientAdapter = _RouteFeedAdapter(
    customerIds: customerIds,
    territory: territory,
    stopsPerRoute: stopsPerRoute,
  );
  return dio;
}

class _RouteFeedAdapter implements HttpClientAdapter {
  _RouteFeedAdapter({
    required this.customerIds,
    required this.territory,
    required this.stopsPerRoute,
  });

  final Future<List<String>> Function() customerIds;
  final String territory;
  final int stopsPerRoute;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? stream,
      Future<void>? cancelFuture) async {
    final ids = await customerIds();

    // Anchored to the UTC calendar day, matching `RouteDao.fetchRoutesForDay`.
    // A local-midnight date lands on the previous UTC day in Cambodia (UTC+7)
    // and silently falls outside every "today" query — the bug the deleted
    // fixtures were repeatedly caught by.
    final now = DateTime.now().toUtc();
    final day = DateTime.utc(now.year, now.month, now.day);
    String at(int hour) => day.add(Duration(hours: hour)).toIso8601String();

    final stopIds = ids.take(stopsPerRoute).toList();

    final body = {
      'data': {
        'customers': [
          for (final id in stopIds)
            {
              'id': id,
              'name': 'ISI Hardware $id',
              'nameKh': 'ISI ហាឌវែរ $id',
              'code': 'C-$id',
              'contact': 'Sok Dara',
              'phone': '012345678',
              'address': 'Street 271',
              'territory': territory,
              'territoryType': 'industrial',
              'latitude': 11.55,
              'longitude': 104.91,
              'geofenceRadiusOverride': null,
            }
        ],
        'routes': [
          if (stopIds.isNotEmpty)
            {
              'id': 'route-today',
              'name': 'my_visits.route_info.plan_daily',
              'repId': 'rep-1',
              'repName': 'Rep One',
              'territory': territory,
              'visitDate': day.toIso8601String(),
              'plannedStart': at(8),
              'plannedEnd': at(17),
              'status': 'published',
              'stops': [
                for (var i = 0; i < stopIds.length; i++)
                  {
                    'id': 'stop-$i',
                    'routeId': 'route-today',
                    'customerId': stopIds[i],
                    'sequence': i + 1,
                    'plannedArrival': at(9 + i),
                    'plannedDeparture': at(9 + i),
                    'status': 'pending',
                    'actualArrival': null,
                    'actualDeparture': null,
                  }
              ],
            }
        ],
        'hasMore': false,
      },
      'message': null,
      'metadata': null,
    };

    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// A feed that names customers the local directory does not have.
///
/// `RouteDriftLocalDataSource.upsertCustomers` only *updates* existing rows —
/// the customer directory is SAP-owned and route sync may never invent one
/// (ADR-001) — so the stops then violate the `route_stops.customer_id` FK and
/// the whole transaction aborts. That is the real shape of "routes arrived
/// before the directory did", and it has to surface as a reported failure
/// rather than an empty dashboard with no explanation.
Dio unsatisfiableRouteFeed() =>
    scriptedRouteFeed(customerIds: () async => ['ghost-customer']);

/// A scripted customer feed for pipeline tests.
Dio scriptedCustomerFeed({int customerCount = 6}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://customers.test'));
  dio.httpClientAdapter = _CustomerFeedAdapter(customerCount: customerCount);
  return dio;
}

class _CustomerFeedAdapter implements HttpClientAdapter {
  _CustomerFeedAdapter({this.customerCount = 6});

  final int customerCount;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? stream,
      Future<void>? cancelFuture) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final body = {
      'data': {
        'customers': [
          for (var i = 1; i <= customerCount; i++)
            {
              'id': 'cust-$i',
              'sapCustomerId': 'SAP-$i',
              'customerCode': 'ISI-$i',
              'shopName': 'Hardware Shop $i',
              'ownerName': 'Owner $i',
              'phone': '01234567$i',
              'province': 'Phnom Penh',
              'district': 'Chamkar Mon',
              'territory': 'Phnom Penh',
              'status': 'Active',
              'latitude': 11.55,
              'longitude': 104.91,
              'creditLimit': {'amount': 50000.0, 'currency': 'USD'},
              'creditBalance': {'amount': 12000.0, 'currency': 'USD'},
            }
        ],
      },
      'message': null,
      'metadata': {
        'pageNumber': 1,
        'pageSize': customerCount,
        'hasNextPage': false,
        'syncTimestamp': now,
      },
    };

    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
