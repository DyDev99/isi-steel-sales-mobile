import 'package:equatable/equatable.dart';
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

/// A request failed (LoginScreen maps this to `error`).
final class AuthFailureState extends AuthState {
  const AuthFailureState(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
