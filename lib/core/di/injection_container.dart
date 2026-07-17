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
