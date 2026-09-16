import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/depot_params.dart';

class AddDepotActivity extends UseCase<void, AddDepotActivityParams> {
  const AddDepotActivity(this._repository);
  final DepotRepository _repository;

  @override
  ResultFuture<void> call(AddDepotActivityParams params) =>
      _repository.addActivity(params.activity);
}
