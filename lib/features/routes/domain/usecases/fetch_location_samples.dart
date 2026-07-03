import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/location_sample_repository.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/routes_params.dart';

class FetchLocationSamples extends UseCase<List<LocationSample>, RouteIdParams> {
  const FetchLocationSamples(this._repository);
  final LocationSampleRepository _repository;
  @override
  ResultFuture<List<LocationSample>> call(RouteIdParams params) => _repository.fetchSamples(params.routeId);
}
