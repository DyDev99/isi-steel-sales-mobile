import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_note.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/depot_params.dart';

class FetchDepotNotes extends UseCase<List<DepotNote>, DepotIdParams> {
  const FetchDepotNotes(this._repository);
  final DepotRepository _repository;

  @override
  ResultFuture<List<DepotNote>> call(DepotIdParams params) =>
      _repository.fetchNotes(params.depotId);
}
