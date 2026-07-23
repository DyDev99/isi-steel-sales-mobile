import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/hive_service.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/depot_selection_store.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/location_sample_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/location_sample_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/routes_database.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/visit_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/visit_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/workflow_state_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/mock_route_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/mock_visit_sync_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/route_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_sync_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/active_workflow_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/location_sample_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/route_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/route_sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/visit_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/visit_sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/services/geolocator_tracking_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/active_workflow_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/location_sample_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/route_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/route_sync_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_sync_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/fraud_detection_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/location_tracking_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/proof_photo_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/services/camera_proof_photo_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/add_collection.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/add_order_line.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/add_return.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/add_stock_update.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/add_visit_note.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/add_visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/check_in.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/check_out.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/clear_active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/complete_visit_check_out.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_resumable_route.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/push_pending_visit_data.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/save_active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/fetch_location_samples.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/fetch_today_routes.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/fetch_visit_data.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_route.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_route_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/record_fraud_flag.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/record_location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/run_route_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/run_route_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_route_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_workflow_step.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_stop_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/watch_all_routes.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/watch_today_routes.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/resumable_visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/depot_selection_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/depot_stock_count_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';

/// Registers the route-management feature: GPS tracking, geofence
/// check-in/out, offline visit capture, and the route sync engine. Async
/// because it opens the sqflite `routes.db` once before anything else can
/// be registered against it — mirrors `registerOrderFeature`.
Future<void> registerMyVisitsFeature(GetIt sl) async {
  final routesDb = await RoutesDatabase.open();
  sl.registerLazySingleton<RoutesDatabase>(() => routesDb);

  // ── Data sources ────────────────────────────────────────────────────
  sl.registerLazySingleton<RouteRemoteDataSource>(
      () => MockRouteRemoteDataSource(sl<CustomerLocalDataSource>()));
  sl.registerLazySingleton<RouteLocalDataSource>(
      () => RouteDriftLocalDataSource(sl<AppDatabase>().routeDao, sl()));
  sl.registerLazySingleton<VisitLocalDataSource>(
      () => VisitDriftLocalDataSource(sl<AppDatabase>().visitDao, sl()));
  // T1.5 cutover: telemetry now reads/writes the encrypted Drift database
  // instead of the plaintext `routes.db`. The interface is unchanged, so the
  // repository and everything above it are untouched (ADR-003 seam).
  // `LocationSampleLocalDataSourceImpl` (sqflite) is retained but unregistered
  // until the import is verified in production — do not delete it before then
  // (`docs/AI_ENGINEERING_PLAYBOOK.md` §8: parity first).
  sl.registerLazySingleton<LocationSampleLocalDataSource>(() =>
      LocationSampleDriftLocalDataSource(sl<AppDatabase>().routeTelemetryDao));
  sl.registerLazySingleton<WorkflowStateLocalDataSource>(
      () => WorkflowStateLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<VisitSyncRemoteDataSource>(
      () => const MockVisitSyncRemoteDataSource());

  // ── Services ────────────────────────────────────────────────────────
  sl.registerLazySingleton<LocationTrackingService>(
      () => GeolocatorTrackingService());
  sl.registerLazySingleton<FraudDetectionService>(
      () => const FraudDetectionService());
  sl.registerLazySingleton<ProofPhotoService>(
      () => const CameraProofPhotoService());

  // ── Repositories ────────────────────────────────────────────────────
  sl.registerLazySingleton<RouteRepository>(() => RouteRepositoryImpl(sl()));
  sl.registerLazySingleton<VisitRepository>(() => VisitRepositoryImpl(sl()));
  sl.registerLazySingleton<LocationSampleRepository>(
      () => LocationSampleRepositoryImpl(sl()));
  sl.registerLazySingleton<RouteSyncRepository>(
    () => RouteSyncRepositoryImpl(
        remote: sl(), local: sl(), network: sl<NetworkInfo>()),
  );
  sl.registerLazySingleton<VisitSyncRepository>(
    () => VisitSyncRepositoryImpl(
        remote: sl(), local: sl(), network: sl<NetworkInfo>()),
  );
  sl.registerLazySingleton<ActiveWorkflowRepository>(
      () => ActiveWorkflowRepositoryImpl(sl()));

  // ── Use cases ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => FetchTodayRoutes(sl()));
  sl.registerLazySingleton(() => WatchTodayRoutes(sl()));
  sl.registerLazySingleton(() => WatchAllRoutes(sl()));
  sl.registerLazySingleton(() => GetRoute(sl()));
  sl.registerLazySingleton(() => UpdateRouteStatus(sl()));
  sl.registerLazySingleton(() => UpdateStopStatus(sl()));

  sl.registerLazySingleton(() => CheckIn(sl()));
  sl.registerLazySingleton(() => CheckOut(sl()));
  sl.registerLazySingleton(() => AddOrderLine(sl()));
  sl.registerLazySingleton(() => AddStockUpdate(sl()));
  sl.registerLazySingleton(() => AddReturn(sl()));
  sl.registerLazySingleton(() => AddCollection(sl()));
  sl.registerLazySingleton(() => AddVisitNote(sl()));
  sl.registerLazySingleton(() => AddVisitPhoto(sl()));
  sl.registerLazySingleton(() => FetchVisitData(sl()));

  sl.registerLazySingleton(() => RecordLocationSample(sl()));
  sl.registerLazySingleton(() => FetchLocationSamples(sl()));
  sl.registerLazySingleton(() => RecordFraudFlag(sl()));

  sl.registerLazySingleton(() => RunRouteInitialSync(sl()));
  sl.registerLazySingleton(() => RunRouteDeltaSync(sl()));
  sl.registerLazySingleton(() => GetRouteLastSyncedAt(sl()));
  sl.registerLazySingleton(() => PushPendingVisitData(sl()));

  sl.registerLazySingleton(() => SaveActiveWorkflow(sl()));
  sl.registerLazySingleton(() => ClearActiveWorkflow(sl()));
  sl.registerLazySingleton(() => GetActiveWorkflow(sl()));
  sl.registerLazySingleton(() => GetResumableRoute(sl(), sl()));
  // Write-side for business-task transitions (Quotation/Sales Order/…): records
  // the current workflow + screen + navigation args onto the active pointer so
  // the resume dispatcher can restore the exact screen.
  sl.registerLazySingleton(() => UpdateWorkflowStep(sl()));
  // Deferred check-out: closes the visit off the persisted pointer (no live
  // ActiveRouteBloc needed) — triggered by the explicit "Check out" on the
  // Continue-Working card now that Stock Count no longer auto-checks-out.
  sl.registerLazySingleton(() => CompleteVisitCheckOut(sl(), sl(), sl(), sl()));

  // ── Presentation ────────────────────────────────────────────────────
  sl.registerFactory(() => RouteDashboardCubit(watchAllRoutes: sl()));
  sl.registerFactory(() => ActiveRouteBloc(
        saveActiveWorkflow: sl(),
        clearActiveWorkflow: sl(),
        getActiveWorkflow: sl(),
        getRoute: sl(),
        updateRouteStatus: sl(),
        updateStopStatus: sl(),
        checkIn: sl(),
        checkOut: sl(),
        recordFraudFlag: sl(),
        fraudDetectionService: sl(),
      ));
  sl.registerFactory(() => LocationTrackingCubit(
        trackingService: sl(),
        recordLocationSample: sl(),
        recordFraudFlag: sl(),
        fraudDetectionService: sl(),
      ));
  sl.registerFactory(() => VisitCubit(
        fetchVisitData: sl(),
        addOrderLine: sl(),
        addStockUpdate: sl(),
        addReturn: sl(),
        addCollection: sl(),
        addVisitNote: sl(),
        addVisitPhoto: sl(),
      ));
  sl.registerFactory(() => RouteSyncCubit(
        pushPendingVisitData: sl(),
        runInitialSync: sl(),
        runDeltaSync: sl(),
        getLastSyncedAt: sl(),
        // Customer-directory guard (ADR-001 FK ordering): resolved lazily at
        // cubit creation, so registration order vs. the customers feature
        // doesn't matter.
        runCustomerInitialSync: sl(),
        getCustomerLastSyncedAt: sl(),
        sessionManager: sl<SessionManager>(),
      ));

  // Lazy singleton (not a factory): its "resume this check-in" state must
  // survive tab switches and be refreshable from the shell.
  sl.registerLazySingleton(() => ResumableVisitCubit(
        getResumableRoute: sl(),
        getRoute: sl(),
        getActiveWorkflow: sl(),
        clearActiveWorkflow: sl(),
        completeVisitCheckOut: sl(),
      ));

  // ── Depot Stock flow ────────────────────────────────────────────────
  sl.registerLazySingleton(() => DepotSelectionStore(HiveService.cacheBox));
  sl.registerFactory(
      () => DepotSelectionCubit(browseCustomers: sl(), store: sl()));
  sl.registerFactory(() => DepotStockCountCubit(
      getCustomerById: sl(), browseProducts: sl(), addStockUpdate: sl()));
}
