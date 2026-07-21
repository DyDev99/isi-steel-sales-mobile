import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';

/// The SAP façade's `POST /api/Auth/Login` reply.
///
/// ```json
/// { "token": "...", "expiresAt": "...", "username": "...", "role": "Admin" }
/// ```
///
/// (`SapAPI_Technical_Document_v1_BP.docx` §3.2.)
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
    final token = json['token'];
    if (token is! String || token.isEmpty) {
      // The key *names* are named in the message, never the values. A response
      // shape mismatch is the likeliest cause of this failure and is otherwise
      // invisible: the façade is ASP.NET Core, which camelCases by default, but
      // a `JsonSerializerOptions` change server-side would emit `Token` /
      // `ExpiresAt` instead and every field would silently read as null.
      // Listing the keys turns that into a one-glance diagnosis.
      //
      // Safe under `docs/SECURITY.md` §10: key names carry no PII, and the
      // token value itself is never included.
      throw FormatException(
        'SAP login response contained no "token" key. '
        'Keys present: ${json.keys.toList()..sort()}. '
        'If these are PascalCase, the façade\'s JSON casing has changed and '
        'this mapper needs updating.',
      );
    }

    final rawExpiry = json['expiresAt'];
    return SapAuthResponseModel(
      token: token,
      // A missing or unparsable expiry is treated as *already expired* rather
      // than as "never expires". Renewing too eagerly costs one extra login;
      // trusting a bad expiry means every later call 401s with no recovery.
      expiresAt: rawExpiry is String
          ? (DateTime.tryParse(rawExpiry) ??
              DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0),
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
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
