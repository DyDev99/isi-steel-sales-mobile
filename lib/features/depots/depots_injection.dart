import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/hive_service.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/local_cache.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/local/depot_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/local/depot_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/local/bp_draft_cache.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/local/depot_reference_cache.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/local/master_data_cache.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/remote/api_depot_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/remote/depot_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/remote/master_data_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/remote/mock_master_data_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/remote/depot_document_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/repositories/depot_document_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_document_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/repositories/depot_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/datasources/business_partner_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/repositories/business_partner_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/remote/depot_datasources.dart'
    as bp;
import 'package:isi_steel_sales_mobile/features/depots/data/repositories/depot_sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/repositories/master_data_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/business_partner_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_sync_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/master_data_repository.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/add_depot_activity.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/add_depot_note.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/create_business_partner.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/create_depot.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/browse_depots.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/fetch_depot_activities.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/fetch_depot_notes.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/fetch_favorite_depots.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/fetch_recent_depots.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/get_depot_by_id.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/lookup_depot_by_code.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/fetch_master_data.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/get_depot_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/refresh_master_data.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/record_depot_viewed.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/run_depot_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/run_depot_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/toggle_favorite_depot.dart';
import 'package:isi_steel_sales_mobile/features/depots/presentation/bloc/depot_code_lookup_cubit.dart';
import 'package:isi_steel_sales_mobile/features/depots/presentation/bloc/depot_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/depots/presentation/bloc/depot_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/depots/presentation/bloc/depots_bloc.dart';
import 'package:isi_steel_sales_mobile/features/depots/presentation/bloc/add_depot_bloc.dart';
import 'package:isi_steel_sales_mobile/features/depots/presentation/bloc/business_partner_submission.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/models/bp_depot_form_data.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/remote/depot_stop_information_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/depots/data/repositories/depot_stop_information_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/repositories/depot_stop_information_repository.dart';

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
/// already wrong here, and the sales area decides which office a depot is
/// routed to.
const _fallbackRepContext = RepSalesContext(
  salesOrganization: '0001',
  salesOrganizationName: 'ISI',
  salesOffice: '0001',
  salesOfficeName: 'Phnom Penh',
  salesEmployeeId: '100389',
  salesEmployeeName: 'Mobile user',
);

/// Registers the approved-depot directory. Persistence is the single
/// SQLCipher-encrypted Drift database (`AppDatabase`) via [DepotDao] — the
/// legacy plaintext `depots.db` was retired in the T2 cutover.
Future<void> registerDepotFeature(GetIt sl) async {
  // ── Data sources ────────────────────────────────────────────────────
  sl.registerLazySingleton<DepotLocalDataSource>(
      () => DepotDriftLocalDataSource(sl<AppDatabase>().depotDao));

  // The depot *directory* feed — `GET /mobile/depots`, consumed by
  // DepotSyncRepositoryImpl.
  //
  // Note there are two unrelated interfaces named `DepotRemoteDataSource`:
  // this one (`data/remote/depot_remote_data_source.dart`) and the BP
  // registration one below, imported as `bp`. They are different types, so
  // registering one does NOT satisfy the other — omitting this line fails at
  // runtime, not compile time, with "DepotRemoteDataSource is not
  // registered" when the Depots screen builds.
  sl.registerLazySingleton<DepotRemoteDataSource>(
      () => ApiDepotRemoteDataSource(sl<Dio>()));

  // SAP Depot Helper master data (ADR-009). Cached in Hive rather than
  // Drift because these are regenerable lookups, not business records
  // (ARCHITECTURE.md §3, Layer 2) — so this needs no schema migration.
  sl.registerLazySingleton<MasterDataRemoteDataSource>(
      () => const MockMasterDataRemoteDataSource());
  sl.registerLazySingleton<MasterDataCache>(
      () => MasterDataCache(LocalCache(HiveService.cacheBox)));

  // ── Repositories ────────────────────────────────────────────────────
  sl.registerLazySingleton<DepotRepository>(() => DepotRepositoryImpl(sl()));
  sl.registerLazySingleton<bp.DepotRemoteDataSource>(
      () => bp.DepotRemoteDataSourceImpl(sl<Dio>()));
  // Hive, not Drift: regenerable ERP lookups are Layer 2 (ADR-009), so this
  // needs no schema migration.
  sl.registerLazySingleton<DepotReferenceCache>(
      () => DepotReferenceCache(LocalCache(HiveService.cacheBox)));
  // Evidence photographs. Separate from the registration repository because the
  // lifetime differs — they outlive the draft and are edited from the detail
  // screen long after registration closed.
  // The outlet profile behind a visit's stop screen. Owned here rather than in
  // `my_visits` because the endpoint is `/mobile/depots/{id}/stop-information`
  // — my_visits consumes it through the domain interface (CLAUDE.md §4).
  sl.registerLazySingleton<DepotStopInformationRemoteDataSource>(
      () => ApiDepotStopInformationRemoteDataSource(sl<Dio>()));
  sl.registerLazySingleton<DepotStopInformationRepository>(
      () => DepotStopInformationRepositoryImpl(
            remote: sl<DepotStopInformationRemoteDataSource>(),
            network: sl<NetworkInfo>(),
            logger: sl<AppLogger>(),
          ));

  sl.registerLazySingleton<DepotDocumentRemoteDataSource>(
      () => ApiDepotDocumentRemoteDataSource(sl<Dio>()));
  sl.registerLazySingleton<DepotDocumentRepository>(
      () => DepotDocumentRepositoryImpl(
            remote: sl<DepotDocumentRemoteDataSource>(),
            logger: sl<AppLogger>(),
          ));
  // The single-write registration endpoint,
  // `POST /api/v1/mobile/depots/business-partner`. Separate from
  // `bp.DepotRemoteDataSource`, which still owns `GET /references` and the
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
            references: sl<bp.DepotRemoteDataSource>(),
            referenceCache: sl<DepotReferenceCache>(),
            draftCache: sl<BpDraftCache>(),
          ));
  sl.registerLazySingleton<DepotSyncRepository>(
    () => DepotSyncRepositoryImpl(
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
  sl.registerLazySingleton(() => BrowseDepots(sl()));
  sl.registerLazySingleton(() => CreateDepot(sl()));
  sl.registerLazySingleton(() => CreateBusinessPartner(sl()));
  sl.registerLazySingleton(() => ValidateBusinessPartner(sl()));
  sl.registerLazySingleton(() => GetDepotById(sl()));
  sl.registerLazySingleton(() => ToggleFavoriteDepot(sl()));
  sl.registerLazySingleton(() => FetchFavoriteDepots(sl()));
  sl.registerLazySingleton(() => FetchRecentDepots(sl()));
  sl.registerLazySingleton(() => RecordDepotViewed(sl()));
  sl.registerLazySingleton(() => FetchDepotNotes(sl()));
  sl.registerLazySingleton(() => AddDepotNote(sl()));
  sl.registerLazySingleton(() => FetchDepotActivities(sl()));
  sl.registerLazySingleton(() => AddDepotActivity(sl()));
  sl.registerLazySingleton(() => RunDepotInitialSync(sl()));
  sl.registerLazySingleton(() => RunDepotDeltaSync(sl()));
  sl.registerLazySingleton(() => GetDepotLastSyncedAt(sl()));
  sl.registerLazySingleton(() => LookupDepotByCode(sl()));
  sl.registerLazySingleton(() => FetchMasterData(sl()));
  sl.registerLazySingleton(() => RefreshMasterData(sl()));

  // ── Presentation ────────────────────────────────────────────────────
  sl.registerFactory(() => DepotsBloc(
        browseDepots: sl(),
        fetchRecentDepots: sl(),
        toggleFavoriteDepot: sl(),
      ));
  // Holds the draft -> payload mapping. A singleton rather than part of the
  // bloc so the mapping can be unit-tested, and so a future offline replay
  // worker builds the payload the same way the wizard does.
  sl.registerLazySingleton(() => BusinessPartnerSubmission(
        createBusinessPartner: sl(),
        validateBusinessPartner: sl(),
      ));

  sl.registerFactory(() => AddDepotBloc(
        repository: sl(),
        documents: sl<DepotDocumentRepository>(),
        submission: sl<BusinessPartnerSubmission>(),
        rep: _fallbackRepContext,
      ));
  sl.registerFactory(() => DepotDetailCubit(
        getDepotById: sl(),
        fetchDepotNotes: sl(),
        addDepotNote: sl(),
        fetchDepotActivities: sl(),
        addDepotActivity: sl(),
        recordDepotViewed: sl(),
      ));
  sl.registerFactory(() => DepotCodeLookupCubit(sl()));
  sl.registerFactory(() => DepotSyncCubit(
        runInitialSync: sl(),
        runDeltaSync: sl(),
        getLastSyncedAt: sl(),
        session: sl<SessionManager>(),
        logger: sl<AppLogger>(),
      ));
}
