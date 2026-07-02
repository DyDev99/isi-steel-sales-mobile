import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';

class Logout extends UseCase<void, NoParams> {
  const Logout(this._repository);
  final AuthRepository _repository;

  @override
  ResultFuture<void> call(NoParams params) => _repository.logout();
}
