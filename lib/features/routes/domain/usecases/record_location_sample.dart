import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/location_sample_repository.dart';

class RecordLocationSample extends UseCase<void, LocationSample> {
  const RecordLocationSample(this._repository);
  final LocationSampleRepository _repository;
  @override
  ResultFuture<void> call(LocationSample params) => _repository.recordSample(params);
}
