import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_repository.dart';

class AddVisitPhoto extends UseCase<void, VisitPhoto> {
  const AddVisitPhoto(this._repository);
  final VisitRepository _repository;
  @override
  ResultFuture<void> call(VisitPhoto params) => _repository.addPhoto(params);
}
