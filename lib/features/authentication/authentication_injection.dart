import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/network/app_middleware.dart';
import 'package:isi_steel_sales_mobile/core/network/app_network.dart';
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
    () => AuthBloc(login: sl(), logout: sl(), getCurrentUser: sl()),
  );

  // ── Domain (use cases) ─────────────────────────────────────────────
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));

  // ── Data (repository) ──────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl(), local: sl(), networkInfo: sl()),
  );

  // ── Data (sources) ─────────────────────────────────────────────────
  // One concrete local source, exposed under two interfaces so the
  // interceptor and the repository share the exact same token storage.
  sl.registerLazySingleton(() => AuthLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => sl<AuthLocalDataSourceImpl>());
  sl.registerLazySingleton<TokenStore>(() => sl<AuthLocalDataSourceImpl>());

  // Authenticated Dio client (auto token attach + refresh).
  sl.registerLazySingleton<Dio>(
    () => AppNetwork.createAuthedClient(tokenStore: sl<TokenStore>()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<Dio>()),
  );
}
