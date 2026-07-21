import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/api_client/config/api_config.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/auth_interceptor.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/connectivity_interceptor.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/retry_interceptor.dart';

/// Builds Dio option objects from an [ApiConfig].
abstract final class DioOptionsBuilder {
  const DioOptionsBuilder._();

  /// Client-wide defaults.
  static BaseOptions base(ApiConfig config) => BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        headers: Map<String, String>.from(config.defaultHeaders),
        // Every status is "valid" so nothing is thrown before the response
        // reaches the error mapper. Dio's default (throw on non-2xx) would
        // surface a 404 as a `DioException` with the body already discarded —
        // and SAP puts the distinction between "no rows" and "unknown conId" in
        // exactly that body.
        validateStatus: (_) => true,
      );

  /// Per-request options.
  static Options request({
    String? contentType,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    bool skipAuth = false,
    bool skipConnectivityCheck = false,
    bool forceRetryable = false,
    Duration? receiveTimeout,
  }) =>
      Options(
        contentType: contentType,
        headers: headers,
        responseType: responseType,
        receiveTimeout: receiveTimeout,
        extra: {
          if (skipAuth) skipAuthFlag: true,
          if (skipConnectivityCheck) skipConnectivityFlag: true,
          // Opt a non-idempotent call into retry. Only correct where the
          // endpoint deduplicates — see `RetryInterceptor`.
          if (forceRetryable) RetryInterceptor.retryableFlag: true,
        },
      );

  /// Options for a file download: raw bytes, and a longer receive window since
  /// a large body legitimately takes longer than an API call.
  static Options download({Duration? receiveTimeout}) => Options(
        responseType: ResponseType.bytes,
        receiveTimeout: receiveTimeout ?? const Duration(minutes: 5),
      );
}
