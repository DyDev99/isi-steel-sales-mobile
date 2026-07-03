import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/fraud_flag.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/location_sample_repository.dart';

class RecordFraudFlag extends UseCase<void, FraudFlag> {
  const RecordFraudFlag(this._repository);
  final LocationSampleRepository _repository;
  @override
  ResultFuture<void> call(FraudFlag params) => _repository.recordFraudFlag(params);
}
