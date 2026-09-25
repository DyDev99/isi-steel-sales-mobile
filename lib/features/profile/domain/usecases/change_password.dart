import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/repositories/profile_repository.dart';

class ChangePasswordParams extends Equatable {
  const ChangePasswordParams(
      {required this.currentPassword, required this.newPassword});
  final String currentPassword;
  final String newPassword;
  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class ChangePassword implements UseCase<void, ChangePasswordParams> {
  const ChangePassword(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Result<void>> call(ChangePasswordParams params) =>
      _repository.changePassword(
        currentPassword: params.currentPassword,
        newPassword: params.newPassword,
      );
}
