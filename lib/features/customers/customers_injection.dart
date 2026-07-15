import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/mock_customer_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/customer_sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_sync_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/add_customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/add_customer_note.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/browse_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_customer_activities.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_customer_notes.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_favorite_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_recent_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_by_id.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/record_customer_viewed.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/toggle_favorite_customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_bloc.dart';

/// Registers the approved-customer directory. Persistence is the single
/// SQLCipher-encrypted Drift database (`AppDatabase`) via [CustomerDao] — the
/// legacy plaintext `customers.db` was retired in the T2 cutover.
Future<void> registerCustomerFeature(GetIt sl) async {
  // ── Data sources ────────────────────────────────────────────────────
  sl.registerLazySingleton<CustomerLocalDataSource>(
      () => CustomerDriftLocalDataSource(sl<AppDatabase>().customerDao));
  sl.registerLazySingleton<CustomerRemoteDataSource>(
      () => MockCustomerRemoteDataSource());

  // ── Repositories ────────────────────────────────────────────────────
  sl.registerLazySingleton<CustomerRepository>(
      () => CustomerRepositoryImpl(sl()));
  sl.registerLazySingleton<CustomerSyncRepository>(
    () => CustomerSyncRepositoryImpl(
        remote: sl(), local: sl(), network: sl<NetworkInfo>()),
  );

  // ── Use cases ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => BrowseCustomers(sl()));
  sl.registerLazySingleton(() => GetCustomerById(sl()));
  sl.registerLazySingleton(() => ToggleFavoriteCustomer(sl()));
  sl.registerLazySingleton(() => FetchFavoriteCustomers(sl()));
  sl.registerLazySingleton(() => FetchRecentCustomers(sl()));
  sl.registerLazySingleton(() => RecordCustomerViewed(sl()));
  sl.registerLazySingleton(() => FetchCustomerNotes(sl()));
  sl.registerLazySingleton(() => AddCustomerNote(sl()));
  sl.registerLazySingleton(() => FetchCustomerActivities(sl()));
  sl.registerLazySingleton(() => AddCustomerActivity(sl()));
  sl.registerLazySingleton(() => RunCustomerInitialSync(sl()));
  sl.registerLazySingleton(() => RunCustomerDeltaSync(sl()));
  sl.registerLazySingleton(() => GetCustomerLastSyncedAt(sl()));

  // ── Presentation ────────────────────────────────────────────────────
  sl.registerFactory(() => CustomersBloc(
        browseCustomers: sl(),
        fetchRecentCustomers: sl(),
        toggleFavoriteCustomer: sl(),
      ));
  sl.registerFactory(() => CustomerDetailCubit(
        getCustomerById: sl(),
        fetchCustomerNotes: sl(),
        addCustomerNote: sl(),
        fetchCustomerActivities: sl(),
        addCustomerActivity: sl(),
        recordCustomerViewed: sl(),
      ));
  sl.registerFactory(() => CustomerSyncCubit(
        runInitialSync: sl(),
        runDeltaSync: sl(),
        getLastSyncedAt: sl(),
      ));
}
