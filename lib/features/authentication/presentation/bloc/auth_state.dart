import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/otp_challenge.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => const [];
}

/// Idle, before any auth check has run.
final class AuthInitialState extends AuthState {
  const AuthInitialState();
}

/// A request is in flight (LoginScreen maps this to `verifying`).
final class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

/// Signed in (LoginScreen maps this to `success`).
final class AuthenticatedState extends AuthState {
  const AuthenticatedState(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

/// No session / signed out (LoginScreen treats this as idle).
final class UnauthenticatedState extends AuthState {
  const UnauthenticatedState();
}

/// Browsing without an account. This is the *default* resting state for a
/// user who finished onboarding but never signed in — the app is fully
/// usable, and protected features prompt for login on demand (see
/// `AuthGuard`). Distinct from [UnauthenticatedState] (a transient
/// "must re-authenticate" signal), a guest is a first-class, expected user.
final class AuthGuestState extends AuthState {
  const AuthGuestState();
}

/// The password was accepted and a code is on its way. **Not a signed-in
/// state** — step 3 has not run, so no token exists at all and
/// [SessionManager] is deliberately untouched.
final class AuthOtpRequiredState extends AuthState {
  const AuthOtpRequiredState({required this.challenge, this.destination});

  /// Drives the screen: [OtpChallenge.otpLength] sizes the boxes and
  /// [OtpChallenge.expiresIn] drives the countdown. Both come from server
  /// configuration and must not be hard-coded.
  final OtpChallenge challenge;

  /// The phone number the code went to, as the user typed it, for the
  /// "we sent a code to …" line.
  final String? destination;

  @override
  List<Object?> get props => [challenge, destination];
}

/// The code or the attempt was rejected.
///
/// Distinct from [AuthFailureState] so the verify screen shows the error in
/// place rather than bouncing to login and making the user retype a password
/// they got right.
final class AuthOtpFailureState extends AuthState {
  const AuthOtpFailureState({
    required this.message,
    this.attemptDead = false,
  });

  final String message;

  /// True when the attempt cannot be rescued — five wrong codes, an expired
  /// window, a spent id, or the resend budget gone. The screen must send the
  /// user back to step 1 and **not** offer a resend.
  final bool attemptDead;

  @override
  List<Object?> get props => [message, attemptDead];
}

/// A request failed (LoginScreen maps this to `error`).
final class AuthFailureState extends AuthState {
  const AuthFailureState(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
