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
