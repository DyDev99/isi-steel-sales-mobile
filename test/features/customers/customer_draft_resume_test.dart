import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_datasources.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/business_partner_repository_impl.dart';

/// Opening the "add customer" form must resume the rep's unfinished
/// registration rather than starting a new one.
///
/// Why this matters: the form is five steps long and is filled in standing at a
/// shop counter. A rep who backs out, loses signal or has the handset killed
/// must find their typing where they left it. Creating a fresh draft each time
/// throws that away *and* leaves an orphaned draft behind on the server.
///
/// The tests drive the real Dio stack so the endpoint path, the envelope and
/// the status handling are all covered — a fake data source would have proved
/// only that the `if` works.
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

/// The active-draft payload exactly as the endpoint returns it.
Map<String, dynamic> _activeDraftBody({
  required String status,
  bool isEditable = true,
  Map<String, dynamic>? fields,
}) =>
    {
      'success': true,
      'message': 'Registration form retrieved successfully.',
      'data': {
        'draftId': '01a0412a-0b1c-7e79-8749-12f762b15627',
        'status': status,
        'isEditable': isEditable,
        'submittedCustomerId': null,
        'submittedAt': null,
        'createdAt': '2026-08-27T03:01:09.557983+00:00',
        'updatedAt': null,
        'fields': fields ??
            {
              'name1': null,
              'partnerCategory': '2',
              'country': 'KH',
              'language': 'E',
              'currency': 'USD',
              'taxCountry': 'KH',
            },
      },
      'metadata': null,
      'traceId': '0HNO3SR9S79ML:00000002',
    };

Map<String, dynamic> _createdDraftBody() => {
      'success': true,
      'data': {
        'draftId': 'brand-new-draft',
        'status': 'Draft',
        'isEditable': true,
        'fields': {'partnerCategory': '2', 'country': 'KH'},
      },
    };

void main() {
  late _ScriptedAdapter adapter;
  late BusinessPartnerRepositoryImpl repository;

  final activePath = '${AppConstants.customersEndpoint}/draft/active';
  final createPath = '${AppConstants.customersEndpoint}/draft';

  void script(Future<ResponseBody> Function(RequestOptions o) handler) {
    adapter = _ScriptedAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    repository =
        BusinessPartnerRepositoryImpl(CustomerRemoteDataSourceImpl(dio));
  }

  /// Answers the active-draft probe with [activeStatus], and any other request
  /// (i.e. the create call) with a brand-new draft.
  void scriptActive(String activeStatus, {bool isEditable = true}) {
    script((o) async => o.path.endsWith('/draft/active')
        ? _json(
            _activeDraftBody(status: activeStatus, isEditable: isEditable), 200)
        : _json(_createdDraftBody(), 200));
  }

  List<String> requestedPaths() => adapter.requests.map((r) => r.path).toList();

  group('an open Draft is resumed', () {
    test('it is returned as-is, and no new draft is created', () async {
      scriptActive('Draft');

      final opened = await repository.openDraft();

      expect(opened.resumed, isTrue);
      expect(opened.draft.draftId, '01a0412a-0b1c-7e79-8749-12f762b15627');
      expect(
        requestedPaths(),
        [activePath],
        reason: 'creating a draft here would abandon the rep\'s typing and '
            'leave a stale draft on the server',
      );
    });

    test('the saved field values come back so each step can prefill', () async {
      script((o) async => _json(
            _activeDraftBody(status: 'Draft', fields: {
              'name1': 'Sok Heng Hardware',
              'name3': 'ហាង សុខ ហេង',
              'city': '12',
              'district': '1204',
              'mobilePhone': '012345678',
              'customerGroup': '02',
            }),
            200,
          ));

      final opened = await repository.openDraft();

      expect(opened.draft.fields['name1'], 'Sok Heng Hardware');
      expect(opened.draft.fields['name3'], 'ហាង សុខ ហេង');
      expect(opened.draft.fields['district'], '1204');
      expect(opened.draft.fields['customerGroup'], '02');
    });
  });

  group('anything not editable starts a fresh draft', () {
    for (final status in const [
      'Submitted',
      'Registered',
      'Rejected',
      // A status this build has never heard of must degrade to "not
      // resumable" rather than throwing or being treated as editable.
      'SomeFutureStatus',
    ]) {
      test('status "$status" creates a new one', () async {
        scriptActive(status);

        final opened = await repository.openDraft();

        expect(opened.resumed, isFalse);
        expect(opened.draft.draftId, 'brand-new-draft');
        expect(requestedPaths(), [activePath, createPath]);
      });
    }

    test('status Draft but isEditable false is not resumed', () async {
      // The two disagreeing should resolve the restrictive way: writing into a
      // record the server considers closed would silently lose the edits.
      scriptActive('Draft', isEditable: false);

      final opened = await repository.openDraft();

      expect(opened.resumed, isFalse);
      expect(opened.draft.draftId, 'brand-new-draft');
    });
  });

  group('no draft open', () {
    test('a 404 means "none", not a failure', () async {
      script((o) async => o.path.endsWith('/draft/active')
          ? _json({
              'type': 'https://docs.isigroup.com.kh/errors/Draft.NotFound',
              'title': 'Not found.',
              'status': 404,
              'errorCode': 'Draft.NotFound',
            }, 404)
          : _json(_createdDraftBody(), 200));

      final opened = await repository.openDraft();

      expect(opened.resumed, isFalse);
      expect(opened.draft.draftId, 'brand-new-draft');
      expect(requestedPaths(), [activePath, createPath]);
    });

    test('a 200 with a null payload also means "none"', () async {
      // ApiEnvelope treats a missing payload as malformed, so this path is
      // parsed defensively instead. A rep must not be blocked from registering
      // a shop because "you have no draft" was phrased as an empty body.
      script((o) async => o.path.endsWith('/draft/active')
          ? _json({'success': true, 'data': null}, 200)
          : _json(_createdDraftBody(), 200));

      final opened = await repository.openDraft();

      expect(opened.resumed, isFalse);
      expect(opened.draft.draftId, 'brand-new-draft');
    });
  });

  group('real failures still surface', () {
    test('a 500 on the probe does not quietly create a second draft', () async {
      // Swallowing this would create a duplicate draft every time the server
      // wobbled, and the rep would lose the form they actually had open.
      script((o) async => o.path.endsWith('/draft/active')
          ? _json({'title': 'Server error'}, 500)
          : _json(_createdDraftBody(), 200));

      await expectLater(repository.openDraft(), throwsA(isA<DioException>()));
      expect(requestedPaths(), [activePath],
          reason: 'the create call must not run after an unexplained failure');
    });
  });
}
