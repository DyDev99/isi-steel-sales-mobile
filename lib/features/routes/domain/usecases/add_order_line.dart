import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_order_line.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/visit_repository.dart';

class AddOrderLine extends UseCase<void, VisitOrderLine> {
  const AddOrderLine(this._repository);
  final VisitRepository _repository;
  @override
  ResultFuture<void> call(VisitOrderLine params) => _repository.addOrderLine(params);
}
