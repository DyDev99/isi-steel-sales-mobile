import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_note.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/visit_repository.dart';

class AddVisitNote extends UseCase<void, VisitNote> {
  const AddVisitNote(this._repository);
  final VisitRepository _repository;
  @override
  ResultFuture<void> call(VisitNote params) => _repository.addNote(params);
}
