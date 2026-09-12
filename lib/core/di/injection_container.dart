import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/camera/camera_factory.dart';
import 'package:isi_steel_sales_mobile/core/camera/image_capture_service.dart';
import 'package:isi_steel_sales_mobile/core/config/env.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database_rekey_executor.dart';
import 'package:isi_steel_sales_mobile/core/database/secure/app_database_key_provider.dart';
import 'package:isi_steel_sales_mobile/core/database/secure/database_key_rotator.dart';
import 'package:isi_steel_sales_mobile/core/database/secure/dynamic_key_store.dart';
import 'package:isi_steel_sales_mobile/core/database/secure/key_derivation.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/app_preferences.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/hive_service.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_cubit.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_service.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_assets.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_file_service.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_service.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_share_service.dart';
import 'package:isi_steel_sales_mobile/core/session/app_restart_controller.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/session/session_scoped_store.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/data/session/order_session_scoped_store.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/active_workflow_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/session/visit_session_scoped_store.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/app_coach_injection.dart';
import 'package:isi_steel_sales_mobile/features/authentication/authentication_injection.dart';
import 'package:isi_steel_sales_mobile/features/localization/localization_injection.dart';
import 'package:isi_steel_sales_mobile/features/customers/customers_injection.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/geo_location/geo_location_injection.dart';
import 'package:isi_steel_sales_mobile/features/home/home_injection.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/my_visits_injection.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/check_material_availability.dart';
import 'package:isi_steel_sales_mobile/features/order/order_injection.dart';
import 'package:isi_steel_sales_mobile/features/notification/notification_injection.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/stock_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/profile_injection.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/theme_injection.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/local_cache.dart';
import 'package:isi_steel_sales_mobile/core/permissions/geolocator_location_permission_service.dart';
import 'package:isi_steel_sales_mobile/core/permissions/location_permission_service.dart';
import 'package:isi_steel_sales_mobile/core/permissions/presentation/app_permissions_cubit.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/push_device_usecases.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Call once from `main()` before `runApp`.
Future<void> initDependencies() async {
  // ── External singletons ────────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // ── Encrypted database (Blueprint §3: composite-key SQLCipher) ──────
  sl.registerLazySingleton<DynamicKeyStore>(() => DynamicKeyStore(sl()));
  sl.registerLazySingleton<KeyDerivation>(() => const KeyDerivation());
  sl.registerLazySingleton<AppDatabaseKeyProvider>(
    () => AppDatabaseKeyProvider(
      deviceKeyStore: sl(),
      keyDerivation: sl(),
      salt: Env.dbSalt,
    ),
  );
  sl.registerFactory(() => StockCubit(sl<CheckMaterialAvailability>()));
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase.encrypted(sl()));
  sl.registerLazySingleton<DatabaseRekeyExecutor>(
    () => AppDatabaseRekeyExecutor(sl()),
  );
  sl.registerLazySingleton<DatabaseKeyRotator>(
    () => DatabaseKeyRotator(
      deviceKeyStore: sl(),
      keyDerivation: sl(),
      executor: sl(),
      salt: Env.dbSalt,
    ),
  );

  // ── Observability (SECURITY.md §10: structured, PII-free) ──────────
  sl.registerLazySingleton<AppLogger>(() => const ConsoleAppLogger());

  // ── Camera ──────────────────────────────────────────────────────────
  //
  // The one place the runtime environment is allowed to decide anything about
  // the camera. Features resolve `ImageCaptureService` and use what they get;
  // none of them may ask whether it is running on a simulator.
  //
  // Under the default `CAMERA_MODE=auto` this is the real camera everywhere
  // except the iOS Simulator, which has no camera hardware at all. Override
  // with `--dart-define=CAMERA_MODE=mock|real`.
  sl.registerLazySingleton<ImageCaptureService>(
      () => CameraFactory.resolve(navigatorKey: navigatorKey));

  // ── Connectivity (ADR-005: real reachability, not interface-up) ─────
  // One instance, app-wide: the UI status pill and the sync drain trigger must
  // never disagree. No UI/bloc/repository/DAO may touch connectivity_plus.
  sl.registerLazySingleton<ReachabilityProbe>(
    () => HttpReachabilityProbe(dio: Dio(), logger: sl()),
  );
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(
      connectivity: sl(),
      probe: sl(),
      logger: sl(),
    ),
  );

  sl.registerFactory<ConnectivityCubit>(() => ConnectivityCubit(sl()));
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<SessionManager>(() => SessionManager());
  sl.registerLazySingleton<AppRestartController>(() => AppRestartController());
  sl.registerLazySingleton<AppPreferences>(
    () => AppPreferencesImpl(HiveService.cacheBox),
  );
  // ── PDF export (reusable across every CRM document type) ────────────
  // Feature-agnostic: generators (quotation/invoice/report…) plug into the
  // same PdfService/File/Share pipeline. PdfAssets caches fonts+logo once.
  sl.registerLazySingleton<PdfAssets>(() => PdfAssets());
  sl.registerLazySingleton<PdfService>(() => PdfServiceImpl(sl<PdfAssets>()));
  sl.registerLazySingleton<PdfFileService>(() => const PdfFileServiceImpl());
  sl.registerLazySingleton<PdfShareService>(() => const PdfShareServiceImpl());

  registerLocalizationFeature(sl);
  sl.registerLazySingleton<ShellTabController>(() => ShellTabController());
  registerThemeFeature(sl);

  // ── Features ───────────────────────────────────────────────────────
  registerAuthFeature(sl);
  registerHomeFeature(sl);
  await registerOrderFeature(sl);
  await registerCustomerFeature(sl);
  // Shared address component. After the customer feature only for readability —
  // its one real dependency is `AppDatabase`, registered above.
  registerGeoLocationFeature(sl);
  // After auth, which supplies the authenticated `Dio` and the `DeviceIdentity`
  // whose per-installation id is the upsert key for a push registration
  // (docs/feature/notification/api/devices-register.md). The feed is no longer derived
  // from the customer cache — it is the real inbox now.
  registerNotificationFeature(sl);
  await registerMyVisitsFeature(sl);
  registerProfileFeature(sl);
  registerAppCoachFeature(sl);

  // ── OS permissions ─────────────────────────────────────────────────
  //
  // Registered after the notification feature because the primer's device
  // registration resolves `RegisterPushDevice` from it. Both are lazy, so this
  // is about readability rather than necessity — but the dependency is real and
  // worth stating where somebody reordering these lines will see it.
  //
  // Location lives in `core/` alongside the push transport rather than in a
  // feature: `features/order` and `features/my_visits` both read a position, and
  // one dialog primes both permissions, so no single feature can own it without
  // another importing its internals (playbook §12).
  sl.registerLazySingleton<LocationPermissionService>(
    () => GeolocatorLocationPermissionService(sl<AppLogger>()),
  );

  // A factory: the primer is per-presentation and is closed with the dialog
  // that built it. A singleton would keep a settled state around and report
  // "already answered" to the next caller.
  sl.registerFactory<AppPermissionsCubit>(
    () => AppPermissionsCubit(
      messaging: sl(),
      location: sl(),
      cache: LocalCache(HiveService.cacheBox),
      logger: sl<AppLogger>(),
      // A callback, not a repository. Registering the handset belongs to the
      // notification feature, and `core/` must not depend on a feature — the
      // same seam the inbox cubit uses for an action's `api_call`.
      registerPushDevice: () async {
        await sl<RegisterPushDevice>()(const NoParams());
      },
    ),
  );

  // ── Sign-out fan-out ───────────────────────────────────────────────
  //
  // Registered after every feature so each one's repositories exist to be
  // resolved. Adding a feature that holds rep-scoped data means adding one
  // entry here — the logout path itself never changes.
  //
  // Master data (catalog, customer directory) is deliberately absent: it is
  // SAP-owned, identical for the next user, and expensive to re-pull. Clearing
  // it on sign-out would turn logout into a multi-minute re-download.
  sl.registerLazySingleton<SessionResetService>(
    () => SessionResetService(
      [
        OrderSessionScopedStore(sl<CartRepository>()),
        VisitSessionScopedStore(sl<ActiveWorkflowRepository>()),
      ],
      sl<AppLogger>(),
    ),
  );
}
