import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/hive_service.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/local_cache.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/master_data_cache.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/api_customer_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/master_data_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/mock_master_data_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/business_partner_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_datasources.dart'
    as bp;
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/customer_sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/master_data_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/business_partner_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_sync_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/master_data_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/add_customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/add_customer_note.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/create_customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/browse_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_customer_activities.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_customer_notes.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_favorite_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_recent_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_by_id.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_master_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/refresh_master_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/record_customer_viewed.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/toggle_favorite_customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/add_customer_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';

/// Registers the approved-customer directory. Persistence is the single
/// SQLCipher-encrypted Drift database (`AppDatabase`) via [CustomerDao] — the
/// legacy plaintext `customers.db` was retired in the T2 cutover.
Future<void> registerCustomerFeature(GetIt sl) async {
  // ── Data sources ────────────────────────────────────────────────────
  sl.registerLazySingleton<CustomerLocalDataSource>(
      () => CustomerDriftLocalDataSource(sl<AppDatabase>().customerDao));

  // The customer *directory* feed — `GET /mobile/customers`, consumed by
  // CustomerSyncRepositoryImpl.
  //
  // Note there are two unrelated interfaces named `CustomerRemoteDataSource`:
  // this one (`data/remote/customer_remote_data_source.dart`) and the BP
  // registration one below, imported as `bp`. They are different types, so
  // registering one does NOT satisfy the other — omitting this line fails at
  // runtime, not compile time, with "CustomerRemoteDataSource is not
  // registered" when the Customers screen builds.
  sl.registerLazySingleton<CustomerRemoteDataSource>(
      () => ApiCustomerRemoteDataSource(sl<Dio>()));

  // SAP Customer Helper master data (ADR-009). Cached in Hive rather than
  // Drift because these are regenerable lookups, not business records
  // (ARCHITECTURE.md §3, Layer 2) — so this needs no schema migration.
  sl.registerLazySingleton<MasterDataRemoteDataSource>(
      () => const MockMasterDataRemoteDataSource());
  sl.registerLazySingleton<MasterDataCache>(
      () => MasterDataCache(LocalCache(HiveService.cacheBox)));

  // ── Repositories ────────────────────────────────────────────────────
  sl.registerLazySingleton<CustomerRepository>(
      () => CustomerRepositoryImpl(sl()));
  sl.registerLazySingleton<bp.CustomerRemoteDataSource>(
      () => bp.CustomerRemoteDataSourceImpl(sl<Dio>()));
  sl.registerLazySingleton<BusinessPartnerRepository>(
      () => BusinessPartnerRepositoryImpl(sl<bp.CustomerRemoteDataSource>()));
  sl.registerLazySingleton<CustomerSyncRepository>(
    () => CustomerSyncRepositoryImpl(
      remote: sl(),
      local: sl(),
      network: sl<NetworkInfo>(),
      logger: sl<AppLogger>(),
    ),
  );
  sl.registerLazySingleton<MasterDataRepository>(
    () => MasterDataRepositoryImpl(
        remote: sl(), cache: sl(), network: sl<NetworkInfo>()),
  );

  // ── Use cases ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => BrowseCustomers(sl()));
  sl.registerLazySingleton(() => CreateCustomer(sl()));
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
  sl.registerLazySingleton(() => FetchMasterData(sl()));
  sl.registerLazySingleton(() => RefreshMasterData(sl()));

  // ── Presentation ────────────────────────────────────────────────────
  sl.registerFactory(() => CustomersBloc(
        browseCustomers: sl(),
        fetchRecentCustomers: sl(),
        toggleFavoriteCustomer: sl(),
      ));
  sl.registerFactory(() => AddCustomerBloc(
        repository: sl(),
        rep: const RepSalesContext(
          salesOrganization: '0001',
          salesOrganizationName: 'ISI',
          salesOffice: '0001',
          salesOfficeName: 'Phnom Penh',
          salesEmployeeId: 'mobile',
          salesEmployeeName: 'Mobile user',
        ),
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
        session: sl<SessionManager>(),
        logger: sl<AppLogger>(),
      ));
}
