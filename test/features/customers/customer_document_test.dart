import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_document_mapper.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_document_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/customer_document_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_document.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_document_repository.dart';

/// Customer evidence photographs — the last step of registration.
///
/// The rules that matter, all from
/// `docs/feature/customer/mobile/customer-documents.md`:
///
///  * `Type` goes on the wire as a **code**, never a label.
///  * `Content-Type` is stated and must agree with the extension — that is what
///    catches a PDF renamed to `.jpg` to reach a photo slot.
///  * `CapturedAt` is photo time, not upload time.
///  * `publicUrl` is null for the three private slots, by design.
///  * A failed upload **must not lose the customer**, and a 4xx must not be
///    retried.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? stream,
      Future<void>? cancelFuture) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, int status) =>
    ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });

/// The upload response, verbatim from the guide.
Map<String, dynamic> _uploadBody() => {
      'success': true,
      'message': 'Photo uploaded successfully.',
      'data': <String, dynamic>{
        'id': '01a0479c-d20c-7275-b8ac-8883b582e9e7',
        'type': 'STOREFRONT',
        'typeDisplay': 'Storefront photo',
        'fileName': 'storefront.jpg',
        'contentType': 'image/jpeg',
        'sizeBytes': 297431,
        'url':
            '/api/v1/mobile/customers/6100000017/documents/01a0479c-/content',
        'publicUrl': '/files/customers/hAS_juvp1vHZ3V87WYfwnw',
        'isPubliclyVisible': true,
        'capturedAt': '2026-08-31T08:00:00Z',
        'uploadedAt': '2026-08-31T09:12:44Z',
      },
    };

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isi_documents_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  File makeFile(String name, {int bytes = 64}) {
    final file = File('${tempDir.path}/$name')
      ..writeAsBytesSync(List.filled(bytes, 0x41));
    return file;
  }

  ({_ScriptedAdapter adapter, ApiCustomerDocumentRemoteDataSource remote})
      script(Future<ResponseBody> Function(RequestOptions o) handler) {
    final adapter = _ScriptedAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    return (adapter: adapter, remote: ApiCustomerDocumentRemoteDataSource(dio));
  }

  group('the five slots', () {
    test('the three photos are always required; VAT depends on tax class', () {
      expect(CustomerDocumentType.storefront.isAlwaysRequired, isTrue);
      expect(CustomerDocumentType.insideStore.isAlwaysRequired, isTrue);
      expect(CustomerDocumentType.idCard.isAlwaysRequired, isTrue);
      expect(CustomerDocumentType.patentTax.isAlwaysRequired, isFalse);

      expect(
        CustomerDocumentType.vatCertificate
            .isRequiredFor(isVatRegistered: true),
        isTrue,
      );
      expect(
        CustomerDocumentType.vatCertificate
            .isRequiredFor(isVatRegistered: false),
        isFalse,
      );
    });

    test('PDF reaches only the two document slots', () {
      expect(CustomerDocumentType.patentTax.acceptsPdf, isTrue);
      expect(CustomerDocumentType.vatCertificate.acceptsPdf, isTrue);
      expect(CustomerDocumentType.storefront.acceptsPdf, isFalse);
      expect(CustomerDocumentType.idCard.acceptsPdf, isFalse);
    });

    test('only the two storefront photos are ever public', () {
      // The rest carry personal and financial data; a URL needing no
      // credentials is a breach waiting for the link to leak.
      expect(CustomerDocumentType.storefront.isPubliclyVisible, isTrue);
      expect(CustomerDocumentType.insideStore.isPubliclyVisible, isTrue);
      expect(CustomerDocumentType.idCard.isPubliclyVisible, isFalse);
      expect(CustomerDocumentType.patentTax.isPubliclyVisible, isFalse);
      expect(CustomerDocumentType.vatCertificate.isPubliclyVisible, isFalse);
    });

    test('codes parse, including the legacy enumeration names', () {
      expect(CustomerDocumentType.fromCode('STOREFRONT'),
          CustomerDocumentType.storefront);
      expect(CustomerDocumentType.fromCode('INSIDE_STORE'),
          CustomerDocumentType.insideStore);
      // Still accepted on input for clients built before the codes existed.
      expect(CustomerDocumentType.fromCode('IdCardPhoto'),
          CustomerDocumentType.idCard);
    });

    test('an unfamiliar slot returns null rather than throwing', () {
      // A server that gains a sixth slot must not crash an app that has not
      // shipped yet.
      expect(CustomerDocumentType.fromCode('HOLOGRAM'), isNull);
      expect(CustomerDocumentType.fromCode(null), isNull);
      expect(CustomerDocumentType.fromCode(''), isNull);
    });
  });

  group('the checklist response', () {
    test('drives completeness from the server, not a local tally', () {
      final state = CustomerDocumentMapper.stateFromJson({
        'documents': [
          {'id': 'a', 'type': 'STOREFRONT', 'fileName': 'storefront.jpg'},
          {'id': 'b', 'type': 'INSIDE_STORE', 'fileName': 'inside.jpg'},
        ],
        'missingRequired': ['ID_CARD'],
        'isComplete': false,
      });

      expect(state.byType.keys, hasLength(2));
      expect(state.missingRequired, {CustomerDocumentType.idCard});
      expect(state.isComplete, isFalse);
      expect(
          state[CustomerDocumentType.storefront]?.fileName, 'storefront.jpg');
    });

    test('an unknown slot in the list is skipped, not fatal', () {
      final state = CustomerDocumentMapper.stateFromJson({
        'documents': [
          {'id': 'a', 'type': 'HOLOGRAM', 'fileName': 'x.jpg'},
          {'id': 'b', 'type': 'ID_CARD', 'fileName': 'id.jpg'},
        ],
        'missingRequired': <dynamic>[],
        'isComplete': true,
      });

      expect(state.byType.keys, [CustomerDocumentType.idCard]);
      expect(state.isComplete, isTrue);
    });

    test('a missing documents array is an empty state, not a crash', () {
      final state = CustomerDocumentMapper.stateFromJson({});
      expect(state.byType, isEmpty);
      expect(state.isComplete, isFalse);
    });
  });

  group('upload', () {
    test('sends the code, the captured time and an explicit content type',
        () async {
      final s = script((o) async => _json(_uploadBody(), 200));
      final captured = DateTime.utc(2026, 8, 31, 8);

      await s.remote.upload(
        customerId: '6100000017',
        type: CustomerDocumentType.storefront,
        file: makeFile('storefront.jpg'),
        capturedAt: captured,
      );

      final request = s.adapter.requests.single;
      expect(request.path, '/api/v1/mobile/customers/6100000017/documents');

      final form = request.data as FormData;
      final fields = {for (final f in form.fields) f.key: f.value};
      // A code, never a label.
      expect(fields['Type'], 'STOREFRONT');
      // Photo time, not upload time.
      expect(fields['CapturedAt'], '2026-08-31T08:00:00.000Z');

      final upload = form.files.single.value;
      expect(upload.contentType?.mimeType, 'image/jpeg');
    });

    test('a PNG is labelled as a PNG, not guessed as JPEG', () async {
      // The server rejects a Content-Type that disagrees with the extension.
      final s = script((o) async => _json(_uploadBody(), 200));

      await s.remote.upload(
        customerId: 'c1',
        type: CustomerDocumentType.idCard,
        file: makeFile('id.png'),
      );

      final form = s.adapter.requests.single.data as FormData;
      expect(form.files.single.value.contentType?.mimeType, 'image/png');
    });

    test('a PDF is accepted by the patent/tax slot', () async {
      final s = script((o) async => _json(_uploadBody(), 200));

      await s.remote.upload(
        customerId: 'c1',
        type: CustomerDocumentType.patentTax,
        file: makeFile('patent.pdf'),
      );

      final form = s.adapter.requests.single.data as FormData;
      expect(form.files.single.value.contentType?.mimeType, 'application/pdf');
    });

    test('a PDF to a photo slot fails before the upload is spent', () async {
      // The server answers Customer.DocumentExtensionNotAllowed, but a rep on
      // a market connection should not pay for the round trip to learn that.
      final s = script((o) async => _json(_uploadBody(), 200));

      await expectLater(
        s.remote.upload(
          customerId: 'c1',
          type: CustomerDocumentType.storefront,
          file: makeFile('scan.pdf'),
        ),
        throwsA(isA<Exception>()),
      );
      expect(s.adapter.requests, isEmpty);
    });

    test('the response is parsed, including the public URL', () async {
      final s = script((o) async => _json(_uploadBody(), 200));

      final document = await s.remote.upload(
        customerId: 'c1',
        type: CustomerDocumentType.storefront,
        file: makeFile('storefront.jpg'),
      );

      expect(document.type, CustomerDocumentType.storefront);
      expect(document.typeDisplay, 'Storefront photo');
      expect(document.publicUrl, '/files/customers/hAS_juvp1vHZ3V87WYfwnw');
      expect(document.isPubliclyVisible, isTrue);
      expect(document.capturedAt, DateTime.utc(2026, 8, 31, 8));
    });

    test('a private slot comes back with no public URL', () async {
      final body = _uploadBody();
      final data = body['data']! as Map<String, dynamic>;
      data['type'] = 'ID_CARD';
      data['publicUrl'] = null;
      data['isPubliclyVisible'] = false;
      final s = script((o) async => _json(body, 200));

      final document = await s.remote.upload(
        customerId: 'c1',
        type: CustomerDocumentType.idCard,
        file: makeFile('id.jpg'),
      );

      expect(document.publicUrl, isNull);
      expect(document.isPubliclyVisible, isFalse);
    });
  });

  group('a failed upload never loses the customer', () {
    CustomerDocumentRepositoryImpl repositoryFor(
            Future<ResponseBody> Function(RequestOptions o) handler) =>
        CustomerDocumentRepositoryImpl(
          remote: script(handler).remote,
          logger: const ConsoleAppLogger(verbose: false),
        );

    PendingCustomerDocument pending(CustomerDocumentType type, File file) =>
        PendingCustomerDocument(
          type: type,
          filePath: file.path,
          capturedAt: DateTime.utc(2026, 8, 31, 8),
        );

    test('a 4xx is a rejection — it will fail identically forever', () async {
      final repository = repositoryFor((o) async => _json({
            'status': 400,
            'errorCode': 'Customer.DocumentTooLarge',
          }, 400));

      final result = await repository.uploadAll(
        customerId: 'c1',
        documents: [
          pending(CustomerDocumentType.storefront, makeFile('a.jpg'))
        ],
      );

      final outcome = result.when(success: (o) => o, failure: (_) => null);
      expect(outcome, isNotNull, reason: 'uploadAll must never report failure');
      expect(outcome!.rejected, [CustomerDocumentType.storefront]);
      expect(outcome.failed, isEmpty,
          reason: 'a 4xx must not be queued for retry');
    });

    test('a 5xx is a transient failure, worth retrying', () async {
      final repository =
          repositoryFor((o) async => _json({'status': 500}, 500));

      final result = await repository.uploadAll(
        customerId: 'c1',
        documents: [pending(CustomerDocumentType.idCard, makeFile('id.jpg'))],
      );

      final outcome = result.when(success: (o) => o, failure: (_) => null)!;
      expect(outcome.failed, [CustomerDocumentType.idCard]);
      expect(outcome.rejected, isEmpty);
    });

    test('one bad slot does not stop the others', () async {
      var call = 0;
      final repository = repositoryFor((o) async {
        call++;
        // The second upload fails; the first and third must still land.
        return call == 2
            ? _json({'status': 400}, 400)
            : _json(_uploadBody(), 200);
      });

      final result = await repository.uploadAll(
        customerId: 'c1',
        documents: [
          pending(CustomerDocumentType.storefront, makeFile('a.jpg')),
          pending(CustomerDocumentType.insideStore, makeFile('b.jpg')),
          pending(CustomerDocumentType.idCard, makeFile('c.jpg')),
        ],
      );

      final outcome = result.when(success: (o) => o, failure: (_) => null)!;
      expect(outcome.uploaded, [
        CustomerDocumentType.storefront,
        CustomerDocumentType.idCard,
      ]);
      expect(outcome.rejected, [CustomerDocumentType.insideStore]);
      expect(outcome.isCompleteSuccess, isFalse);
    });

    test('a file that vanished before upload is a rejection', () async {
      // A share sheet, a cache sweep, an OS cleanup. Nothing to retry.
      final repository = repositoryFor((o) async => _json(_uploadBody(), 200));
      final gone = File('${tempDir.path}/never-written.jpg');

      final result = await repository.uploadAll(
        customerId: 'c1',
        documents: [
          PendingCustomerDocument(
            type: CustomerDocumentType.storefront,
            filePath: gone.path,
            capturedAt: DateTime.utc(2026, 8, 31),
          ),
        ],
      );

      final outcome = result.when(success: (o) => o, failure: (_) => null)!;
      expect(outcome.rejected, [CustomerDocumentType.storefront]);
    });

    test('everything landing is a clean success', () async {
      final repository = repositoryFor((o) async => _json(_uploadBody(), 200));

      final result = await repository.uploadAll(
        customerId: 'c1',
        documents: [
          pending(CustomerDocumentType.storefront, makeFile('a.jpg'))
        ],
      );

      final outcome = result.when(success: (o) => o, failure: (_) => null)!;
      expect(outcome.isCompleteSuccess, isTrue);
      expect(outcome.outstanding, isEmpty);
    });
  });
}
