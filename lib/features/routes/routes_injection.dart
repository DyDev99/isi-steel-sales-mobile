import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/local/location_sample_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/local/routes_database.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/local/visit_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/remote/mock_route_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/remote/route_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/repositories/location_sample_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/repositories/route_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/repositories/route_sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/repositories/visit_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/services/geolocator_tracking_service.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/location_sample_repository.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/route_repository.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/route_sync_repository.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/visit_repository.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/services/fraud_detection_service.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/services/location_tracking_service.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/add_collection.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/add_order_line.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/add_return.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/add_stock_update.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/add_visit_note.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/add_visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/check_in.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/check_out.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/fetch_location_samples.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/fetch_today_routes.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/fetch_visit_data.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/get_route.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/get_route_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/record_fraud_flag.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/record_location_sample.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/run_route_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/run_route_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/update_route_status.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/usecases/update_stop_status.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/route_dashboard_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/routes/presentation/bloc/visit_cubit.dart';

/// Registers the route-management feature: GPS tracking, geofence
/// check-in/out, offline visit capture, and the route sync engine. Async
/// because it opens the sqflite `routes.db` once before anything else can
/// be registered against it — mirrors `registerOrderFeature`.
Future<void> registerRoutesFeature(GetIt sl) async {
  final routesDb = await RoutesDatabase.open();
  sl.registerLazySingleton<RoutesDatabase>(() => routesDb);

  // ── Data sources ────────────────────────────────────────────────────
  sl.registerLazySingleton<RouteLocalDataSource>(() => RouteLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<VisitLocalDataSource>(() => VisitLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<LocationSampleLocalDataSource>(() => LocationSampleLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<RouteRemoteDataSource>(() => MockRouteRemoteDataSource());

  // ── Services ────────────────────────────────────────────────────────
  sl.registerLazySingleton<LocationTrackingService>(() => GeolocatorTrackingService());
  sl.registerLazySingleton<FraudDetectionService>(() => const FraudDetectionService());

  // ── Repositories ────────────────────────────────────────────────────
  sl.registerLazySingleton<RouteRepository>(() => RouteRepositoryImpl(sl()));
  sl.registerLazySingleton<VisitRepository>(() => VisitRepositoryImpl(sl()));
  sl.registerLazySingleton<LocationSampleRepository>(() => LocationSampleRepositoryImpl(sl()));
  sl.registerLazySingleton<RouteSyncRepository>(
    () => RouteSyncRepositoryImpl(remote: sl(), local: sl(), network: sl<NetworkInfo>()),
  );

  // ── Use cases ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => FetchTodayRoutes(sl()));
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

  // ── Presentation ────────────────────────────────────────────────────
  sl.registerFactory(() => RouteDashboardCubit(fetchTodayRoutes: sl()));
  sl.registerFactory(() => ActiveRouteBloc(
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
        runInitialSync: sl(),
        runDeltaSync: sl(),
        getLastSyncedAt: sl(),
        sessionManager: sl<SessionManager>(),
      ));
}
