import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/add_customer_bloc.dart';

/// Registers the Home feature's dependencies.
///
/// Today this is the "Add Customer" bloc surfaced from the home dashboard and
/// the customer directory. Register future Home datasources, repositories and
/// use cases above the bloc, following the standard
/// `register<Feature>Feature(GetIt sl)` convention used by every feature.
///
/// Resolved lazily inside the factory, so registration order relative to
/// `registerCustomerFeature` does not matter.
void registerHomeFeature(GetIt sl) {
  sl.registerFactory(() => AddCustomerBloc(createCustomer: sl()));
}
