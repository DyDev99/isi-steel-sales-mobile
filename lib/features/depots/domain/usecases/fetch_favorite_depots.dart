import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_repository.dart';

class FetchFavoriteDepots extends UseCase<List<Depot>, NoParams> {
  const FetchFavoriteDepots(this._repository);
  final DepotRepository _repository;

  @override
  ResultFuture<List<Depot>> call(NoParams params) =>
      _repository.fetchFavorites();
}
