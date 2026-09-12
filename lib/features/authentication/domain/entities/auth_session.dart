import 'package:equatable/equatable.dart';

/// One active device session, from `GET /auth/sessions`.
///
/// This list is what a representative uses when they lose a handset — hence
/// the effort spent sending a `device` block at sign-in. Without it the screen
/// is a column of GUIDs nobody can act on.
class AuthSession extends Equatable {
  const AuthSession({
    required this.sessionId,
    required this.deviceId,
    required this.createdAt,
    required this.isCurrent,
    this.deviceName,
    this.ipAddress,
    this.userAgent,
    this.lastSeenAt,
    this.expiresAt,
  });

  final String sessionId;
  final String deviceId;
  final String? deviceName;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final DateTime? expiresAt;

  /// Marks the caller's own session. **Warn before revoking it** — doing so
  /// signs the user out of the device they are holding.
  final bool isCurrent;

  /// A best-effort label for the row, falling back through what the server
  /// supplied so the list never renders a bare identifier.
  String get displayName =>
      deviceName?.trim().isNotEmpty == true ? deviceName!.trim() : deviceId;

  @override
  List<Object?> get props => [sessionId, deviceId, isCurrent, lastSeenAt];
}
