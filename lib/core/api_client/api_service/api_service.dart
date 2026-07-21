import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_exception.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_response.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_client.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_options.dart';

/// The networking contract every remote datasource depends on.
///
/// ```
/// CustomerSapRemoteDatasource → ApiService → DioClient → Interceptors → Dio
/// ```
///
/// A datasource depends on this interface and nothing else from the networking
/// layer. It does not import `dio`, does not see `Response`, does not catch
/// `DioException`, and does not know whether a token was attached — which is why
/// a datasource can be unit-tested against a fake `ApiService` with no HTTP
/// stack at all.
///
/// Every method throws [ApiException] on failure and returns [ApiResponse] on
/// success.
abstract interface class ApiService {
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Object? body)? decoder,
    bool allowEmpty,
  });

  /// [headers] are merged over the client's `defaultHeaders` for this one
  /// request. Use it only where an endpoint genuinely differs from the backend
  /// default — it is not a general escape hatch, and anything that belongs on
  /// every request belongs in `ApiConfig.defaultHeaders` instead.
  ///
  /// Never pass an `Authorization` header here: bearer tokens are the
  /// `AuthInterceptor`'s job, and setting one by hand bypasses the token
  /// lifecycle (`docs/SECURITY.md` §5).
  /// [skipConnectivityCheck] sends the request even when the cached
  /// connectivity verdict says offline. Correct for login and nothing else so
  /// far — see `skipConnectivityFlag`.
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? body)? decoder,
    bool skipAuth,
    bool skipConnectivityCheck,
    Map<String, dynamic>? headers,
  });

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? body)? decoder,
  });

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? body)? decoder,
  });

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? body)? decoder,
  });

  Future<ApiResponse<List<int>>> download(
    String path, {
    Map<String, dynamic>? queryParameters,
    void Function(int received, int total)? onProgress,
  });
}

/// [ApiService] backed by a [DioClient].
///
/// One instance per backend: `sl<ApiService>(instanceName: 'sap')` and
/// `'isi'`. They differ only in the client they wrap, so a datasource written
/// against one works against the other unchanged.
class DioApiService implements ApiService {
  const DioApiService(this._client);

  final DioClient _client;

  /// Backend name, for diagnostics.
  String get backend => _client.config.name;

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Object? body)? decoder,
    bool allowEmpty = false,
  }) =>
      _client.get<T>(
        path,
        queryParameters: queryParameters,
        decoder: decoder,
        allowEmpty: allowEmpty,
      );

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? body)? decoder,
    bool skipAuth = false,
    bool skipConnectivityCheck = false,
    Map<String, dynamic>? headers,
  }) =>
      _client.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        decoder: decoder,
        // Left null when none is set so the request keeps Dio's BaseOptions
        // untouched — passing an empty Options would drop nothing today, but it
        // makes the "no per-request override" case explicit.
        options: (skipAuth || skipConnectivityCheck || headers != null)
            ? DioOptionsBuilder.request(
                skipAuth: skipAuth,
                skipConnectivityCheck: skipConnectivityCheck,
                headers: headers,
              )
            : null,
      );

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? body)? decoder,
  }) =>
      _client.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        decoder: decoder,
      );

  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? body)? decoder,
  }) =>
      _client.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        decoder: decoder,
      );

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? body)? decoder,
  }) =>
      _client.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        decoder: decoder,
      );

  @override
  Future<ApiResponse<List<int>>> download(
    String path, {
    Map<String, dynamic>? queryParameters,
    void Function(int received, int total)? onProgress,
  }) =>
      _client.download(
        path,
        queryParameters: queryParameters,
        onProgress: onProgress,
      );
}
