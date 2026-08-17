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

/// The device has a working network, but the ISI gateway did not answer.
///
/// Deliberately distinct from [NetworkFailure]. Telling a user standing on
/// office WiFi that they have "no internet connection" sends them to check
/// their signal, their router and their data plan — none of which is the
/// problem. The causes here are a wrong `API_BASE_URL`, a backend that is not
/// running, an expired tunnel, or a VPN that is off; every one of them is
/// actionable, and none of them looks like the message the user was given.
final class ServerUnreachableFailure extends Failure {
  const ServerUnreachableFailure({
    super.message = 'Cannot reach the ISI server.',
  });
}

/// Invalid credentials, expired token, or no active session.
final class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.statusCode,
    this.code,
  });

  /// The stable platform code, kept so the presentation layer can tell a
  /// recoverable wrong code from a dead sign-in attempt.
  final String? code;

  @override
  List<Object?> get props => [message, statusCode, code];
}

/// Codes that mean the OTP attempt cannot be rescued — the user must start
/// again from step 1 rather than retyping the code.
extension AttemptLifetime on Failure {
  bool get isAttemptDead {
    final self = this;
    if (self is! AuthenticationFailure) return false;
    return const {
      'Auth.VerificationBlocked',
      'Auth.VerificationExpired',
      'Auth.VerificationNotFound',
      'Auth.VerificationNotCompleted',
      'Auth.ResendLimitReached',
    }.contains(self.code);
  }
}
