/// A bearer session for one backend.
///
/// Backend-agnostic on purpose: SAP issues a ~60-minute JWT with no refresh
/// token, while the ISI backend has a refresh endpoint. Both fit here — SAP
/// simply leaves [refreshToken] null — so the auth interceptor works against one
/// shape rather than one per service.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.username = '',
    this.role = '',
  });

  final String accessToken;
  final DateTime expiresAt;

  /// Null where the backend issues none. SAP has no refresh endpoint
  /// (`SapAPI_Technical_Document_v1_BP.docx` §3.2), so renewal there means
  /// re-authenticating with stored credentials.
  final String? refreshToken;

  final String username;
  final String role;

  /// Treats a token as expired slightly early so a request is not dispatched
  /// with one that lapses in flight — which would surface as a spurious 401 and
  /// an avoidable retry.
  static const skew = Duration(minutes: 1);

  bool get isExpired =>
      DateTime.now().toUtc().isAfter(expiresAt.toUtc().subtract(skew));

  bool get isValid => accessToken.isNotEmpty && !isExpired;

  bool get canRefresh => refreshToken != null && refreshToken!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'expiresAt': expiresAt.toIso8601String(),
        'refreshToken': refreshToken,
        'username': username,
        'role': role,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String? ?? '',
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        refreshToken: json['refreshToken'] as String?,
        username: json['username'] as String? ?? '',
        role: json['role'] as String? ?? '',
      );

  /// Parses SAP's login reply: `{token, expiresAt, username, role}`.
  factory AuthSession.fromSapLogin(Map<String, dynamic> json) {
    final token = json['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('SAP login response contained no token.');
    }
    final expiresAt = json['expiresAt'];
    return AuthSession(
      accessToken: token,
      // A malformed or missing expiry is treated as already expired rather than
      // as "never expires". Re-authenticating too eagerly costs a login;
      // trusting a bad expiry costs a hard 401 on every later call with no
      // recovery path.
      expiresAt: expiresAt is String
          ? (DateTime.tryParse(expiresAt) ??
              DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0),
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}

/// Credentials used to obtain, and silently renew, a session.
class AuthCredentials {
  const AuthCredentials({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };

  factory AuthCredentials.fromJson(Map<String, dynamic> json) =>
      AuthCredentials(
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );

  /// Never include [password] in any diagnostic string.
  @override
  String toString() => 'AuthCredentials($username)';
}
