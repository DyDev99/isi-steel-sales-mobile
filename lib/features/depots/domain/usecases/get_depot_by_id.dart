import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/depot_params.dart';

class GetDepotById extends UseCase<Depot, DepotIdParams> {
  const GetDepotById(this._repository);
  final DepotRepository _repository;

  @override
  ResultFuture<Depot> call(DepotIdParams params) =>
      _repository.getById(params.depotId);
}
