import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => const [];
}

/// Fired once on app start to resolve any persisted session.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Enter guest browsing explicitly (e.g. after onboarding completes, or when
/// the user dismisses a login prompt with "Later"). Idempotent — safe to fire
/// even if already a guest.
final class AuthGuestRequested extends AuthEvent {
  const AuthGuestRequested();
}

/// Fired by the login form. Name + shape must match LoginScreen.
final class LoginSubmittedEvent extends AuthEvent {
  const LoginSubmittedEvent({
    required this.identifier,
    required this.password,
    this.rememberDevice = true,
  });

  /// Employee ID **or** e-mail address. The form has one field because the
  /// server accepts either: field reps know their personnel number and often
  /// have no company e-mail, portal users keep using theirs.
  final String identifier;
  final String password;

  /// Protects this device from being retired first once the user exceeds five
  /// concurrent sessions.
  final bool rememberDevice;

  @override
  List<Object?> get props => [identifier, password, rememberDevice];
}

/// Step 1 of the sales-rep flow: phone + password.
///
/// The password lives only for this event — it is spent at `send-otp` and is
/// never re-sent, so nothing holds it afterwards.
final class PhoneLoginSubmitted extends AuthEvent {
  const PhoneLoginSubmitted({
    required this.phoneNumber,
    required this.password,
  });

  /// **As the user typed it.** The server matches on digits, so spaces, dashes
  /// and a `+855` prefix all resolve to the same account — reformatting here
  /// would only risk breaking a form the server already accepts.
  final String phoneNumber;
  final String password;

  @override
  List<Object?> get props => [phoneNumber, password];
}

/// The code from the verify screen. Length comes from the challenge, not a
/// constant.
final class OtpSubmitted extends AuthEvent {
  const OtpSubmitted(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}

/// Ask for a fresh code.
final class OtpResendRequested extends AuthEvent {
  const OtpResendRequested();
}

/// The user backed out of the code screen.
///
/// Not the same as doing nothing: credentials were accepted and tokens are on
/// disk, so abandoning here must clear them. Otherwise the next launch would
/// restore a session that never finished its challenge.
final class OtpAbandoned extends AuthEvent {
  const OtpAbandoned();
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested({this.allDevices = false});

  /// Ends every session rather than just this one. Offer it after a password
  /// change or a suspected compromise.
  final bool allDevices;

  @override
  List<Object?> get props => [allDevices];
}
