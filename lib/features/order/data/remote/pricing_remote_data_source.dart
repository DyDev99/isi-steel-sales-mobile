import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';

/// `GET /mobile/pricing/customers/{customerId}`.
abstract interface class PricingRemoteDataSource {
  /// One request for every material on the quotation.
  ///
  /// The endpoint's `materials` parameter repeats, so this batches rather than
  /// issuing one call per line — a rep adding an eighth material should not
  /// cost an eighth round trip.
  Future<List<DataMap>> fetchPrices({
    required String customerId,
    required List<String> materials,
  });
}

class ApiPricingRemoteDataSource implements PricingRemoteDataSource {
  const ApiPricingRemoteDataSource(this._client);

  final Dio _client;

  @override
  Future<List<DataMap>> fetchPrices({
    required String customerId,
    required List<String> materials,
  }) async {
    if (materials.isEmpty) return const [];

    try {
      final res = await _client.get<Object?>(
        AppConstants.customerPricingEndpoint(customerId),
        // A `List` value is serialised as a repeated key by Dio's default
        // `ListFormat.multi` — `?materials=A&materials=B`, which is the
        // contract. Joining them with a comma would arrive as one material
        // named "A,B" and price nothing.
        queryParameters: {'materials': materials},
      );
      return ApiListEnvelope.fromBody(res.data, key: 'prices').items;
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }
}
