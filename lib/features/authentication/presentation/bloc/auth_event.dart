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
  const LoginSubmittedEvent({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// The stored SAP session can no longer be renewed.
///
/// Pushed by `TokenManager.onSessionExpired`, not raised by any screen: the
/// auth interceptor discovers this mid-request, deep below the widget tree, and
/// an interceptor can neither navigate nor emit a state. Routing it through the
/// bloc gives the app one place to react.
///
/// Distinct from [LogoutRequested] because the user did not ask for it: the UI
/// should explain that the session ended rather than presenting a normal
/// sign-out.
final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
