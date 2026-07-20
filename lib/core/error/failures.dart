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

/// Local input failed validation before any request was attempted.
final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// A bounded network operation exceeded its deadline.
final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'The request timed out.'});
}

// ── SAP-specific failures ──────────────────────────────────────────────────
// The SAP backend is the `SapAPI` ASP.NET façade over S/4HANA. Its errors are
// distinguishable from generic HTTP errors and are surfaced as their own types
// so presentation can tell "SAP rejected this" from "the network is down".

/// Login failed, or the ~60-minute JWT expired and could not be renewed.
///
/// The SAP façade exposes no refresh endpoint (technical document §3.2), so
/// renewal means re-authenticating with the user's credentials.
final class SapAuthenticationFailure extends Failure {
  const SapAuthenticationFailure({
    required super.message,
    super.statusCode = 401,
  });
}

/// The token was valid but the account's role is not permitted (HTTP 403).
final class SapForbiddenFailure extends Failure {
  const SapForbiddenFailure({
    required super.message,
    super.statusCode = 403,
  });
}

/// SAP itself rejected a business-partner read/write (HTTP 422), or returned
/// `type: 'E' | 'A'` entries in its `messages` array.
///
/// [messages] preserves the SAP diagnostic codes so they can be logged and
/// shown to support without re-parsing the response.
final class SapBusinessPartnerFailure extends Failure {
  const SapBusinessPartnerFailure({
    required super.message,
    this.messages = const [],
    super.statusCode,
  });

  final List<SapMessage> messages;

  @override
  List<Object?> get props => [message, statusCode, messages];
}

/// The SAP façade reached SAP but the call failed server-side (HTTP 500), or
/// the RFC connection to S/4HANA is down.
final class SapServerFailure extends Failure {
  const SapServerFailure({required super.message, super.statusCode});
}

/// The configured `conId` does not exist or is inactive on the server.
///
/// Distinct from "no rows matched": both surface as HTTP 404, but only this one
/// is a misconfiguration rather than an empty result (technical document §4.4).
final class SapConnectionIdFailure extends Failure {
  const SapConnectionIdFailure({
    required super.message,
    super.statusCode = 404,
  });
}

/// No certificate pin is configured, or the server presented a certificate that
/// does not match it.
///
/// The SAP host serves HTTPS on a raw IP with a self-signed certificate, so
/// pinning is the only way to authenticate it. Absent or mismatched, the client
/// fails closed rather than trusting an unverified peer.
final class SapCertificatePinFailure extends Failure {
  const SapCertificatePinFailure({required super.message});
}

/// One entry of SAP's `messages` array (technical document §6.2).
class SapMessage extends Equatable {
  const SapMessage({
    required this.type,
    required this.message,
    this.id,
    this.number,
  });

  /// `S` success · `I` info · `W` warning · `E` error · `A` abort.
  final String type;
  final String message;
  final String? id;
  final String? number;

  /// Whether this entry represents a failure rather than information.
  bool get isError => type == 'E' || type == 'A';

  /// SAP's own diagnostic reference, e.g. `F2/003`, or null when absent.
  String? get code => (id == null || number == null) ? null : '$id/$number';

  @override
  List<Object?> get props => [type, message, id, number];
}
