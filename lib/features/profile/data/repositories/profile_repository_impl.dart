import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/profile/data/models/worker_profile_model.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/entities/worker_profile.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/repositories/profile_repository.dart';

/// NOTE: `Failure` is sealed (`ServerFailure`/`CacheFailure`/`NetworkFailure`/
/// `AuthenticationFailure`) with a required *named* `message` param — it
/// can't be instantiated directly. The generic catches below use
/// `ServerFailure` as the closest fit for "something unexpected went
/// wrong talking to the data source." Swap in `NetworkFailure`/
/// `CacheFailure`/`AuthenticationFailure` at specific call sites once you
/// have real error types to distinguish (e.g. a `DioException` for no
/// connectivity vs. a 401 from the API).
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required ProfileRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Result<WorkerProfile>> getProfile() async {
    try {
      final profile = await _remoteDataSource.fetchProfile();
      return Success(profile);
    } catch (e) {
      return Failed(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<WorkerProfile>> updateProfile(WorkerProfile profile) async {
    try {
      final updated = await _remoteDataSource
          .updateProfile(WorkerProfileModel.fromEntity(profile));
      return Success(updated);
    } catch (e) {
      return Failed(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> changePassword(
      {required String currentPassword, required String newPassword}) async {
    try {
      await _remoteDataSource.changePassword(
          currentPassword: currentPassword, newPassword: newPassword);
      return const Success(null);
    } catch (e) {
      return Failed(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remoteDataSource.logout();
      // TODO: also clear your SessionManager here, e.g.
      // await sessionManager.clearSession();
      return const Success(null);
    } catch (e) {
      return Failed(ServerFailure(message: e.toString()));
    }
  }
}
