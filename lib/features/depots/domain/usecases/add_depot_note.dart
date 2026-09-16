import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/depot_params.dart';

class AddDepotNote extends UseCase<void, AddDepotNoteParams> {
  const AddDepotNote(this._repository);
  final DepotRepository _repository;

  @override
  ResultFuture<void> call(AddDepotNoteParams params) =>
      _repository.addNote(params.depotId, params.body);
}
