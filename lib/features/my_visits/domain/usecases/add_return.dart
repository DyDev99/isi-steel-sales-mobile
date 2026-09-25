import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_return.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_repository.dart';

class AddReturn extends UseCase<void, VisitReturn> {
  const AddReturn(this._repository);
  final VisitRepository _repository;
  @override
  ResultFuture<void> call(VisitReturn params) => _repository.addReturn(params);
}
