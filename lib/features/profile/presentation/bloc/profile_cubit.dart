import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/entities/worker_profile.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/usecases/change_password.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/usecases/get_worker_profile.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/usecases/logout_worker.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/usecases/update_worker_profile.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_state.dart';

/// Loads and mutates the signed-in worker's profile. Single-cubit shape,
/// mirroring `RouteDashboardCubit`.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetWorkerProfile getWorkerProfile,
    required UpdateWorkerProfile updateWorkerProfile,
    required ChangePassword changePassword,
    required LogoutWorker logoutWorker,
  })  : _getWorkerProfile = getWorkerProfile,
        _updateWorkerProfile = updateWorkerProfile,
        _changePassword = changePassword,
        _logoutWorker = logoutWorker,
        super(const ProfileLoading());

  final GetWorkerProfile _getWorkerProfile;
  final UpdateWorkerProfile _updateWorkerProfile;
  final ChangePassword _changePassword;
  final LogoutWorker _logoutWorker;

  Future<void> load() async {
    emit(const ProfileLoading());
    final result = await _getWorkerProfile(const NoParams());
    result.when(
      success: (profile) => emit(ProfileLoaded(profile: profile)),
      failure: (f) => emit(ProfileError(f.message)),
    );
  }

  /// Returns true on success so the sheet UI can close/show a snackbar.
  Future<bool> updateProfile(WorkerProfile updated) async {
    final current = state;
    if (current is! ProfileLoaded) return false;
    emit(current.copyWith(isSaving: true, actionError: () => null));
    final result = await _updateWorkerProfile(updated);
    return result.when(
      success: (profile) {
        emit(ProfileLoaded(profile: profile));
        return true;
      },
      failure: (f) {
        emit(current.copyWith(isSaving: false, actionError: () => f.message));
        return false;
      },
    );
  }

  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    final current = state;
    if (current is! ProfileLoaded) return false;
    emit(current.copyWith(isSaving: true, actionError: () => null));
    final result = await _changePassword(
      ChangePasswordParams(currentPassword: currentPassword, newPassword: newPassword),
    );
    return result.when(
      success: (_) {
        emit(current.copyWith(isSaving: false));
        return true;
      },
      failure: (f) {
        emit(current.copyWith(isSaving: false, actionError: () => f.message));
        return false;
      },
    );
  }

  /// Returns true on success so the caller can proceed to clear the app's
  /// auth session (see `ProfileScreen`, which follows this with an
  /// `AuthBloc` `LogoutRequested` to clear the real token store and
  /// trigger navigation to login).
  Future<bool> logout() async {
    final result = await _logoutWorker(const NoParams());
    return result.when(
      success: (_) {
        emit(const ProfileLoggedOut());
        return true;
      },
      failure: (f) {
        emit(ProfileError(f.message));
        return false;
      },
    );
  }
}
