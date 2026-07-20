import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Debug-only request logging.
///
/// ## What is logged, and what is deliberately not
///
/// `docs/SECURITY.md` §10 permits endpoint, response code and error code. This
/// interceptor adds method, duration and payload **size** — all metadata, none
/// of it content.
///
/// It does **not** log bodies, query parameters, or header values:
///
/// * **Bodies** carry names, phone numbers, addresses, credit limits and, on the
///   login route, passwords.
/// * **Query parameters** are not safe either — `GetDetail?enName=...&customer=...`
///   puts a customer's name and number straight in the URL, which is why the
///   path is logged without its query string.
/// * **Header values** include `Authorization: Bearer <jwt>`. Header *names* are
///   logged so a missing or malformed header is still diagnosable, but every
///   value is withheld.
///
/// The whole interceptor is gated on [kDebugMode] as well as the `LOG_NETWORK`
/// flag, so it cannot ship enabled in a release build even if the flag is left
/// on by accident.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required this.backendName});

  /// Distinguishes backends once several are in flight at once.
  final String backendName;

  static const _startedAtKey = 'log_started_at';

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[$backendName] $message');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();

    if (kDebugMode) {
      _log('→ ${options.method} ${_safePath(options)}');
      final headerNames = options.headers.keys.toList()..sort();
      if (headerNames.isNotEmpty) {
        // Names only. Never values.
        _log('  headers: ${headerNames.join(', ')}');
      }
      final size = _payloadSize(options.data);
      if (size != null) _log('  payload: $size bytes');
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      _log(
        '← ${response.statusCode} '
        '${_safePath(response.requestOptions)}'
        '${_durationSuffix(response.requestOptions)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _log(
        '✗ ${err.type.name} ${err.response?.statusCode ?? ''} '
        '${_safePath(err.requestOptions)}'
        '${_durationSuffix(err.requestOptions)}',
      );
    }
    handler.next(err);
  }

  /// Path without the query string — the query carries customer names and
  /// numbers on the SAP filter endpoints.
  String _safePath(RequestOptions options) {
    final path = options.path;
    final queryStart = path.indexOf('?');
    final bare = queryStart == -1 ? path : path.substring(0, queryStart);
    final paramCount = options.queryParameters.length;
    return paramCount == 0 ? bare : '$bare (+$paramCount query params)';
  }

  String _durationSuffix(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    if (startedAt is! DateTime) return '';
    final ms = DateTime.now().difference(startedAt).inMilliseconds;
    return ' ${ms}ms';
  }

  /// Size only — never the content.
  int? _payloadSize(Object? data) {
    if (data == null) return null;
    if (data is String) return data.length;
    if (data is List<int>) return data.length;
    if (data is Map || data is List) return data.toString().length;
    return null;
  }
}
