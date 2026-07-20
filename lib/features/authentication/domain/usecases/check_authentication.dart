import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';

/// Resolves whether a usable session exists, without touching the network.
///
/// Drives the splash decision — MainShell or Login — so boot must not depend on
/// connectivity (`docs/OFFLINE_FIRST.md` §2.1). A rep opening the app in a
/// warehouse with no signal still lands in the app on their cached session.
///
/// Distinct from `GetCurrentUser` only in intent: this is the boot-time gate,
/// and naming it for that purpose keeps the splash from looking like it is
/// fetching a profile.
class CheckAuthentication extends UseCase<User, NoParams> {
  CheckAuthentication(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<User> call(NoParams params) => _repository.getCurrentUser();
}
