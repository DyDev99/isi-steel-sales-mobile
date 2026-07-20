import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/api_client/auth/token_manager.dart';
import 'package:isi_steel_sales_mobile/core/api_client/config/api_config.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/auth_interceptor.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/connectivity_interceptor.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/logging_interceptor.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/retry_interceptor.dart';
import 'package:isi_steel_sales_mobile/core/api_client/network/network_checker.dart';
import 'package:isi_steel_sales_mobile/core/config/app_config.dart';

/// Assembles the interceptor chain.
///
/// **Order is behaviour, not style.** Dio runs `onRequest` in registration order
/// and `onError` in the same order, so the sequence below is chosen
/// deliberately:
///
/// 1. **Connectivity** — first, so an offline request is rejected before any
///    other interceptor spends work on it, and before retry can back off
///    waiting for a network that is simply absent.
/// 2. **Auth** — before logging, so the log reflects the request as actually
///    sent (header names include `Authorization`).
/// 3. **Logging** — after auth, before retry, so each individual attempt is
///    logged rather than only the final outcome.
/// 4. **Retry** — last, so its replay passes back through nothing else; the
///    replayed request already carries its token and has been logged.
abstract final class DioInterceptors {
  const DioInterceptors._();

  static List<Interceptor> build({
    required ApiConfig config,
    required NetworkChecker networkChecker,
    required Dio Function() dio,
    TokenManager Function()? tokenManager,
  }) {
    return [
      ConnectivityInterceptor(networkChecker),

      if (config.requiresAuth && tokenManager != null)
        AuthInterceptor(tokenManager: tokenManager, retryDio: dio),

      // Gated twice: the runtime flag, and `kDebugMode` inside the interceptor
      // itself. A release build cannot log even if the flag is left enabled.
      if (AppConfig.logNetwork) LoggingInterceptor(backendName: config.name),

      RetryInterceptor(dio: dio, maxRetries: config.maxRetries),
    ];
  }

  /// Chain for the login client: no auth interceptor (it would recurse into the
  /// token manager that is trying to log in) and no retry (a rejected
  /// credential does not become valid on a second attempt; a timeout during
  /// login is better surfaced immediately than silently retried).
  static List<Interceptor> forLogin({
    required ApiConfig config,
    required NetworkChecker networkChecker,
  }) {
    return [
      ConnectivityInterceptor(networkChecker),
      if (AppConfig.logNetwork) LoggingInterceptor(backendName: config.name),
    ];
  }
}
