import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/config/env.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/middleware/app_middleware.dart';

/// Factory for the app's Dio clients. Keeping construction here means the
/// timeout / header policy lives in exactly one place.
class AppNetwork {
  AppNetwork._();

  static BaseOptions get _baseOptions => BaseOptions(
        // Environment-driven, never a literal: the target gateway comes from
        // the `.env` compiled in at build time, so a QA/staging build is a
        // different `.env` rather than a different source tree.
        baseUrl: Env.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        responseType: ResponseType.json,
        headers: const {'Accept': 'application/json'},
      );

  /// Bare client with no auth interceptor. Used for the refresh flow and
  /// public endpoints (e.g. login).
  static Dio createBareClient() => Dio(_baseOptions);

  /// Authenticated client used by feature data sources. Auto-attaches and
  /// refreshes the bearer token.
  static Dio createAuthedClient({required TokenStore tokenStore}) {
    return Dio(_baseOptions)
      ..interceptors.add(
        AuthInterceptor(
          tokenStore: tokenStore,
          refreshClient: createBareClient(),
        ),
      );
  }
}
