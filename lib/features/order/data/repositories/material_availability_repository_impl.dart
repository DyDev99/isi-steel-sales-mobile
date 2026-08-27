import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/models/material_api_mapper.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/material_selection_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/material_availability.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/material_availability_repository.dart';

/// The sellability check, over the middleware's live SAP passthrough.
///
/// ## The sales area
///
/// SAP needs `salesOrg`, `disChannel` and `division` to answer at all. None of
/// them is currently carried by the session, so none is sent, and SAP responds
/// **HTTP 200** with `isSellable: false` and `INPUT_VKORG` / `INPUT_VTWEG`
/// checks — "Validation not performed. Mandatory input parameters are
/// missing."
///
/// That is a client-side gap, not a business verdict, and
/// [MaterialAvailability.isInputIncomplete] keeps the distinction readable all
/// the way to the UI even where the badge currently renders both as "No stock".
///
/// TODO(release-gate): resolve the sales area from the signed-in rep's
/// assignment and pass it through [_salesOrg] / [_disChannel] / [_division].
/// Until that lands every material reads as unsellable, which is safe (it
/// never invents a yes) but uninformative.
class MaterialAvailabilityRepositoryImpl
    implements MaterialAvailabilityRepository {
  const MaterialAvailabilityRepositoryImpl({
    required MaterialSelectionRemoteDataSource remote,
    required NetworkInfo network,
    String? salesOrg,
    String? disChannel,
    String? division,
    String? plant,
  })  : _remote = remote,
        _network = network,
        _salesOrg = salesOrg,
        _disChannel = disChannel,
        _division = division,
        _plant = plant;

  final MaterialSelectionRemoteDataSource _remote;
  final NetworkInfo _network;

  final String? _salesOrg;
  final String? _disChannel;
  final String? _division;
  final String? _plant;

  @override
  ResultFuture<MaterialAvailability> checkAvailability(String material) async {
    if (material.trim().isEmpty) {
      return const Failed(
          ServerFailure(message: 'No material number to check.'));
    }

    // Checked up front because this is the one call in the feature that
    // genuinely cannot work offline. Letting it fail at the socket would
    // surface a transport error where the honest answer is "not asked yet" —
    // and the flow renders an unchecked material differently from a refused
    // one for exactly that reason.
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }

    try {
      final json = await _remote.fetchAvailability(
        material.trim(),
        salesOrg: _salesOrg,
        disChannel: _disChannel,
        division: _division,
        plant: _plant,
      );
      return Success(
          MaterialApiMapper.availabilityFrom(json, requested: material.trim()));
    } on ApiException catch (e) {
      return Failed(ServerFailure(
        message: e.error.message ?? 'Could not check stock availability.',
        statusCode: e.statusCode,
      ));
    } on ServerException catch (e) {
      return Failed(ServerFailure(message: e.message));
    }
  }
}
