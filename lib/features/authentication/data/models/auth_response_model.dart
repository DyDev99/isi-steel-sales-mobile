import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/auth_token_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/user_model.dart';

/// The login/refresh payload: the user plus the token pair. Tolerant of a
/// couple of common envelope shapes (`{user, ...tokens}` or `{data:{user}}`).
class AuthResponseModel {
  const AuthResponseModel({required this.user, required this.token});

  final UserModel user;
  final AuthTokenModel token;

  factory AuthResponseModel.fromMap(DataMap map) {
    final root = (map['data'] as DataMap?) ?? map;
    final userMap = (root['user'] as DataMap?) ?? root;
    return AuthResponseModel(
      user: UserModel.fromMap(userMap),
      token: AuthTokenModel.fromMap(root),
    );
  }
}
