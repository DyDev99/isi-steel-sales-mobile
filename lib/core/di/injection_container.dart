import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
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
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_service.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/isi_api_service.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/sap_api_service.dart';
import 'package:isi_steel_sales_mobile/core/api_client/auth/token_manager.dart';
import 'package:isi_steel_sales_mobile/core/api_client/config/api_config.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_client.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_factory.dart';
import 'package:isi_steel_sales_mobile/core/api_client/network/network_checker.dart';
import 'package:isi_steel_sales_mobile/core/api_client/security/secure_storage_service.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_assets.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_file_service.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_service.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_share_service.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/app_coach_injection.dart';
import 'package:isi_steel_sales_mobile/features/authentication/authentication_injection.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/bloc/language_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/customers_injection.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/home_injection.dart';
import 'package:isi_steel_sales_mobile/features/lead/lead_injection.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/my_visits_injection.dart';
import 'package:isi_steel_sales_mobile/features/order/order_injection.dart';
import 'package:isi_steel_sales_mobile/features/profile/profile_injection.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/theme_injection.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// `get_it` instance names for the per-backend networking registrations.
///
/// Exported so a feature can resolve the right `ApiService`:
/// `sl<ApiService>(instanceName: sapBackend)`.
///
/// Constants rather than bare strings — a typo'd instance name is a runtime
/// lookup failure, not a compile error, and would surface as a crash on first
/// use rather than at build time.
const String sapBackend = _sapBackend;
const String isiBackend = _isiBackend;

const String _sapBackend = 'sap';
const String _isiBackend = 'isi';

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

  // ── Connectivity (ADR-005: real reachability, not interface-up) ─────
  // One instance, app-wide: the UI status pill and the sync drain trigger must
  // never disagree. No UI/bloc/repository/DAO may touch connectivity_plus.
  // The probe must carry the SAP client's TLS policy, not a bare `Dio()`. The
  // SAP host is a raw IP with a self-signed certificate, so a default-trust
  // client refuses the handshake every time — the probe then always reports
  // unreachable and `ConnectivityInterceptor` rejects every SAP call before it
  // is sent. `createProbeDio` applies the same pin and deliberately installs no
  // interceptors, so the probe cannot gate itself behind its own result.
  sl.registerLazySingleton<ReachabilityProbe>(
    () => HttpReachabilityProbe(
      dio: DioFactory.createProbeDio(config: ApiConfig.sap),
      logger: sl(),
    ),
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

  // ── Networking (core/api_client) ───────────────────────────────────
  //
  // One shared layer for every backend. Adding a service — notifications,
  // uploads, analytics, reporting — is one `ApiConfig` plus one registration
  // here; no interceptor, DioClient or ApiService change.
  //
  // Registered unconditionally so wiring is identical in mock and live builds:
  // nothing connects until a datasource issues a call, and with ENABLE_MOCK=true
  // none ever does.
  sl.registerLazySingleton<SecureStorageService>(
    () => FlutterSecureStorageService(sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<NetworkChecker>(
    () => ConnectivityNetworkChecker(sl<ConnectivityService>()),
  );

  // SAP token manager. Its login Dio deliberately carries no auth interceptor —
  // a 401 while signing in must not trigger another sign-in.
  sl.registerLazySingleton<TokenManager>(
    () => SapTokenManager(
      loginDio: DioFactory.createLoginDio(
        config: ApiConfig.sap,
        networkChecker: sl(),
      ),
      storage: sl(),
    ),
    instanceName: _sapBackend,
  );

  // One DioClient per backend. The *class*, its interceptor stack and its error
  // mapping are shared; only the configured instance differs, because the two
  // backends have different hosts and different credentials — a single instance
  // would attach the SAP bearer token to ISI requests.
  sl.registerLazySingleton<DioClient>(
    () => DioFactory.createSapClient(
      networkChecker: sl(),
      // Resolved lazily: the token manager and the Dio it attaches to are
      // mutually dependent at construction time.
      tokenManager: () => sl<TokenManager>(instanceName: _sapBackend),
    ),
    instanceName: _sapBackend,
  );
  sl.registerLazySingleton<DioClient>(
    // No token manager yet: the ISI backend's auth contract is not specified in
    // any document supplied, so nothing is guessed. Requests go out
    // unauthenticated until it is defined.
    () => DioFactory.createIsiClient(networkChecker: sl()),
    instanceName: _isiBackend,
  );

  // Named services, so a datasource declares its backend in its constructor
  // signature and wiring it to the wrong one fails to compile.
  sl.registerLazySingleton<SapApiService>(
    () => SapApiService(sl<DioClient>(instanceName: _sapBackend)),
  );
  sl.registerLazySingleton<IsiApiService>(
    () => IsiApiService(sl<DioClient>(instanceName: _isiBackend)),
  );

  // Also exposed under the plain `ApiService` interface for datasources that
  // are backend-agnostic. Same instances — not a second construction.
  sl.registerLazySingleton<ApiService>(
    () => sl<SapApiService>(),
    instanceName: _sapBackend,
  );
  sl.registerLazySingleton<ApiService>(
    () => sl<IsiApiService>(),
    instanceName: _isiBackend,
  );
  sl.registerLazySingleton<SessionManager>(() => SessionManager());
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

  sl.registerLazySingleton<LanguageCubit>(() => LanguageCubit(sl()));
  sl.registerLazySingleton<ShellTabController>(() => ShellTabController());
  registerThemeFeature(sl);

  // ── Features ───────────────────────────────────────────────────────
  registerAuthFeature(sl);
  registerHomeFeature(sl);
  registerLeadFeature(sl);
  await registerOrderFeature(sl);
  await registerCustomerFeature(sl);
  await registerMyVisitsFeature(sl);
  registerProfileFeature(sl);
  registerAppCoachFeature(sl);
}
