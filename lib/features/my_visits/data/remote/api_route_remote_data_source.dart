import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_plan_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_stop_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/route_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/route_sync_page.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_sync_scope.dart';

/// `GET /api/v1/mobile/visits/routes` and `…/routes/delta` — the real thing.
///
/// The sole implementation of [RouteRemoteDataSource]. It replaced a fixture
/// source behind the same interface, so `RouteSyncRepositoryImpl` and
/// everything above it were untouched by the cutover.
///
/// Both calls read the same envelope — `data.customers`, `data.routes` and
/// `data.hasMore` (`docs/backend-document.md` §5).
class ApiRouteRemoteDataSource implements RouteRemoteDataSource {
  const ApiRouteRemoteDataSource(this._client);

  final Dio _client;

  @override
  Future<RouteSyncPage> fetchInitial({
    required RouteSyncScope scope,
    required int page,
    required int pageSize,
  }) async {
    return _page(AppConstants.visitRoutesEndpoint, {
      ..._territory(scope),
      // **The interface is 0-based, the API is 1-based.** `RouteSyncPage`'s
      // contract was set by the mock, whose paging is `page * pageSize`, and
      // the repository counts from 0 to match. Converting here rather than
      // changing either keeps this a pure adapter concern — and the conversion
      // is not cosmetic: the customer endpoint silently treats page 0 as page
      // 1, so an unconverted first call would re-fetch page 1 twice and the
      // last page would never be read.
      'page': page + 1,
      'pageSize': pageSize,
    });
  }

  @override
  Future<RouteSyncPage> fetchDelta({
    required RouteSyncScope scope,
    required DateTime since,
  }) async {
    return _page(AppConstants.visitRoutesDeltaEndpoint, {
      ..._territory(scope),
      // The watermark the repository stored from the last successful sync.
      // Sent as UTC so it cannot be read in the wrong zone; the server may use
      // it to short-circuit with an empty page, but is documented to be free
      // to return the rep's complete current set every time — which is what
      // the client expects and what the repository is built to absorb.
      'since': since.toUtc().toIso8601String(),
    });
  }

  /// The territory filter, omitted entirely when the profile named none.
  ///
  /// Sending `territory=` (empty) would have the server match a territory
  /// literally called "", which returns nothing; leaving the key off lets it
  /// scope from the bearer token alone, which is the honest fallback.
  static DataMap _territory(RouteSyncScope scope) =>
      scope.hasTerritory ? {'territory': scope.territory} : const {};

  /// Reads one page of the shared route body.
  ///
  /// Note what is *not* sent: `repId`. The rep identity comes from the bearer
  /// token server-side (`docs/backend-document.md` §5, §8.1). A client-supplied
  /// rep id would be an authorisation claim the client is not entitled to make,
  /// and the server is required to ignore it — so sending it would only
  /// suggest otherwise. [RouteSyncScope.repId] stays local, for local scoping.
  Future<RouteSyncPage> _page(String path, DataMap query) async {
    final ApiEnvelope envelope;
    try {
      final res = await _client.get<DataMap>(path, queryParameters: query);
      envelope = ApiEnvelope.fromBody(res.data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }

    // Customers first: stops resolve against them, and a stop whose customer
    // is missing cannot be built at all.
    final customers =
        envelope.list('customers').map(CustomerStopInfoModel.fromJson).toList();
    final customersById = {for (final c in customers) c.id: c};

    final routes = <RoutePlanModel>[];
    for (final routeJson in envelope.list('routes')) {
      final stopsJson = (routeJson['stops'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>());

      // Drop a stop whose customer is absent from the payload rather than
      // failing the page. `customers` is documented as a flat de-duplicated
      // list covering every stop, so a miss is a server bug — but taking the
      // rep's whole route down over one unresolvable stop is the worse
      // failure, and this is the same tolerance the mock source applies.
      final stops = [
        for (final stopJson in stopsJson)
          if (customersById[stopJson['customerId']] case final customer?)
            RouteStopModel.fromJson(stopJson, customer: customer),
      ];

      routes.add(RoutePlanModel.fromJson(routeJson, stops: stops));
    }

    return RouteSyncPage(
      customers: customers,
      routes: routes,
      // Absent means "no more" — the delta endpoint is a single full page and
      // is not documented to send the flag at all.
      hasMore: envelope.data['hasMore'] as bool? ?? false,
    );
  }
}
