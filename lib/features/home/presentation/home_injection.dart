// 1. Add the correct path import at the top of your file
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/add_customer_bloc.dart';
// ADD THIS IMPORT AT THE TOP OF YOUR FILE
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
// 2. Locate your main initialization function (e.g., Future<void> init() async)
// and register the factory alongside your other Cubits/Blocs:
void initCustomerFeatures() {
  
  // ==========================================================================
  // Features - Customer Onboarding Pipeline
  // ==========================================================================
  
  // Bloc Registration
  sl.registerFactory(() => AddCustomerBloc());
  
  // Note: If you eventually add DataSources, Repositories, or UseCases for this feature,
  // register them as lazySingletons right above the Bloc like this:
  // sl.registerLazySingleton(() => CustomerRepository());
}