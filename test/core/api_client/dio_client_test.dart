import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_exception.dart';
import 'package:isi_steel_sales_mobile/core/api_client/config/api_config.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_client.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/dio_options.dart';

/// Serves canned responses so status→exception mapping can be exercised without
/// a network. Real `Dio` machinery runs; only the socket is replaced.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.statusCode, this.body, this.headers});

  final int statusCode;
  final Object? body;
  final Map<String, List<String>>? headers;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final encoded = utf8.encode(jsonEncode(body ?? {}));
    return ResponseBody.fromBytes(
      encoded,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...?headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioClient _clientReturning({
  required int statusCode,
  Object? body,
  Map<String, List<String>>? headers,
}) {
  final config = ApiConfig.sap;
  final dio = Dio(DioOptionsBuilder.base(config))
    ..httpClientAdapter =
        _StubAdapter(statusCode: statusCode, body: body, headers: headers);
  return DioClient(dio: dio, config: config);
}

void main() {
  group('status code mapping', () {
    test('200 returns the decoded body', () async {
      final client = _clientReturning(
        statusCode: 200,
        body: {'customer': '0001000123'},
      );

      final response = await client.get<Object?>('/api/Customer/Read/PRD/1');

      expect(response.statusCode, 200);
      expect((response.data! as Map)['customer'], '0001000123');
      expect(response.isSuccess, isTrue);
    });

    test('401 -> UnauthorizedException', () {
      final client = _clientReturning(statusCode: 401);
      expect(
        () => client.get<Object?>('/x'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('403 -> ForbiddenException', () {
      final client = _clientReturning(statusCode: 403);
      expect(
        () => client.get<Object?>('/x'),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('500 -> ServerException', () {
      final client = _clientReturning(statusCode: 500);
      expect(
        () => client.get<Object?>('/x'),
        throwsA(isA<ServerException>()),
      );
    });

    test('400 -> ValidationException', () {
      final client = _clientReturning(
        statusCode: 400,
        body: {'message': 'ConId cannot be empty.'},
      );
      expect(
        () => client.get<Object?>('/x'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('no DioException ever escapes the client', () async {
      final client = _clientReturning(statusCode: 503);
      try {
        await client.get<Object?>('/x');
        fail('expected a throw');
      } on Object catch (e) {
        expect(e, isA<ApiException>());
        expect(e, isNot(isA<DioException>()));
      }
    });
  });

  group("SAP's overloaded 404", () {
    test('a conId fault is surfaced, not swallowed as empty', () {
      // Collapsing this into "no rows" would hide a broken deployment behind an
      // empty customer list indefinitely.
      final client = _clientReturning(
        statusCode: 404,
        body: {'message': "ConId 'XYZ' not found."},
      );
      expect(
        () => client.get<Object?>('/x', allowEmpty: true),
        throwsA(isA<SapConnectionException>()),
      );
    });

    test('zero matching rows with allowEmpty resolves to null data', () async {
      final client = _clientReturning(
        statusCode: 404,
        body: {'message': 'No sales organization found.'},
      );

      final response = await client.get<Object?>('/x', allowEmpty: true);

      expect(response.data, isNull);
      expect(response.statusCode, 404);
    });

    test('without allowEmpty a 404 is NotFoundException', () {
      final client = _clientReturning(
        statusCode: 404,
        body: {'message': 'No rows.'},
      );
      expect(
        () => client.get<Object?>('/x'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('SAP failure inside a 200', () {
    test('success:false with an E message throws SapException', () async {
      // §5.4: Create/Update report rejection in the body, not the status line.
      // A status-code-only mapping would read this as success.
      final client = _clientReturning(
        statusCode: 200,
        body: {
          'success': false,
          'messages': [
            {
              'type': 'E',
              'id': 'F2',
              'number': '003',
              'message': 'Field is required',
            },
          ],
        },
      );

      try {
        await client.post<Object?>('/api/Customer/Create/PRD');
        fail('expected SapException');
      } on SapException catch (e) {
        expect(e.message, 'Field is required');
        expect(e.messages.single.code, 'F2/003');
      }
    });

    test('informational messages do not fail the request', () async {
      final client = _clientReturning(
        statusCode: 200,
        body: {
          'customer': '1',
          'messages': [
            {'type': 'S', 'message': 'Created'},
            {'type': 'W', 'message': 'Check the credit limit'},
          ],
        },
      );

      final response = await client.post<Object?>('/x');
      expect(response.statusCode, 200);
    });
  });

  group('response envelope', () {
    test('credential-bearing headers are dropped at the boundary', () async {
      final client = _clientReturning(
        statusCode: 200,
        body: {'ok': true},
        headers: {
          'authorization': ['Bearer super-secret'],
          'set-cookie': ['session=abc'],
          'x-request-id': ['req-42'],
        },
      );

      final response = await client.get<Object?>('/x');

      expect(response.headers.containsKey('authorization'), isFalse);
      expect(response.headers.containsKey('set-cookie'), isFalse);
      expect(response.requestId, 'req-42');
    });

    test('duration is recorded and timestamp is UTC', () async {
      final client = _clientReturning(statusCode: 200, body: {'ok': true});

      final response = await client.get<Object?>('/x');

      expect(response.duration, isNotNull);
      expect(response.timestamp.isUtc, isTrue);
    });
  });

  group('decoder', () {
    test('maps the payload into a typed value', () async {
      final client = _clientReturning(
        statusCode: 200,
        body: {'rows': <dynamic>[], 'totalCount': 7},
      );

      final response = await client.get<int>(
        '/x',
        decoder: (body) => (body! as Map)['totalCount'] as int,
      );

      expect(response.data, 7);
    });
  });
}
