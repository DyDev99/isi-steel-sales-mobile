import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_token.dart';

class AuthTokenModel extends AuthToken {
  const AuthTokenModel({
    required super.accessToken,
    required super.refreshToken,
  });

  factory AuthTokenModel.fromMap(DataMap map) => AuthTokenModel(
        accessToken: map['access_token'] as String? ?? '',
        refreshToken: map['refresh_token'] as String? ?? '',
      );

  DataMap toMap() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
      };
}
