import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/usecases/change_password.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/usecases/get_worker_profile.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/usecases/logout_worker.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/usecases/update_worker_profile.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';

/// Registers the profile feature: worker profile read/update, password
/// change, and logout. Mirrors `registerRoutesFeature`.
void registerProfileFeature(GetIt sl) {
  // ── Data sources ────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRemoteDataSource>(() => MockProfileRemoteDataSource());

  // ── Repositories ────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(remoteDataSource: sl()));

  // ── Use cases ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetWorkerProfile(sl()));
  sl.registerLazySingleton(() => UpdateWorkerProfile(sl()));
  sl.registerLazySingleton(() => ChangePassword(sl()));
  sl.registerLazySingleton(() => LogoutWorker(sl()));

  // ── Presentation ────────────────────────────────────────────────────
  sl.registerFactory(() => ProfileCubit(
        getWorkerProfile: sl(),
        updateWorkerProfile: sl(),
        changePassword: sl(),
        logoutWorker: sl(),
      ));
}
