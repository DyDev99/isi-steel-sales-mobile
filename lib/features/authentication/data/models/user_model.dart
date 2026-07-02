import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';

/// Data-layer representation of [User]. Extends the entity so it can be
/// passed anywhere a [User] is expected, with JSON (de)serialisation added.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.company,
    super.avatarUrl,
  });

  factory UserModel.fromMap(DataMap map) => UserModel(
        id: map['id']?.toString() ?? '',
        email: map['email'] as String? ?? '',
        fullName: (map['full_name'] ?? map['name']) as String? ?? '',
        company: map['company'] as String?,
        avatarUrl: map['avatar_url'] as String?,
      );

  factory UserModel.fromEntity(User user) => UserModel(
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        company: user.company,
        avatarUrl: user.avatarUrl,
      );

  DataMap toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'company': company,
        'avatar_url': avatarUrl,
      };
}
