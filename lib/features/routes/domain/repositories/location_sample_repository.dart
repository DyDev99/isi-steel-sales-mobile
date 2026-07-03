import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/fraud_flag.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/location_sample.dart';

abstract interface class LocationSampleRepository {
  ResultFuture<void> recordSample(LocationSample sample);
  ResultFuture<List<LocationSample>> fetchSamples(String routeId);
  ResultFuture<void> recordFraudFlag(FraudFlag flag);
  ResultFuture<List<FraudFlag>> fetchFraudFlags(String routeId);
}
