import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_exception.dart';
import 'package:isi_steel_sales_mobile/core/api_client/network/network_checker.dart';

/// Rejects requests before they are sent when the device is plainly offline.
///
/// Without this, an offline call sits until the connect timeout expires —
/// 30 seconds of spinner for an answer that was knowable immediately. Failing
/// fast lets the UI fall back to local Drift data at once, which is what
/// offline-first requires (`docs/OFFLINE_FIRST.md`).
///
/// Ordered **first** in the chain: there is no point attaching a token, logging,
/// or arming a retry for a request that will not be dispatched.
class ConnectivityInterceptor extends Interceptor {
  const ConnectivityInterceptor(this._checker);

  final NetworkChecker _checker;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (await _checker.isConnected) return handler.next(options);

    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: NoInternetException(endpoint: options.path),
      ),
      // `true` marks this as a resolved rejection so Dio does not run the
      // remaining error interceptors — notably the retry interceptor, which
      // would otherwise back off and re-attempt a request that cannot succeed
      // until connectivity returns. Reconnect is an event, not something to
      // wait out in a retry loop.
      true,
    );
  }
}
