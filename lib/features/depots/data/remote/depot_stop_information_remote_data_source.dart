import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/models/depot_stop_information_mapper.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_stop_information.dart';

/// `GET /api/v1/mobile/depots/{depotId}/stop-information`.
abstract interface class DepotStopInformationRemoteDataSource {
  /// Requires `customers.read`.
  ///
  /// A **404 means "not available to you"** and covers both "no such outlet"
  /// and "outside your entitlement" — the server makes them deliberately
  /// indistinguishable, so a caller must not present it as "deleted".
  Future<DepotStopInformation> fetch(String depotId);
}

class ApiDepotStopInformationRemoteDataSource
    implements DepotStopInformationRemoteDataSource {
  const ApiDepotStopInformationRemoteDataSource(this._client);

  final Dio _client;

  @override
  Future<DepotStopInformation> fetch(String depotId) async {
    try {
      final res = await _client
          .get<DataMap>(AppConstants.depotStopInformationEndpoint(depotId));
      return DepotStopInformationMapper.fromData(
          ApiEnvelope.fromBody(res.data).data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }
}
