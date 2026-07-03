import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/route_repository.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/routes_params.dart';

class UpdateStopStatus extends UseCase<void, UpdateStopStatusParams> {
  const UpdateStopStatus(this._repository);
  final RouteRepository _repository;
  @override
  ResultFuture<void> call(UpdateStopStatusParams params) => _repository.updateStopStatus(
        params.stopId,
        status: params.status,
        actualArrival: params.actualArrival,
        actualDeparture: params.actualDeparture,
      );
}
