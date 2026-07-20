import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_service.dart';
import 'package:isi_steel_sales_mobile/core/api_client/endpoints/sap_endpoints.dart';
import 'package:isi_steel_sales_mobile/core/config/app_config.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/customer_sap_remote_datasource.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/dto/sap_business_partner.dart';

/// Talks to the SAP façade's `Customer` controller.
///
/// Depends only on [ApiService] — no `dio` import, no `Response`, no
/// `DioException`. Transport concerns (TLS pinning, bearer tokens, renewal,
/// timeouts, retry, connectivity, logging) all sit behind that interface, which
/// is why this class is a pure translation of endpoint shapes and payloads and
/// can be unit-tested with a fake `ApiService`.
class CustomerSapRemoteDataSourceImpl implements CustomerSapRemoteDataSource {
  const CustomerSapRemoteDataSourceImpl(this._api, {String? conId})
      : _overrideConId = conId;

  final ApiService _api;
  final String? _overrideConId;

  String get _conId => _overrideConId ?? SapConfig.conId;

  @override
  Future<SapBusinessPartner?> read(String customerNumber) async {
    final response = await _api.get<Object?>(
      SapEndpoints.readCustomer(_conId, customerNumber),
      // A 404 here means SAP holds no such customer — an absence, not a fault.
      allowEmpty: true,
    );

    final body = response.data;
    if (body is! Map) return null;
    return SapBusinessPartner.fromJson(Map<String, dynamic>.from(body));
  }

  @override
  Future<SapCustomerPage> fetchPage({
    required int page,
    required int pageSize,
    String? salesOrg,
    String? division,
    String? nameFilter,
  }) async {
    final response = await _api.get<Object?>(
      SapEndpoints.customerPaging(_conId),
      queryParameters: _filters(
        salesOrg: salesOrg,
        division: division,
        nameFilter: nameFilter,
        extra: {
          SapEndpoints.qPage: page,
          SapEndpoints.qPageSize: pageSize,
        },
      ),
      allowEmpty: true,
    );

    final body = response.data;

    // "No rows matched" (§4.4). An empty page with totalPages 0 stops the sync
    // loop cleanly rather than raising an error the UI would have to special-case.
    if (body == null) return SapCustomerPage.empty;

    if (body is Map) {
      return SapCustomerPage.fromJson(Map<String, dynamic>.from(body));
    }

    // Defensive: should the endpoint ever answer with a bare array instead of
    // the documented envelope (§5.3), treat it as one complete page rather than
    // failing outright.
    if (body is List) {
      final rows = body
          .whereType<Map>()
          .map((r) => SapBusinessPartner.fromJson(Map<String, dynamic>.from(r)))
          .toList(growable: false);
      return SapCustomerPage(
        page: page,
        pageSize: pageSize,
        totalCount: rows.length,
        totalPages: 1,
        rows: rows,
      );
    }

    return SapCustomerPage.empty;
  }

  @override
  Future<List<SapBusinessPartner>> fetchDetail({
    String? customerNumber,
    String? salesOrg,
    String? division,
    String? nameFilter,
  }) async {
    final response = await _api.get<Object?>(
      SapEndpoints.customerDetail(_conId),
      queryParameters: _filters(
        salesOrg: salesOrg,
        division: division,
        nameFilter: nameFilter,
        extra: {
          if (customerNumber != null) SapEndpoints.qCustomer: customerNumber,
        },
      ),
      allowEmpty: true,
    );

    final body = response.data;
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((r) => SapBusinessPartner.fromJson(Map<String, dynamic>.from(r)))
        .toList(growable: false);
  }

  /// Builds the query map, omitting absent filters entirely.
  ///
  /// SAP treats an omitted filter as "return everything" (§4.1), so sending
  /// `salesOrg=` is not equivalent to leaving the key out. Omission is the
  /// documented way to express "no filter".
  Map<String, dynamic> _filters({
    String? salesOrg,
    String? division,
    String? nameFilter,
    Map<String, dynamic> extra = const {},
  }) =>
      {
        if (salesOrg != null && salesOrg.isNotEmpty)
          SapEndpoints.qSalesOrg: salesOrg,
        if (division != null && division.isNotEmpty)
          SapEndpoints.qDivision: division,
        if (nameFilter != null && nameFilter.isNotEmpty)
          SapEndpoints.qEnName: nameFilter,
        ...extra,
      };
}
