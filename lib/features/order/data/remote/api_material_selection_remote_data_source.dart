import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/features/order/data/models/category_filter_schema_model.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/material_selection_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';

/// `/api/v1/mobile/materials/selection/*` — the real thing.
///
/// Three of the four endpoints answer the standard envelope with a **JSON
/// array** at `data`, which is why every read here goes through
/// [ApiListEnvelope] rather than [ApiEnvelope].
///
/// Every method needs `materials.read`. A 403 with no `errorCode` on all of
/// them means the caller's role is missing that permission in the database —
/// a roles-screen fix, not a client one, and nothing here should try to work
/// around it.
class ApiMaterialSelectionRemoteDataSource
    implements MaterialSelectionRemoteDataSource {
  const ApiMaterialSelectionRemoteDataSource(this._client);

  final Dio _client;

  @override
  Future<List<DataMap>> fetchCategories({bool includeBlocked = false}) async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.materialCategoriesEndpoint,
        queryParameters: {'includeBlocked': includeBlocked},
      );
      return ApiListEnvelope.fromBody(res.data, key: 'categories').items;
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<List<CategoryFilterSchemaModel>> fetchSchemas(
      {String? categoryCode}) async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.materialSchemaEndpoint,
        queryParameters: {
          if (categoryCode != null && categoryCode.isNotEmpty)
            'categoryCode': categoryCode,
        },
      );
      return ApiListEnvelope.fromBody(res.data, key: 'schemas')
          .items
          .map(CategoryFilterSchemaModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<List<DataMap>> fetchFacetOptions({
    required String attribute,
    required Map<String, dynamic> selection,
  }) async {
    try {
      final res = await _client.post<Object?>(
        AppConstants.materialFacetsEndpoint,
        // `{attribute, selection}`. The terminal read below takes a different
        // body, and the two are not interchangeable — see the note there.
        data: {'attribute': attribute, 'selection': selection},
      );
      return ApiListEnvelope.fromBody(res.data, key: 'options').items;
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<MaterialPage> fetchMaterials({
    required Map<String, dynamic> selection,
    required int page,
    required int pageSize,
    String? search,
  }) async {
    try {
      final res = await _client.post<Object?>(
        AppConstants.materialSelectionEndpoint,
        // `{selection, page, pageSize, search}` — the selection stays nested.
        // Flattening it here is not an error the server reports; it is read as
        // an empty selection, which then fails the bounded check for a reason
        // that has nothing to do with what the rep actually chose.
        data: {
          'selection': selection,
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      final envelope = ApiListEnvelope.fromBody(res.data, key: 'materials');
      final meta = envelope.metadata;
      return MaterialPage(
        rows: envelope.items,
        hasMore: meta?.hasNextPage ?? false,
        totalRecords: meta?.totalRecords ?? envelope.items.length,
      );
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<DataMap> fetchAvailability(
    String material, {
    String? salesOrg,
    String? disChannel,
    String? division,
    String? plant,
  }) async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.materialAvailabilityEndpoint(material),
        queryParameters: {
          // Sent only when known. SAP treats all three as mandatory and
          // answers 200 with `INPUT_*` checks when they are absent, so an
          // empty string here would be worse than an omission: it looks like
          // an answer.
          if (salesOrg != null && salesOrg.isNotEmpty) 'salesOrg': salesOrg,
          if (disChannel != null && disChannel.isNotEmpty)
            'disChannel': disChannel,
          if (division != null && division.isNotEmpty) 'division': division,
          if (plant != null && plant.isNotEmpty) 'plant': plant,
        },
      );
      // This endpoint answers `{data, meta}` rather than the selection
      // surface's `{data: [...]}`, so it reads through the object envelope.
      return ApiEnvelope.fromBody(res.data).data;
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }
}
