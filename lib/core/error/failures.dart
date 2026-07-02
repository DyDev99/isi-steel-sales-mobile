import 'package:equatable/equatable.dart';

/// Domain-level error type. Sealed so presentation code can exhaustively
/// map each variant to a user-facing message if it wants to.
sealed class Failure extends Equatable {
  const Failure({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

final class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

final class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

final class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection.'});
}

/// Invalid credentials, expired token, or no active session.
final class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.statusCode});
}
