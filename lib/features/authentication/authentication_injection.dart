import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/sap_api_service.dart';
import 'package:isi_steel_sales_mobile/core/api_client/auth/token_manager.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart'
    show sapBackend;
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/check_authentication.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/get_current_user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/login.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/logout.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';

/// Registers the authentication feature.
///
/// SAP is the only authentication provider. Externals — secure storage, the
/// shared networking layer, the token manager — are registered by the core
/// composition root before this runs.
///
/// All registrations are lazy, so order is irrelevant: a dependency is built the
/// first time it is resolved.
void registerAuthFeature(GetIt sl) {
  // ── Presentation ───────────────────────────────────────────────────
  // Factory: a fresh bloc per screen, disposed with it.
  sl.registerFactory(
    () => AuthBloc(
      login: sl(),
      logout: sl(),
      getCurrentUser: sl(),
      sessionManager: sl(),
      // Expiry discovered by the auth interceptor, mid-request, is routed here
      // so one place reacts to it instead of every screen guessing.
      sessionExpiredStream:
          sl<TokenManager>(instanceName: sapBackend).onSessionExpired,
    ),
  );

  // ── Domain (use cases) ─────────────────────────────────────────────
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => CheckAuthentication(sl()));

  // ── Data (repository) ──────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl(),
      local: sl(),
      // The token manager owns the token; this feature owns the profile. One
      // store each, so the interceptor and the feature can never disagree about
      // whether a session exists.
      tokenManager: sl<TokenManager>(instanceName: sapBackend),
      logger: sl(),
    ),
  );

  // ── Data (sources) ─────────────────────────────────────────────────
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );

  // Talks to SAP through the shared networking layer — no feature-local Dio.
  // The previous implementation built its own authenticated `Dio` via
  // `AppNetwork`, duplicating the interceptor stack; that whole path is gone.
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      sl<SapApiService>(),
    ),
  );
}
