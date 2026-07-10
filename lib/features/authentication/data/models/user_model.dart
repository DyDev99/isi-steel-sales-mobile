import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';

/// Data-layer representation of [User]. Extends the entity so it can be
/// passed anywhere a [User] is expected, with JSON (de)serialisation added.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.roles, // 1. Added missing required super field
    super.company,
    super.avatarUrl,
  });

  factory UserModel.fromMap(DataMap map) => UserModel(
        id: map['id']?.toString() ?? '',
        email: map['email'] as String? ?? '',
        fullName: (map['full_name'] ?? map['name']) as String? ?? '',
        // 2. Safely maps the incoming JSON array to a Set of UserRole enums
        roles: ((map['roles'] ?? map['user_roles']) as List<dynamic>?)
                ?.map((e) => UserRole.values.byName(e as String))
                .toSet() ??
            {},
        company: map['company'] as String?,
        avatarUrl: map['avatar_url'] as String?,
      );

  factory UserModel.fromEntity(User user) => UserModel(
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        roles: user.roles, // 3. Pass roles forward from domain entity
        company: user.company,
        avatarUrl: user.avatarUrl,
      );

  DataMap toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        // 4. Converts the enum Set back to a list of clean strings for the API/DB
        'roles': roles.map((e) => e.name).toList(),
        'company': company,
        'avatar_url': avatarUrl,
      };
}
