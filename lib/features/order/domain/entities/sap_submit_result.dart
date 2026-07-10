import 'package:equatable/equatable.dart';

/// Outcome of pushing one quotation to SAP. Sealed so the sync processor must
/// handle every branch explicitly — the difference between a *retryable*
/// transport failure and a *terminal* business rejection is the crux of a
/// correct retry policy.
sealed class SapSubmitResult extends Equatable {
  const SapSubmitResult();
  @override
  List<Object?> get props => [];
}

/// SAP created the document. Carries everything the spec asks to persist.
final class SapAccepted extends SapSubmitResult {
  const SapAccepted({
    required this.documentNumber,
    required this.message,
    required this.timestamp,
  });
  final String documentNumber;
  final String message;
  final DateTime timestamp;

  @override
  List<Object?> get props => [documentNumber, message, timestamp];
}

/// SAP reached the request but rejected it on business rules (credit limit,
/// expired promotion…). Terminal — retrying the same payload won't help, so
/// the user must act.
final class SapRejected extends SapSubmitResult {
  const SapRejected({required this.errorCode, required this.message});
  final String errorCode;
  final String message;

  @override
  List<Object?> get props => [errorCode, message];
}

/// SAP state diverged from the local draft (customer/price/stock changed).
/// Routed to the conflict queue for a Keep-Local / Use-SAP / Merge decision.
final class SapConflict extends SapSubmitResult {
  const SapConflict({required this.message, this.field});
  final String message;
  final String? field;

  @override
  List<Object?> get props => [message, field];
}

/// The request never got a business answer (offline, timeout, 5xx). Retryable
/// under the backoff policy.
final class SapTransportFailure extends SapSubmitResult {
  const SapTransportFailure({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
