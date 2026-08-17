import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/device/device_identity.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/middleware/app_middleware.dart';
import 'package:isi_steel_sales_mobile/core/network/app_network.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/get_current_user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/login.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/logout.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';

/// Registers every dependency the authentication feature needs.
/// Externals (secure storage, connectivity, network info) are registered
/// by the core composition root before this runs.
///
/// All registrations are lazy, so registration order is irrelevant — a
/// dependency is only built the first time it's resolved.
void registerAuthFeature(GetIt sl) {
  // ── Presentation ───────────────────────────────────────────────────
  // Factory: a fresh bloc per screen, disposed with it.
  sl.registerFactory(
    () => AuthBloc(
      login: sl(),
      logout: sl(),
      getCurrentUser: sl(),
      sessionManager: sl(),
      // Resolved lazily at bloc construction, which happens after every
      // feature has registered — auth is wired before order/my_visits, so an
      // eager reference here would not find their repositories yet.
      sessionReset: sl(),
      appRestart: sl(),
      repository: sl<AuthRepository>(),
      logger: sl<AppLogger>(),
    ),
  );


  // ── Domain (use cases) ─────────────────────────────────────────────
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));

  // ── Data (repository) ──────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl(),
      local: sl(),
      networkInfo: sl(),
      logger: sl<AppLogger>(),
    ),
  );

  // ── Data (sources) ─────────────────────────────────────────────────
  // One concrete local source, exposed under two interfaces so the
  // interceptor and the repository share the exact same token storage.
  sl.registerLazySingleton(() => AuthLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => sl<AuthLocalDataSourceImpl>());
  sl.registerLazySingleton<TokenStore>(() => sl<AuthLocalDataSourceImpl>());

  // The per-installation device identity sent with login and every refresh.
  // A singleton because the id must be the same value across both — minting a
  // second one would detach the rotation from the session it belongs to.
  sl.registerLazySingleton(() => DeviceIdentity(sl()));

  // Authenticated Dio client (auto token attach + refresh). The default `Dio`
  // registration, so feature data sources resolve it without extra ceremony.
  sl.registerLazySingleton<Dio>(
    () => AppNetwork.createAuthedClient(
      tokenStore: sl<TokenStore>(),
      deviceId: () => sl<DeviceIdentity>().deviceId(),
      logger: sl<AppLogger>(),
      // Closes the loop between the network layer and global session state.
      //
      // Without this the interceptor cleared the token store on a failed
      // refresh and nothing else in the app was told: `SessionManager` still
      // reported the user as authenticated, guards still let them into
      // protected screens, and every subsequent request failed with no
      // explanation. The session was gone but the app did not know it.
      onSessionExpired: () => sl<SessionManager>().expire(),
    ),
  );

  // Bare client for the endpoints that establish or recover a session. Named
  // so it does not collide with the authenticated client above.
  sl.registerLazySingleton<Dio>(
    () => AppNetwork.createBareClient(logger: sl<AppLogger>()),
    instanceName: bareClientName,
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      authedClient: sl<Dio>(),
      bareClient: sl<Dio>(instanceName: bareClientName),
      device: sl(),
    ),
  );
}

/// GetIt instance name for the unauthenticated Dio client.
const String bareClientName = 'bareClient';
