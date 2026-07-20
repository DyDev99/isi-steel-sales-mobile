import 'package:equatable/equatable.dart';

/// The single error vocabulary of the networking layer.
///
/// Every backend fault — SAP, ISI, and any service added later — arrives at the
/// feature layer as one of these. `DioException` is caught at the interceptor
/// boundary and never escapes `core/api_client`, so no feature imports `dio`
/// (`docs/ENGINEERING_STANDARD.md` §7).
///
/// These are *transport* errors. Repositories translate them into the domain
/// `Failure` hierarchy in `core/error/failures.dart`; presentation sees only
/// `Failure`.
sealed class ApiException extends Equatable implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.endpoint,
    this.requestId,
  });

  final String message;
  final int? statusCode;

  /// Path only — never the full URL with query parameters, which on the
  /// Customer endpoints carry names and customer numbers
  /// (`docs/SECURITY.md` §10).
  final String? endpoint;

  /// Correlation id echoed by the server, when it supplies one. Safe to log and
  /// the fastest way to find one request in a backend trace.
  final String? requestId;

  @override
  List<Object?> get props => [message, statusCode, endpoint, requestId];

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// The device has no usable connectivity. Raised *before* a request is sent.
final class NoInternetException extends ApiException {
  const NoInternetException({
    super.message = 'No internet connection.',
    super.endpoint,
  });
}

/// A transport-level failure with connectivity apparently present — DNS
/// failure, connection refused, socket dropped mid-flight.
final class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'The network request could not be completed.',
    super.endpoint,
  });
}

/// The request exceeded its deadline.
///
/// Named `ApiTimeoutException`, not `TimeoutException`, so it cannot collide
/// with `dart:async`'s type of that name in any file importing both.
final class ApiTimeoutException extends ApiException {
  const ApiTimeoutException({
    super.message = 'The request timed out.',
    super.endpoint,
  });
}

/// TLS failure — certificate not trusted, or it did not match the configured
/// pin. Distinct from [NetworkException] because the remedy is completely
/// different: a pin refresh, not a retry.
final class SslException extends ApiException {
  const SslException({required super.message, super.endpoint});
}

/// HTTP 401. The session is absent, expired, or rejected.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Session expired. Please sign in again.',
    super.statusCode = 401,
    super.endpoint,
  });
}

/// HTTP 403. Authenticated, but the account's role is not permitted.
final class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'You do not have access to this resource.',
    super.statusCode = 403,
    super.endpoint,
  });
}

/// HTTP 404 where the absence is meaningful rather than a fault.
final class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Not found.',
    super.statusCode = 404,
    super.endpoint,
  });
}

/// HTTP 400/422 — the server rejected the payload.
final class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    super.statusCode,
    super.endpoint,
    this.fieldErrors = const {},
  });

  /// Field name → message, when the backend reports errors per field.
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// HTTP 5xx.
final class ServerException extends ApiException {
  const ServerException({
    super.message = 'The server encountered an error.',
    super.statusCode,
    super.endpoint,
  });
}

/// A SAP-specific business fault.
///
/// SAP is the one backend that can report failure inside a `200 OK` — a
/// `Create`/`Update` answers with `success: false` and a populated `messages`
/// array (`SapAPI_Technical_Document_v1_BP.docx` §5.4). A generic status-code
/// mapping would read that as success, so it gets its own type carrying SAP's
/// diagnostic entries.
final class SapException extends ApiException {
  const SapException({
    required super.message,
    this.messages = const [],
    super.statusCode,
    super.endpoint,
  });

  final List<SapDiagnostic> messages;

  bool get hasError => messages.any((m) => m.isError);

  @override
  List<Object?> get props => [...super.props, messages];
}

/// The configured SAP `conId` is unknown or inactive.
///
/// Separate from [NotFoundException] because SAP overloads 404: it means both
/// "no rows matched" (routine) and "this connection id does not exist"
/// (misconfiguration). Collapsing them would hide a broken deployment behind an
/// empty list forever.
final class SapConnectionException extends ApiException {
  const SapConnectionException({
    required super.message,
    super.statusCode = 404,
    super.endpoint,
  });
}

/// One entry of SAP's `messages` array (technical document §6.2).
class SapDiagnostic extends Equatable {
  const SapDiagnostic({
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

  bool get isError => type == 'E' || type == 'A';

  /// SAP's diagnostic reference, e.g. `F2/003`.
  String? get code => (id == null || number == null) ? null : '$id/$number';

  @override
  List<Object?> get props => [type, message, id, number];
}

// NOTE: there is deliberately no `CacheException` here.
//
// A cache failure is a persistence concern, not a transport one — it belongs to
// `core/error/exceptions.dart`, which already defines it and which the local
// datasources already throw. Duplicating the name in this file would mean any
// repository importing both (the normal case: a remote call plus a local write)
// gets an ambiguous reference, and would blur the boundary this layer exists to
// draw.
//
// Repositories import this library with a prefix (`as net`) where they also use
// the persistence exceptions, so `net.ServerException` and `ServerException`
// stay unambiguous.
