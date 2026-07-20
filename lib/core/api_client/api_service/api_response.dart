/// A backend response, decoupled from Dio.
///
/// `Response<T>` from Dio never leaves `core/api_client`: it drags `dio` into
/// every consumer's imports and exposes `RequestOptions`, headers and redirect
/// history that no datasource should be reasoning about.
///
/// Only successful responses are represented here. Failures are thrown as
/// [ApiException] rather than returned as a `success: false` value — a response
/// object that might not contain data invites callers to forget to check, and
/// the compiler cannot help them. Throwing puts the error on a path they cannot
/// silently ignore.
class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    required this.statusCode,
    this.headers = const {},
    this.message,
    this.requestId,
    required this.timestamp,
    this.duration,
  });

  /// The decoded payload.
  final T data;

  final int statusCode;

  /// Response headers, lower-cased.
  ///
  /// Deliberately excludes `set-cookie` and `authorization` — see
  /// [ApiResponse.fromParts]. Nothing above this layer needs credentials, and
  /// carrying them makes accidental logging of the whole map dangerous.
  final Map<String, String> headers;

  /// Server-supplied human message, when present.
  final String? message;

  /// Correlation id for tracing this call in backend logs.
  final String? requestId;

  /// When the response was received (UTC).
  final DateTime timestamp;

  /// Round-trip duration, when the client measured it.
  final Duration? duration;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Maps the payload while preserving the envelope.
  ApiResponse<R> map<R>(R Function(T data) transform) => ApiResponse<R>(
        data: transform(data),
        statusCode: statusCode,
        headers: headers,
        message: message,
        requestId: requestId,
        timestamp: timestamp,
        duration: duration,
      );

  /// Builds a response, sanitising headers on the way in.
  static ApiResponse<T> fromParts<T>({
    required T data,
    required int statusCode,
    Map<String, List<String>>? rawHeaders,
    String? message,
    Duration? duration,
  }) {
    final headers = <String, String>{};
    if (rawHeaders != null) {
      for (final entry in rawHeaders.entries) {
        final key = entry.key.toLowerCase();
        // Credential-bearing headers are dropped at the boundary rather than
        // relied on never being logged downstream.
        if (_sensitiveHeaders.contains(key)) continue;
        if (entry.value.isEmpty) continue;
        headers[key] = entry.value.join(', ');
      }
    }

    return ApiResponse<T>(
      data: data,
      statusCode: statusCode,
      headers: headers,
      message: message,
      requestId: _requestIdFrom(headers),
      timestamp: DateTime.now().toUtc(),
      duration: duration,
    );
  }

  static const _sensitiveHeaders = {
    'authorization',
    'set-cookie',
    'cookie',
    'proxy-authorization',
    'www-authenticate',
  };

  /// Correlation-id headers differ per backend; the common spellings are all
  /// checked so tracing works without per-service configuration.
  static String? _requestIdFrom(Map<String, String> headers) {
    for (final key in const [
      'x-request-id',
      'x-correlation-id',
      'request-id',
      'x-trace-id',
    ]) {
      final value = headers[key];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
