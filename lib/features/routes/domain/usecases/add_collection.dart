import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_collection.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/visit_repository.dart';

class AddCollection extends UseCase<void, VisitCollection> {
  const AddCollection(this._repository);
  final VisitRepository _repository;
  @override
  ResultFuture<void> call(VisitCollection params) => _repository.addCollection(params);
}
