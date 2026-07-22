import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';

/// The SAP façade's `POST /api/Auth/Login` reply.
///
/// The live server returns **PascalCase**:
/// ```json
/// { "Token": "...", "ExpiresAt": "...", "Username": "Mobile", "Role": "Operator" }
/// ```
/// The technical document (`SapAPI_Technical_Document_v1_BP.docx` §3.2) shows
/// camelCase (`token`/`expiresAt`/…), which is ASP.NET Core's default. The two
/// disagree, so [fromJson] reads **case-insensitively** rather than betting on
/// one casing — a `JsonSerializerOptions` change server-side must not silently
/// break sign-in again.
class SapAuthResponseModel {
  const SapAuthResponseModel({
    required this.token,
    required this.expiresAt,
    required this.username,
    required this.role,
  });

  final String token;
  final DateTime expiresAt;
  final String username;
  final String role;

  factory SapAuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Read by lower-cased key so `Token` and `token` both resolve. Built once
    // rather than lower-casing at each lookup. If two keys collide only in case
    // (never seen from this façade), last-wins — acceptable for a flat DTO.
    final ci = <String, dynamic>{
      for (final entry in json.entries) entry.key.toLowerCase(): entry.value,
    };

    final token = ci['token'];
    if (token is! String || token.isEmpty) {
      // Key *names* only, never values (`docs/SECURITY.md` §10). If this ever
      // fires again, the key list is the one-glance diagnosis.
      throw FormatException(
        'SAP login response contained no token. '
        'Keys present: ${json.keys.toList()..sort()}.',
      );
    }

    final rawExpiry = ci['expiresat'];
    return SapAuthResponseModel(
      token: token,
      // A missing or unparsable expiry is treated as *already expired* rather
      // than as "never expires". Renewing too eagerly costs one extra login;
      // trusting a bad expiry means every later call 401s with no recovery.
      expiresAt: rawExpiry is String
          ? (DateTime.tryParse(rawExpiry) ??
              DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0),
      username: ci['username'] as String? ?? '',
      role: ci['role'] as String? ?? '',
    );
  }
}

/// Maps the SAP login reply onto the app's [User].
///
/// SAP authenticates a *named API account*, not a CRM person: the reply carries
/// only `username` and `role`. The app's `User` was shaped around an ISI-style
/// profile (id, email, full name, avatar, company), so most of it has no SAP
/// source.
///
/// Rather than invent values, the mapping states what is true:
/// * `id` and `fullName` take the SAP username — it is the only identifier SAP
///   supplies, and it is stable.
/// * `email` is left empty. SAP does not return one, and fabricating
///   `username@…` would produce an address that looks real and does not exist.
/// * `company` and `avatarUrl` stay null.
extension SapAuthResponseMapper on SapAuthResponseModel {
  User toUser() => User(
        id: username,
        email: '',
        fullName: username,
        roles: {SapRoleMapper.toUserRole(role)},
      );
}

/// Translates SAP's role string onto [UserRole].
///
/// The technical document names only `Admin` and `Operator` (§4, §6.3). The
/// mapping is deliberately conservative: anything unrecognised becomes
/// [UserRole.guest] — the least-privileged role — so a new or misspelled SAP
/// role can never silently grant elevated access in the app.
abstract final class SapRoleMapper {
  const SapRoleMapper._();

  static UserRole toUserRole(String role) => switch (role.toLowerCase()) {
        'admin' => UserRole.admin,
        'manager' => UserRole.manager,
        'operator' || 'salesrep' || 'sales_rep' => UserRole.salesRep,
        _ => UserRole.guest,
      };
}
