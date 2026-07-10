import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/entities/worker_profile.dart';

/// Contract for reading/updating the signed-in worker's profile.
/// Implemented by `ProfileRepositoryImpl` in the data layer.
abstract class ProfileRepository {
  Future<Result<WorkerProfile>> getProfile();

  Future<Result<WorkerProfile>> updateProfile(WorkerProfile profile);

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Clears the worker's session. Wire this to your `SessionManager`
  /// (see `RouteSyncCubit` for how the routes feature holds one) inside
  /// `ProfileRepositoryImpl`.
  Future<Result<void>> logout();
}
