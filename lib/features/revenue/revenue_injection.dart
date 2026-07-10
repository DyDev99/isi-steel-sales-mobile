import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/features/revenue/data/datasources/local/revenue_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/revenue/data/repositories/revenue_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/repositories/revenue_repository.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_categories.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_customer_credit.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_discount_options.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_products.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/bloc/revenue_bloc.dart';

/// Registers the Revenue feature — UI only, backed entirely by mock data.
void registerRevenueFeature(GetIt sl) {
  // ── Data sources ────────────────────────────────────────────────────
  sl.registerLazySingleton<RevenueLocalDataSource>(
      () => const RevenueMockLocalDataSource());

  // ── Repositories ────────────────────────────────────────────────────
  sl.registerLazySingleton<RevenueRepository>(
      () => RevenueRepositoryImpl(sl()));

  // ── Use cases ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetProducts(sl()));
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => GetDiscountOptions(sl()));
  sl.registerLazySingleton(() => GetCustomerCredit(sl()));

  // ── Presentation ────────────────────────────────────────────────────
  sl.registerFactory(() => RevenueBloc(
        getProducts: sl(),
        getCategories: sl(),
        getDiscountOptions: sl(),
        getCustomerCredit: sl(),
      ));
}
