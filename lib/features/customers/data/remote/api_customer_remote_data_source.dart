import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_api_mapper.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_draft.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_sync_page.dart';

/// `GET /api/v1/mobile/customers` — the real thing.
///
/// Both list calls read the same envelope: the rows live at
/// `data.customers` and the paging plus sync bookkeeping at `metadata`.
class ApiCustomerRemoteDataSource implements CustomerRemoteDataSource {
  const ApiCustomerRemoteDataSource(this._client);

  final Dio _client;

  @override
  Future<CustomerInitialPage> fetchInitial({
    required int page,
    required int pageSize,
  }) async {
    final envelope = await _list({
      // The API is one-based. The sync repository counts from 1 to match;
      // sending 0 would silently be treated as 1 and re-fetch the first page.
      'pageNumber': page,
      'pageSize': pageSize,
      // A stable order matters across pages: without it the server is free to
      // return rows in a different order per page and a paged run can both
      // miss and duplicate records.
      'sort': 'updatedAt',
    });

    final meta = envelope.metadata;
    return CustomerInitialPage(
      items: envelope
          .list('customers')
          .map(CustomerApiMapper.fromSummary)
          .toList(),
      hasMore: meta?.hasNextPage ?? false,
      syncTimestamp: meta?.syncTimestamp,
      // Read back rather than echoed: `pageSize` is clamped to 200, not
      // rejected, so what was asked for is not necessarily what was used.
      pageSize: meta?.pageSize,
    );
  }

  @override
  Future<CustomerDeltaPage> fetchDelta({
    required DateTime since,
    int page = 1,
    int pageSize = AppConstants.maxPageSize,
  }) async {
    final envelope = await _list({
      // Always the server's own previous `syncTimestamp`, never a device
      // clock. A `modifiedSince` more than five minutes ahead of server time
      // is rejected outright.
      'modifiedSince': since.toUtc().toIso8601String(),
      'pageNumber': page,
      'pageSize': pageSize,
      // `includeDeleted` is implied by `modifiedSince`, but stating it keeps
      // the intent obvious: this call *must* return tombstones.
      'includeDeleted': true,
      'sort': 'updatedAt',
    });

    final rows =
        envelope.list('customers').map(CustomerApiMapper.fromSummary).toList();

    // Split once, here, so the repository never has to remember to check the
    // flag — dropping tombstones on the floor leaves deleted shops on the
    // phone forever.
    final upserted = <CustomerModel>[];
    final deletedIds = <String>[];
    for (final row in rows) {
      if (row.deleted) {
        deletedIds.add(row.id);
      } else {
        upserted.add(row);
      }
    }

    final meta = envelope.metadata;
    return CustomerDeltaPage(
      upserted: upserted,
      deletedIds: deletedIds,
      hasMore: meta?.hasNextPage ?? false,
      syncTimestamp: meta?.syncTimestamp,
    );
  }

  @override
  Future<CustomerModel> fetchById(String id) async {
    try {
      final res = await _client
          .get<DataMap>('${AppConstants.customersEndpoint}/$id');
      final envelope = ApiEnvelope.fromBody(res.data);

      // Wrapped one level deeper than the list: `data.customer`, not `data`.
      final customer = envelope.object('customer');
      if (customer == null) {
        throw const ServerException(
            message: 'The customer response was missing its payload.');
      }
      return CustomerApiMapper.fromDetail(customer);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<CustomerModel> create(CustomerDraft draft) async {
    try {
      final res = await _client.post<DataMap>(
        AppConstants.customersEndpoint,
        data: draft.toJson(),
      );
      final envelope = ApiEnvelope.fromBody(res.data);

      // 201 returns the created customer with a `Location` header. The body is
      // wrapped the same way the detail route is, but fall back to the flatter
      // shape rather than losing a customer the server has already committed —
      // the row exists either way, and failing here would leave the rep
      // believing the shop was never registered.
      final created = envelope.object('customer') ?? envelope.data;
      return CustomerApiMapper.fromDetail(created);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  Future<ApiEnvelope> _list(DataMap query) async {
    try {
      final res = await _client.get<DataMap>(
        AppConstants.customersEndpoint,
        queryParameters: query,
      );
      return ApiEnvelope.fromBody(res.data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }
}
