import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_profile.dart';
import 'package:isi_steel_sales_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/profile/data/models/worker_profile_model.dart';

/// The signed-in employee's profile, sourced from the auth layer.
///
/// This replaces `MockProfileRemoteDataSource`, which served a hardcoded
/// "Alex Morgan / ISI-2291" to every user regardless of who had signed in.
///
/// There is no separate profile service to call: `GET /auth/me` already
/// returns the authoritative record, and the session cache already holds a
/// copy. Adding a second fetch path would create a second answer to "who is
/// signed in", and the two would drift.
class AuthBackedProfileDataSource implements ProfileRemoteDataSource {
  const AuthBackedProfileDataSource({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required AppLogger logger,
  })  : _remote = remote,
        _local = local,
        _logger = logger;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final AppLogger _logger;

  /// Fresh from `/auth/me`, falling back to the cached session when the call
  /// fails.
  ///
  /// The fallback is the point: a rep opening their profile in a warehouse
  /// with no signal should see who they are, not an error. The cached copy was
  /// written at sign-in and is the same shape, so the screen renders
  /// identically — it is simply not re-verified.
  @override
  Future<WorkerProfileModel> fetchProfile() async {
    try {
      final profile = await _remote.getProfile();
      await _local.cacheProfile(profile);
      _logger.debug('profile.loaded', fields: {'source': 'remote'});
      return _toWorker(profile);
    } on ApiException catch (e) {
      final cached = await _local.readProfile();
      if (cached == null) rethrow;

      _logger.warning('profile.loaded', fields: {
        'source': 'cache',
        'errorCode': e.error.code,
      });
      return _toWorker(cached);
    }
  }

  /// Not supported: the API exposes no profile-update endpoint.
  ///
  /// `/auth/me` is read-only, and the guide documents no `PUT`. Employee
  /// records are HR-owned and flow in from the directory, so a field rep
  /// editing their own territory here would either be silently discarded or
  /// contradict the system of record on the next sync. Invented endpoints fail
  /// at runtime on the user's device rather than here.
  ///
  /// [ProfileScreen] hides the edit action for this reason; this exists so a
  /// future caller that ignores that gets a clear failure rather than a 404.
  @override
  Future<WorkerProfileModel> updateProfile(WorkerProfileModel profile) {
    throw const ServerException(
      message: 'Profile details are managed by HR and cannot be edited here.',
      statusCode: 405,
    );
  }

  /// Real password change. The server re-verifies [currentPassword] even
  /// though the caller is authenticated — that is what stops a borrowed
  /// unlocked handset becoming a permanent account takeover.
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _remote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  /// Sign-out is owned by `AuthBloc`, which clears the token store, every
  /// session-scoped store, and restarts the app.
  ///
  /// [ProfileScreen] already dispatches `LogoutRequested` after this returns,
  /// so revoking here as well would end the session twice — the second call
  /// presenting a refresh token the first one already retired, which reuse
  /// detection reads as theft.
  @override
  Future<void> logout() async {
    _logger.debug('profile.logout.delegated');
  }

  /// Maps the auth profile onto the shape this feature renders.
  WorkerProfileModel _toWorker(AuthProfile p) => WorkerProfileModel(
        id: p.id,
        fullName: p.fullName,
        employeeCode: p.employeeId,
        // The HR job title, falling back to the coarse role bucket.
        role: p.positionOrRoleLabel ?? '',
        email: p.email,
        phone: p.phoneNumber ?? '',
        territory: p.territoryCode ?? '',
        // `region` has no direct counterpart; the depot is the nearest real
        // organisational unit, with department as a fallback.
        region: p.depotCode ?? p.department ?? '',
        // Absent by design — see [WorkerProfile.joinedAt].
        joinedAt: null,
        avatarUrl: p.avatarUrl,
        // Reaching /auth/me at all requires an unexpired, unrevoked token on a
        // non-disabled account, so a rendered profile is an active one.
        isActive: true,
      );
}
