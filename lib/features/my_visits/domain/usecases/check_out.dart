import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/check_out_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_repository.dart';

class CheckOut extends UseCase<CheckOutRecord, CheckOutRecord> {
  const CheckOut(this._repository);
  final VisitRepository _repository;
  @override
  ResultFuture<CheckOutRecord> call(CheckOutRecord params) =>
      _repository.checkOut(params);
}
