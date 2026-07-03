import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/route_repository.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/routes_params.dart';

class UpdateRouteStatus extends UseCase<void, UpdateRouteStatusParams> {
  const UpdateRouteStatus(this._repository);
  final RouteRepository _repository;
  @override
  ResultFuture<void> call(UpdateRouteStatusParams params) =>
      _repository.updateRouteStatus(params.routeId, params.status);
}
