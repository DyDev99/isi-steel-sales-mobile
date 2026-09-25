import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_activity.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/depot_params.dart';

class FetchDepotActivities extends UseCase<List<DepotActivity>, DepotIdParams> {
  const FetchDepotActivities(this._repository);
  final DepotRepository _repository;

  @override
  ResultFuture<List<DepotActivity>> call(DepotIdParams params) =>
      _repository.fetchActivities(params.depotId);
}
