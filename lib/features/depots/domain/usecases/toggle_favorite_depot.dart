import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/depot_params.dart';

class ToggleFavoriteDepot extends UseCase<void, DepotIdParams> {
  const ToggleFavoriteDepot(this._repository);
  final DepotRepository _repository;

  @override
  ResultFuture<void> call(DepotIdParams params) =>
      _repository.toggleFavorite(params.depotId);
}
