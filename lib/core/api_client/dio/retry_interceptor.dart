import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Retries transient transport failures with exponential backoff.
///
/// ## What is retried
///
/// Only failures where the request provably did not produce a result:
/// connect/receive/send timeouts, and socket-level connection errors.
///
/// ## What is never retried
///
/// * **401 / 403** — authorization does not become valid by asking again.
///   Renewal is [AuthInterceptor]'s job, and it replays the request itself.
/// * **4xx generally** — the request is malformed or rejected; repeating it
///   repeats the rejection.
/// * **5xx** — deliberately excluded. A 500 from the SAP façade means the RFC
///   call reached SAP and failed there; the write may well have been committed
///   before the error, so replaying it risks duplicating it.
/// * **Non-idempotent methods** — see below. This is the important one.
///
/// ## Why POST and PATCH are excluded
///
/// A timeout means the *response* was lost, not that the request never arrived.
/// Retrying `POST /api/Customer/Create` after a timeout can therefore create the
/// customer a second time — a real duplicate in the ERP, produced by the
/// client's own recovery logic and invisible until someone notices two business
/// partners.
///
/// GET, HEAD, PUT and DELETE are idempotent by HTTP contract: repeating them
/// converges on the same state. Those are retried; POST and PATCH are not.
///
/// A POST *can* be made safely retryable with a server-honoured idempotency key
/// — which is exactly what `docs/SYNC_ENGINE.md` §4 specifies for the sync
/// queue. Until the SAP façade accepts such a key, opting POSTs in per-request
/// via [retryableFlag] is available but should be used only where the endpoint
/// is known to deduplicate.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio Function() dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  }) : _dio = dio;

  final Dio Function() _dio;
  final int maxRetries;
  final Duration baseDelay;

  static const _attemptKey = 'retry_attempt';

  /// Per-request opt-in for a non-idempotent call known to be safe to repeat.
  static const String retryableFlag = 'force_retryable';

  static const _idempotentMethods = {'GET', 'HEAD', 'PUT', 'DELETE', 'OPTIONS'};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    // Exponential backoff: 400ms, 800ms, 1600ms… A fixed delay would have every
    // queued request retry in lockstep and hit a recovering server together.
    final delay = baseDelay * (1 << attempt);
    await Future<void>.delayed(delay);

    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;

    try {
      final response = await _dio().fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      // Feed the new failure back through the chain so a subsequent attempt is
      // still counted, and the final error reflects the last try rather than
      // the first.
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    if (!_isTransient(err)) return false;

    final method = err.requestOptions.method.toUpperCase();
    if (_idempotentMethods.contains(method)) return true;

    return err.requestOptions.extra[retryableFlag] == true;
  }

  bool _isTransient(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.connectionError:
        // A refused/dropped socket is transient. A TLS handshake failure is
        // not — the certificate will not start matching the pin on a retry, and
        // repeating it only delays a clear error.
        return err.error is SocketException;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
        return false;
      default:
        return false;
    }
  }
}
