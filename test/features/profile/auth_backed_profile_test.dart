import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/auth_profile_model.dart';
import 'package:isi_steel_sales_mobile/features/profile/data/datasources/auth_backed_profile_data_source.dart';
import 'package:mocktail/mocktail.dart';

import 'profile_test_doubles.dart';

/// The profile screen served a hardcoded "Alex Morgan / ISI-2291" to every
/// user, whoever had signed in. It now reads the real session.
void main() {
  late MockAuthRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late AuthBackedProfileDataSource source;

  /// The live `/auth/me` payload, keys as the server actually sends them.
  final serverProfile = AuthProfileModel.fromJson(const {
    'userId': '019fefd2-1111-4a7f-b0d2-1f9e4c8a2b31',
    'employeeId': 'EMP000202',
    'fullName': 'Sok Dara',
    'email': 'sok.dara@isigroup.com.kh',
    'phoneNumber': '012345678',
    'position': 'Sales Representative',
    'department': 'Sales',
    'roles': ['Sales Representative'],
    'permissions': ['outlets.read', 'visits.create'],
    'territoryCode': 'PP-NORTH',
    'depotCode': 'DEPOT-PP01',
  });

  setUpAll(registerProfileFallbacks);

  setUp(() {
    remote = MockAuthRemoteDataSource();
    local = MockAuthLocalDataSource();
    source = AuthBackedProfileDataSource(
      remote: remote,
      local: local,
      logger: const ConsoleAppLogger(verbose: false),
    );
    when(() => local.cacheProfile(any())).thenAnswer((_) async {});
  });

  test('shows the signed-in employee, not a fixture', () async {
    when(remote.getProfile).thenAnswer((_) async => serverProfile);

    final worker = await source.fetchProfile();

    expect(worker.fullName, 'Sok Dara');
    expect(worker.employeeCode, 'EMP000202');
    expect(worker.email, 'sok.dara@isigroup.com.kh');
    expect(worker.phone, '012345678');
    expect(worker.territory, 'PP-NORTH');
    expect(worker.region, 'DEPOT-PP01');
    // The HR job title, preferred over the coarse role bucket.
    expect(worker.role, 'Sales Representative');
    // `/auth/me` returns no start date; inventing one would be worse than
    // omitting the row.
    expect(worker.joinedAt, isNull);
  });

  test('a fresh profile refreshes the session cache', () async {
    when(remote.getProfile).thenAnswer((_) async => serverProfile);

    await source.fetchProfile();

    // Otherwise the profile screen and the rest of the app would disagree
    // about who is signed in until the next sign-in.
    verify(() => local.cacheProfile(serverProfile)).called(1);
  });

  test('falls back to the cached profile when the call fails', () async {
    // A rep opening their profile in a warehouse with no signal should see
    // who they are, not an error.
    when(remote.getProfile)
        .thenThrow(const ApiException(ApiError(code: ApiErrorCodes.network)));
    when(local.readProfile).thenAnswer((_) async => serverProfile);

    final worker = await source.fetchProfile();

    expect(worker.fullName, 'Sok Dara');
    expect(worker.employeeCode, 'EMP000202');
  });

  test('rethrows when offline with nothing cached', () async {
    // Nothing to show and no way to get it — the screen must surface the
    // error rather than render a blank identity.
    when(remote.getProfile)
        .thenThrow(const ApiException(ApiError(code: ApiErrorCodes.network)));
    when(local.readProfile).thenAnswer((_) async => null);

    await expectLater(source.fetchProfile(), throwsA(isA<ApiException>()));
  });

  test('editing is refused rather than sent to a route that does not exist',
      () async {
    // `/auth/me` is read-only and employee records are HR-owned. Inventing a
    // PUT would fail on the user's device instead of here.
    when(remote.getProfile).thenAnswer((_) async => serverProfile);
    final worker = await source.fetchProfile();

    expect(() => source.updateProfile(worker), throwsA(isA<ServerException>()));
  });

  test('password change goes to the real endpoint', () async {
    when(() => remote.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async {});

    await source.changePassword(
      currentPassword: 'old-password-1',
      newPassword: 'new-password-long-enough',
    );

    verify(() => remote.changePassword(
          currentPassword: 'old-password-1',
          newPassword: 'new-password-long-enough',
        )).called(1);
  });

  test('logout does not revoke — AuthBloc owns that', () async {
    // ProfileScreen dispatches LogoutRequested after this returns. Revoking
    // here too would end the session twice, the second call presenting a
    // refresh token the first already retired — which reuse detection reads
    // as theft.
    await source.logout();

    verifyNever(() => remote.logout(
          refreshToken: any(named: 'refreshToken'),
          allDevices: any(named: 'allDevices'),
        ));
  });
}
