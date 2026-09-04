import 'package:isi_steel_sales_mobile/features/profile/data/models/worker_profile_model.dart';

/// Talks to the profile API. `MockProfileRemoteDataSource` below is a
/// stand-in so the feature runs end-to-end today — replace it with a real
/// implementation (Dio/ApiClient call) that matches how `RouteRepository`
/// or `AuthRepository` hits your backend elsewhere in this app, then swap
/// the registration in your DI container.
abstract class ProfileRemoteDataSource {
  Future<WorkerProfileModel> fetchProfile();
  Future<WorkerProfileModel> updateProfile(WorkerProfileModel profile);
  Future<void> changePassword(
      {required String currentPassword, required String newPassword});
  Future<void> logout();
}

class MockProfileRemoteDataSource implements ProfileRemoteDataSource {
  MockProfileRemoteDataSource();

  WorkerProfileModel _current = WorkerProfileModel(
    id: 'w-001',
    fullName: 'Alex Morgan',
    employeeCode: 'ISI-2291',
    role: 'Sales Representative',
    email: 'alex.morgan@isisteel.com',
    phone: '+1 555 010 2938',
    territory: 'North Metro',
    region: 'Region 3',
    joinedAt: DateTime(2023, 4, 12),
    avatarUrl: null,
    isActive: true,
  );

  @override
  Future<WorkerProfileModel> fetchProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _current;
  }

  @override
  Future<WorkerProfileModel> updateProfile(WorkerProfileModel profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _current = profile;
    return _current;
  }

  @override
  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // TODO: validate currentPassword against backend once wired up.
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
