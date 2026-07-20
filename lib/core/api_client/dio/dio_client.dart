import 'dart:io';

import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_exception.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_response.dart';
import 'package:isi_steel_sales_mobile/core/api_client/config/api_config.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_options.dart';

/// Wraps one configured [Dio] and presents HTTP verbs that return
/// [ApiResponse] and throw [ApiException].
///
/// This is the boundary: `dio` types go in, neither comes out. Nothing above
/// `core/api_client` imports `dio`, which is what lets a backend be re-hosted,
/// or the HTTP package swapped, without touching a single feature.
class DioClient {
  DioClient({required Dio dio, required ApiConfig config})
      : _dio = dio,
        _config = config;

  final Dio _dio;
  final ApiConfig _config;

  ApiConfig get config => _config;

  /// Escape hatch for the token manager, which needs a raw Dio for its
  /// interceptor-free login call. Deliberately not exported to features.
  Dio get rawDio => _dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Object? body)? decoder,
    bool allowEmpty = false,
  }) =>
      _send<T>(
        path,
        decoder: decoder,
        allowEmpty: allowEmpty,
        call: (cancelToken) => _dio.get<dynamic>(
          path,
          queryParameters: queryParameters,
          options: options,
        ),
      );

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Object? body)? decoder,
  }) =>
      _send<T>(
        path,
        decoder: decoder,
        call: (_) => _dio.post<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ),
      );

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Object? body)? decoder,
  }) =>
      _send<T>(
        path,
        decoder: decoder,
        call: (_) => _dio.put<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ),
      );

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Object? body)? decoder,
  }) =>
      _send<T>(
        path,
        decoder: decoder,
        call: (_) => _dio.patch<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ),
      );

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(Object? body)? decoder,
  }) =>
      _send<T>(
        path,
        decoder: decoder,
        call: (_) => _dio.delete<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ),
      );

  /// Multipart upload.
  ///
  /// Not retried: a re-sent upload can produce a duplicate attachment on the
  /// server, and re-streaming a large file over a link that just failed is
  /// expensive. The caller decides whether to try again.
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    void Function(int sent, int total)? onProgress,
    T Function(Object? body)? decoder,
  }) =>
      _send<T>(
        path,
        decoder: decoder,
        call: (_) => _dio.post<dynamic>(
          path,
          data: formData,
          queryParameters: queryParameters,
          onSendProgress: onProgress,
        ),
      );

  /// Downloads to raw bytes.
  ///
  /// Returns bytes rather than writing to a path: attachments belong in the
  /// encrypted file store, not on the open filesystem
  /// (`docs/ARCHITECTURE.md` §3, Layer 4), so the caller decides where they land
  /// and how they are protected.
  Future<ApiResponse<List<int>>> download(
    String path, {
    Map<String, dynamic>? queryParameters,
    void Function(int received, int total)? onProgress,
    Duration? receiveTimeout,
  }) =>
      _send<List<int>>(
        path,
        decoder: (body) => body is List<int> ? body : const <int>[],
        call: (_) => _dio.get<dynamic>(
          path,
          queryParameters: queryParameters,
          options: DioOptionsBuilder.download(receiveTimeout: receiveTimeout),
          onReceiveProgress: onProgress,
        ),
      );

  // ── Internals ────────────────────────────────────────────────────────

  Future<ApiResponse<T>> _send<T>(
    String path, {
    required Future<Response<dynamic>> Function(CancelToken? token) call,
    T Function(Object? body)? decoder,
    bool allowEmpty = false,
  }) async {
    final startedAt = DateTime.now();
    try {
      final response = await call(null);
      return _handle<T>(
        response,
        path,
        decoder: decoder,
        allowEmpty: allowEmpty,
        duration: DateTime.now().difference(startedAt),
      );
    } on DioException catch (e) {
      throw _mapDioException(e, path);
    }
  }

  ApiResponse<T> _handle<T>(
    Response<dynamic> response,
    String path, {
    T Function(Object? body)? decoder,
    required bool allowEmpty,
    required Duration duration,
  }) {
    final status = response.statusCode ?? 0;
    final body = response.data;

    if (status == 404 && allowEmpty) {
      // SAP overloads 404: "no rows matched" (routine) and "unknown conId"
      // (misconfiguration). Only the first is an acceptable empty result;
      // collapsing both would hide a broken deployment behind an empty list.
      final message = _messageOf(body);
      if (_looksLikeConnectionIdFault(message)) {
        throw SapConnectionException(message: message!, endpoint: path);
      }
      return ApiResponse.fromParts<T>(
        data: _decode<T>(null, decoder),
        statusCode: status,
        rawHeaders: response.headers.map,
        duration: duration,
      );
    }

    if (status < 200 || status >= 300) {
      throw _mapStatus(status, body, path);
    }

    // A 200 can still be a failure: SAP answers Create/Update with
    // `success: false` and a populated `messages` array (technical document
    // §5.4). A status-code-only mapping would read that as success.
    final diagnostics = parseSapDiagnostics(body);
    if (diagnostics.any((d) => d.isError)) {
      throw SapException(
        message: diagnostics.firstWhere((d) => d.isError).message,
        messages: diagnostics,
        statusCode: status,
        endpoint: path,
      );
    }

    return ApiResponse.fromParts<T>(
      data: _decode<T>(body, decoder),
      statusCode: status,
      rawHeaders: response.headers.map,
      message: _messageOf(body),
      duration: duration,
    );
  }

  T _decode<T>(Object? body, T Function(Object? body)? decoder) {
    if (decoder != null) return decoder(body);
    if (body is T) return body;
    // A decoder is required whenever T is not what the transport produced.
    // Failing loudly here beats an obscure cast error deep inside a datasource.
    throw ServerException(
      message: 'Response could not be read as $T. Supply a decoder.',
    );
  }

  ApiException _mapStatus(int status, Object? body, String path) {
    final message = _messageOf(body);
    final diagnostics = parseSapDiagnostics(body);

    return switch (status) {
      400 => ValidationException(
          message: message ?? 'The request was rejected as invalid.',
          statusCode: 400,
          endpoint: path,
        ),
      401 => UnauthorizedException(endpoint: path),
      403 => ForbiddenException(endpoint: path),
      404 when _looksLikeConnectionIdFault(message) =>
        SapConnectionException(message: message!, endpoint: path),
      404 => NotFoundException(
          message: message ?? 'Not found.',
          endpoint: path,
        ),
      422 => diagnostics.isEmpty
          ? ValidationException(
              message: message ?? 'The server rejected the record.',
              statusCode: 422,
              endpoint: path,
            )
          : SapException(
              message: message ?? diagnostics.first.message,
              messages: diagnostics,
              statusCode: 422,
              endpoint: path,
            ),
      >= 500 => ServerException(
          message: message ?? 'The server encountered an error.',
          statusCode: status,
          endpoint: path,
        ),
      _ => ServerException(
          message: 'Unexpected response ($status).',
          statusCode: status,
          endpoint: path,
        ),
    };
  }

  ApiException _mapDioException(DioException e, String path) {
    // An interceptor may already have produced a typed error — the connectivity
    // and auth interceptors both do. Pass it through rather than re-deriving a
    // vaguer one from the Dio type.
    final inner = e.error;
    if (inner is ApiException) return inner;

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        ApiTimeoutException(endpoint: path),
      DioExceptionType.badCertificate => SslException(
          message: 'The server certificate is not trusted and does not match '
              'the configured pin.',
          endpoint: path,
        ),
      DioExceptionType.connectionError => inner is HandshakeException
          // A pin mismatch surfaces as a handshake failure on some platforms
          // rather than as `badCertificate`. Without this check it is
          // indistinguishable from the server being down, and an operator would
          // chase the wrong fault.
          ? SslException(
              message: 'TLS handshake failed — the certificate does not match '
                  'the configured pin.',
              endpoint: path,
            )
          : NetworkException(endpoint: path),
      DioExceptionType.badResponse => _mapStatus(
          e.response?.statusCode ?? 0,
          e.response?.data,
          path,
        ),
      DioExceptionType.cancel =>
        NetworkException(message: 'Request cancelled.', endpoint: path),
      _ => NetworkException(endpoint: path),
    };
  }

  static String? _messageOf(Object? body) {
    if (body is! Map) return null;
    final message = body['message'];
    return message is String && message.isNotEmpty ? message : null;
  }

  /// §4.4/§6.4 phrase the conId fault around "ConId"/"connection id",
  /// distinguishing it from "No sales organization found." style empty results.
  static bool _looksLikeConnectionIdFault(String? message) {
    if (message == null) return false;
    final lower = message.toLowerCase();
    return lower.contains('conid') || lower.contains('connection id');
  }
}

/// Parses SAP's `messages` array (technical document §6.2).
///
/// Top-level so both [DioClient] and any SAP-specific datasource can read it
/// without duplicating the shape.
List<SapDiagnostic> parseSapDiagnostics(Object? body) {
  if (body is! Map) return const [];
  final raw = body['messages'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((m) => SapDiagnostic(
            type: m['type'] as String? ?? 'E',
            message: m['message'] as String? ?? '',
            id: m['id'] as String?,
            number: m['number'] as String?,
          ))
      .toList(growable: false);
}
