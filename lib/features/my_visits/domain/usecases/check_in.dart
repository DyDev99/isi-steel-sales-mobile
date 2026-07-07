import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/check_in_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_repository.dart';

class CheckIn extends UseCase<CheckInRecord, CheckInRecord> {
  const CheckIn(this._repository);
  final VisitRepository _repository;
  @override
  ResultFuture<CheckInRecord> call(CheckInRecord params) => _repository.checkIn(params);
}
