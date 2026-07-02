import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';

/// The contract the domain depends on. The data layer provides the
/// implementation; the domain never knows about Dio, JSON, or storage.
abstract interface class AuthRepository {
  ResultFuture<User> login({required String email, required String password});
  ResultFuture<User> getCurrentUser();
  ResultFuture<void> logout();
}
