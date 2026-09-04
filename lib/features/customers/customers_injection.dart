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
import 'package:isi_steel_sales_mobile/features/customers/data/local/bp_draft_cache.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_reference_cache.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/master_data_cache.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/api_customer_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/master_data_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/mock_master_data_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_document_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/customer_document_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_document_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasources/business_partner_remote_data_source.dart';
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
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/create_business_partner.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/create_customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/browse_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_customer_activities.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_customer_notes.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_favorite_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_recent_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_by_id.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/lookup_customer_by_code.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_master_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/refresh_master_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/record_customer_viewed.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/toggle_favorite_customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_code_lookup_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/add_customer_bloc.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/business_partner_submission.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';

/// Sales-area context used until the session carries one.
///
/// `salesEmployeeId` becomes `PersonnelNumber` on the BP payload, and SAP's
/// `PERNR` is a **numeric** field. The previous placeholder was the literal
/// string `'mobile'`, which the middleware accepted and the SAP push then
/// rejected — producing a registration that existed on the backend and never
/// in the ERP, with nothing in the mobile log to say why.
///
/// The number below is the one from the reference payload, so registrations
/// land against a real personnel record while this is still a placeholder. It
/// is wrong for every rep who is not that person, which is why it must not
/// survive to release.
///
/// TODO(sales-context): read from `SessionManager` — the rep's own
/// `salesOrganization`, `salesOffice` and personnel number. All three are
/// already wrong here, and the sales area decides which office a customer is
/// routed to.
const _fallbackRepContext = RepSalesContext(
  salesOrganization: '0001',
  salesOrganizationName: 'ISI',
  salesOffice: '0001',
  salesOfficeName: 'Phnom Penh',
  salesEmployeeId: '100389',
  salesEmployeeName: 'Mobile user',
);

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
  // Hive, not Drift: regenerable ERP lookups are Layer 2 (ADR-009), so this
  // needs no schema migration.
  sl.registerLazySingleton<CustomerReferenceCache>(
      () => CustomerReferenceCache(LocalCache(HiveService.cacheBox)));
  // Evidence photographs. Separate from the registration repository because the
  // lifetime differs — they outlive the draft and are edited from the detail
  // screen long after registration closed.
  sl.registerLazySingleton<CustomerDocumentRemoteDataSource>(
      () => ApiCustomerDocumentRemoteDataSource(sl<Dio>()));
  sl.registerLazySingleton<CustomerDocumentRepository>(
      () => CustomerDocumentRepositoryImpl(
            remote: sl<CustomerDocumentRemoteDataSource>(),
            logger: sl<AppLogger>(),
          ));
  // The single-write registration endpoint,
  // `POST /api/v1/mobile/customers/business-partner`. Separate from
  // `bp.CustomerRemoteDataSource`, which still owns `GET /references` and the
  // retired draft routes — the two are different types and both are needed.
  sl.registerLazySingleton<BusinessPartnerRemoteDataSource>(
      () => BusinessPartnerRemoteDataSourceImpl(sl<Dio>()));

  // Hive, not Drift: an in-progress form is UI state that survives a process
  // kill, not a business record, so it needs no schema migration (ADR-009).
  sl.registerLazySingleton<BpDraftCache>(
      () => BpDraftCache(LocalCache(HiveService.cacheBox)));

  sl.registerLazySingleton<BusinessPartnerRepository>(
      () => BusinessPartnerRepositoryImpl(
            remote: sl<BusinessPartnerRemoteDataSource>(),
            references: sl<bp.CustomerRemoteDataSource>(),
            referenceCache: sl<CustomerReferenceCache>(),
            draftCache: sl<BpDraftCache>(),
          ));
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
  sl.registerLazySingleton(() => CreateBusinessPartner(sl()));
  sl.registerLazySingleton(() => ValidateBusinessPartner(sl()));
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
  sl.registerLazySingleton(() => LookupCustomerByCode(sl()));
  sl.registerLazySingleton(() => FetchMasterData(sl()));
  sl.registerLazySingleton(() => RefreshMasterData(sl()));

  // ── Presentation ────────────────────────────────────────────────────
  sl.registerFactory(() => CustomersBloc(
        browseCustomers: sl(),
        fetchRecentCustomers: sl(),
        toggleFavoriteCustomer: sl(),
      ));
  // Holds the draft -> payload mapping. A singleton rather than part of the
  // bloc so the mapping can be unit-tested, and so a future offline replay
  // worker builds the payload the same way the wizard does.
  sl.registerLazySingleton(() => BusinessPartnerSubmission(
        createBusinessPartner: sl(),
        validateBusinessPartner: sl(),
      ));

  sl.registerFactory(() => AddCustomerBloc(
        repository: sl(),
        documents: sl<CustomerDocumentRepository>(),
        submission: sl<BusinessPartnerSubmission>(),
        rep: _fallbackRepContext,
      ));
  sl.registerFactory(() => CustomerDetailCubit(
        getCustomerById: sl(),
        fetchCustomerNotes: sl(),
        addCustomerNote: sl(),
        fetchCustomerActivities: sl(),
        addCustomerActivity: sl(),
        recordCustomerViewed: sl(),
      ));
  sl.registerFactory(() => CustomerCodeLookupCubit(sl()));
  sl.registerFactory(() => CustomerSyncCubit(
        runInitialSync: sl(),
        runDeltaSync: sl(),
        getLastSyncedAt: sl(),
        session: sl<SessionManager>(),
        logger: sl<AppLogger>(),
      ));
}
