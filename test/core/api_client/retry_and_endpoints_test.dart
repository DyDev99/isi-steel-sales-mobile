import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_exception.dart';
import 'package:isi_steel_sales_mobile/core/api_client/config/api_config.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/connectivity_interceptor.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_client.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_options.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/retry_interceptor.dart';
import 'package:isi_steel_sales_mobile/core/api_client/endpoints/sap_endpoints.dart';
import 'package:isi_steel_sales_mobile/core/api_client/network/network_checker.dart';

/// Counts attempts and always times out, so retry behaviour is observable.
class _TimeoutAdapter implements HttpClientAdapter {
  int attempts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    attempts++;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.receiveTimeout,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _OfflineChecker implements NetworkChecker {
  @override
  Future<bool> get isConnected async => false;
}

DioClient _retryingClient(_TimeoutAdapter adapter, {int maxRetries = 2}) {
  final config = ApiConfig.sap;
  final dio = Dio(DioOptionsBuilder.base(config))..httpClientAdapter = adapter;
  dio.interceptors.add(RetryInterceptor(
      dio: () => dio, maxRetries: maxRetries, baseDelay: Duration.zero));
  return DioClient(dio: dio, config: config);
}

void main() {
  group('retry policy — idempotency', () {
    test('GET is retried up to maxRetries', () async {
      final adapter = _TimeoutAdapter();
      final client = _retryingClient(adapter, maxRetries: 2);

      await expectLater(
        client.get<Object?>('/x'),
        throwsA(isA<ApiTimeoutException>()),
      );

      // 1 initial attempt + 2 retries.
      expect(adapter.attempts, 3);
    });

    test('POST is NOT retried', () async {
      // The load-bearing assertion of this file. A timeout means the *response*
      // was lost, not that the request never arrived — so replaying
      // `Customer/Create` can create the business partner twice, a real ERP
      // duplicate manufactured by the client's own recovery logic.
      final adapter = _TimeoutAdapter();
      final client = _retryingClient(adapter);

      await expectLater(
        client.post<Object?>(SapEndpoints.createCustomer('PRD')),
        throwsA(isA<ApiTimeoutException>()),
      );

      expect(adapter.attempts, 1,
          reason: 'no replay of a non-idempotent write');
    });

    test('PATCH is NOT retried', () async {
      final adapter = _TimeoutAdapter();
      final client = _retryingClient(adapter);

      await expectLater(
        client.patch<Object?>('/x'),
        throwsA(isA<ApiTimeoutException>()),
      );

      expect(adapter.attempts, 1);
    });

    test('PUT is retried — it is idempotent by HTTP contract', () async {
      // SAP models customer update as PUT with the key in the URL, so repeating
      // it converges on the same record rather than creating another.
      final adapter = _TimeoutAdapter();
      final client = _retryingClient(adapter, maxRetries: 1);

      await expectLater(
        client.put<Object?>(SapEndpoints.updateCustomer('PRD', '1')),
        throwsA(isA<ApiTimeoutException>()),
      );

      expect(adapter.attempts, 2);
    });

    test('DELETE is retried', () async {
      final adapter = _TimeoutAdapter();
      final client = _retryingClient(adapter, maxRetries: 1);

      await expectLater(
        client.delete<Object?>('/x'),
        throwsA(isA<ApiTimeoutException>()),
      );

      expect(adapter.attempts, 2);
    });
  });

  group('connectivity interceptor', () {
    test('an offline request fails fast without touching the socket', () async {
      final adapter = _TimeoutAdapter();
      final config = ApiConfig.sap;
      final dio = Dio(DioOptionsBuilder.base(config))
        ..httpClientAdapter = adapter
        ..interceptors.add(ConnectivityInterceptor(_OfflineChecker()));
      final client = DioClient(dio: dio, config: config);

      await expectLater(
        client.get<Object?>('/x'),
        throwsA(isA<NoInternetException>()),
      );

      expect(
        adapter.attempts,
        0,
        reason: 'offline must not burn the 30s connect timeout',
      );
    });
  });

  group('SapEndpoints', () {
    test('every data path embeds the conId', () {
      // Forgetting the conId is the easiest mistake against this API — every
      // Customer and CustHelper route requires it.
      const conId = 'PRD';
      final paths = [
        SapEndpoints.readCustomer(conId, '0001000123'),
        SapEndpoints.customerDetail(conId),
        SapEndpoints.customerPaging(conId),
        SapEndpoints.createCustomer(conId),
        SapEndpoints.updateCustomer(conId, '0001000123'),
        SapEndpoints.salesOrg(conId),
        SapEndpoints.paymentTerm(conId),
        SapEndpoints.salesEmployee(conId),
      ];

      for (final path in paths) {
        expect(path, contains('/$conId'), reason: path);
      }
    });

    test('paths match the documented controller/action shape', () {
      expect(SapEndpoints.login, '/api/Auth/Login');
      expect(
        SapEndpoints.readCustomer('PRD', '0001000123'),
        '/api/Customer/Read/PRD/0001000123',
      );
      expect(
        SapEndpoints.customerPaging('PRD'),
        '/api/Customer/GetPaging/PRD',
      );
      expect(SapEndpoints.salesOrg('PRD'), '/api/CustHelper/GetSalesOrg/PRD');
    });
  });

  group('ApiConfig', () {
    test('a raw-IP host is flagged as requiring a certificate pin', () {
      // The SAP host serves HTTPS from an IP with a self-signed certificate, so
      // ordinary CA validation can never succeed there.
      expect(ApiConfig.sap.requiresCertificatePin, isTrue);
    });

    test('SAP and ISI are configured independently', () {
      expect(ApiConfig.sap.name, isNot(ApiConfig.isi.name));
    });
  });
}
