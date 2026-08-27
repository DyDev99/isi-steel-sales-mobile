// =============================================================================
// customer_datasources.dart
//
// Split these into two files in your tree:
//   lib/features/customer/data/datasources/customer_remote_datasource.dart
//   lib/features/customer/data/datasources/customer_local_datasource.dart
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';

// -----------------------------------------------------------------------------
// REMOTE
// -----------------------------------------------------------------------------

/// Middleware rejected the payload. Retrying is pointless — the rep must fix
/// a field. Distinct from a network error, which IS worth retrying.
class ValidationFailure implements Exception {
  final String message;
  final String? field;
  final String? code;
  const ValidationFailure(this.message, {this.field, this.code});
}

/// The server-owned registration form. `fields` is intentionally a map: the
/// API owns the 46-field SAP schema and can add a field without breaking an
/// already released mobile app.
class CustomerRegistrationDraft {
  const CustomerRegistrationDraft({
    required this.draftId,
    required this.fields,
    this.status = kDraftStatus,
    this.isEditable = true,
    this.submittedCustomerId,
  });

  /// The status a draft carries while the rep can still edit it. Other values
  /// (`Submitted`, `Registered`, `Rejected`, …) mean the form has left the
  /// rep's hands.
  static const String kDraftStatus = 'Draft';

  final String draftId;
  final Map<String, dynamic> fields;

  /// Server lifecycle state. Kept as the raw string rather than an enum: the
  /// server may add a status before this app ships again, and an unrecognised
  /// value must degrade to "not resumable", never throw.
  final String status;

  final bool isEditable;

  /// Set once the draft has become a real customer.
  final String? submittedCustomerId;

  /// Whether this draft should be reopened rather than replaced by a new one.
  ///
  /// Both conditions are checked on purpose. `status` is the documented
  /// contract, and `isEditable` is the server's own verdict — if they ever
  /// disagree, the safe reading is the restrictive one, because resuming a
  /// draft the server considers closed would send the rep's edits into a
  /// record that can no longer accept them.
  bool get isResumable =>
      isEditable && status.toLowerCase() == kDraftStatus.toLowerCase();

  factory CustomerRegistrationDraft.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'];
    return CustomerRegistrationDraft(
      draftId: json['draftId'] as String? ?? '',
      fields: fields is Map<String, dynamic>
          ? fields
          : fields is Map
              ? fields.cast<String, dynamic>()
              : const {},
      // Defaults describe a freshly created draft, which is what `POST /draft`
      // returns and what older responses that omit these keys mean.
      status: json['status'] as String? ?? kDraftStatus,
      isEditable: json['isEditable'] as bool? ?? true,
      submittedCustomerId: json['submittedCustomerId'] as String?,
    );
  }
}

/// Flat reference catalogues returned by `/references`. Sales employees are
/// deliberately absent unless queried with `search`, per MobileCustomerApi.
class CustomerReferenceCatalogue {
  const CustomerReferenceCatalogue(this.values);
  final Map<String, dynamic> values;

  factory CustomerReferenceCatalogue.fromJson(Map<String, dynamic> json) =>
      CustomerReferenceCatalogue(json);
}

class CreateBpResponse {
  /// Null when HQ approval is still pending — SAP has not assigned a number yet.
  final String? customerCode;
  final String status; // PENDING_HQ | CREATED | REJECTED
  final String localId;

  const CreateBpResponse({
    required this.status,
    required this.localId,
    this.customerCode,
  });

  factory CreateBpResponse.fromJson(Map<String, dynamic> j) => CreateBpResponse(
        customerCode: (j['customerCode'] ?? j['customer_code']) as String?,
        status: (j['sapStatus'] ?? j['status']) as String? ?? 'PENDING_HQ',
        localId: (j['customerId'] ?? j['local_id']) as String? ?? '',
      );
}

abstract class CustomerRemoteDataSource {
  Future<CustomerReferenceCatalogue> fetchRegistrationReferences({
    Iterable<String>? kinds,
    String? search,
  });
  Future<CustomerRegistrationDraft> createRegistrationDraft();

  /// The rep's current registration form, or null when they have none open.
  ///
  /// Null covers three genuinely different situations that the caller treats
  /// identically — no draft has ever been started, the last one was submitted,
  /// or this server does not expose the endpoint yet (404). In all three the
  /// right next move is to create a fresh draft.
  Future<CustomerRegistrationDraft?> fetchActiveRegistrationDraft();

  Future<CustomerRegistrationDraft> updateRegistrationDraft({
    required String draftId,
    required Map<String, dynamic> changedFields,
  });
  Future<CreateBpResponse> submitRegistrationDraft(String draftId);
  Future<List<CustomerRegistrationDraft>> fetchRegistrationDrafts();
  Future<CustomerRegistrationDraft> fetchRegistrationDraft(String draftId);
  Future<void> deleteRegistrationDraft(String draftId);

  /// Compatibility route for older clients. New UI should use the server-draft
  /// lifecycle above so a killed handset can resume a partially completed form.
  Future<CreateBpResponse> createBusinessPartner(Map<String, dynamic> payload);

  Future<String> uploadAttachment({
    required String localId,
    required String kind,
    required String filePath,
  });
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final Dio _dio;
  const CustomerRemoteDataSourceImpl(this._dio);

  @override
  Future<CustomerReferenceCatalogue> fetchRegistrationReferences({
    Iterable<String>? kinds,
    String? search,
  }) async {
    final query = <String, dynamic>{
      if (kinds != null && kinds.isNotEmpty) 'kinds': kinds.join(','),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    debugPrint('[CustomerRegistration] GET references '
        'kinds=${kinds?.join(',') ?? 'all'} search=${search?.trim().isEmpty ?? true ? 'none' : 'provided'}');
    final response = await _get(
      '${AppConstants.customersEndpoint}/references',
      queryParameters: query,
    );
    return CustomerReferenceCatalogue.fromJson(_data(response));
  }

  @override
  Future<CustomerRegistrationDraft> createRegistrationDraft() async {
    debugPrint('[CustomerRegistration] POST draft');
    final response = await _post('${AppConstants.customersEndpoint}/draft');
    final draft = CustomerRegistrationDraft.fromJson(_data(response));
    debugPrint('[CustomerRegistration] POST draft complete '
        'draftId=${draft.draftId} fieldCount=${draft.fields.length}');
    return draft;
  }

  @override
  Future<CustomerRegistrationDraft?> fetchActiveRegistrationDraft() async {
    debugPrint('[CustomerRegistration] GET draft/active');

    final Response<dynamic> response;
    try {
      response =
          await _dio.get('${AppConstants.customersEndpoint}/draft/active');
    } on DioException catch (error) {
      final apiError = ApiError.fromDio(error);
      // 404 is "you have no open form", not a failure. It is also what a
      // server that has not deployed this endpoint yet answers, so treating it
      // as absence keeps the app working against both.
      if (apiError.statusCode == 404) {
        debugPrint('[CustomerRegistration] GET draft/active -> none (404)');
        return null;
      }
      throw _translate(error, apiError);
    }

    // Read the envelope defensively rather than through `_data`: a server with
    // no active draft may answer 200 with `"data": null`, and ApiEnvelope
    // treats a missing payload as a malformed response.
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      debugPrint('[CustomerRegistration] GET draft/active -> none (empty)');
      return null;
    }

    final draft =
        CustomerRegistrationDraft.fromJson(data.cast<String, dynamic>());
    if (draft.draftId.isEmpty) {
      debugPrint('[CustomerRegistration] GET draft/active -> none (no id)');
      return null;
    }

    debugPrint('[CustomerRegistration] GET draft/active complete '
        'draftId=${draft.draftId} status=${draft.status} '
        'resumable=${draft.isResumable} fieldCount=${draft.fields.length}');
    return draft;
  }

  @override
  Future<CustomerRegistrationDraft> updateRegistrationDraft({
    required String draftId,
    required Map<String, dynamic> changedFields,
  }) async {
    debugPrint('[CustomerRegistration] POST update '
        'draftId=$draftId changedFields=${changedFields.keys.join(',')}');
    final response = await _post('${AppConstants.customersEndpoint}/update',
        // `fields` is intentional: update is a patch, and the server must be
        // able to distinguish an omitted field from one explicitly set to ''.
        data: {'draftId': draftId, 'fields': changedFields});
    final draft = CustomerRegistrationDraft.fromJson(_data(response));
    debugPrint('[CustomerRegistration] POST update complete '
        'draftId=${draft.draftId} fieldCount=${draft.fields.length}');
    return draft;
  }

  @override
  Future<CreateBpResponse> submitRegistrationDraft(String draftId) async {
    debugPrint('[CustomerRegistration] POST submit draftId=$draftId');
    final response = await _post('${AppConstants.customersEndpoint}/submit',
        data: {'draftId': draftId});
    final result = CreateBpResponse.fromJson(_data(response));
    debugPrint('[CustomerRegistration] POST submit complete '
        'draftId=$draftId status=${result.status}');
    return result;
  }

  @override
  Future<List<CustomerRegistrationDraft>> fetchRegistrationDrafts() async {
    debugPrint('[CustomerRegistration] GET drafts');
    final response = await _get('${AppConstants.customersEndpoint}/drafts');
    final data = _data(response);
    final drafts = data['drafts'] ?? data['items'] ?? data;
    if (drafts is! List) return const [];
    final result = drafts
        .whereType<Map>()
        .map((draft) =>
            CustomerRegistrationDraft.fromJson(draft.cast<String, dynamic>()))
        .toList();
    debugPrint(
        '[CustomerRegistration] GET drafts complete count=${result.length}');
    return result;
  }

  @override
  Future<CustomerRegistrationDraft> fetchRegistrationDraft(
      String draftId) async {
    debugPrint('[CustomerRegistration] GET draft draftId=$draftId');
    final response =
        await _get('${AppConstants.customersEndpoint}/draft/$draftId');
    return CustomerRegistrationDraft.fromJson(_data(response));
  }

  @override
  Future<void> deleteRegistrationDraft(String draftId) =>
      _deleteRegistrationDraft(draftId);

  Future<void> _deleteRegistrationDraft(String draftId) async {
    debugPrint('[CustomerRegistration] DELETE draft draftId=$draftId');
    await _dio.delete<void>('${AppConstants.customersEndpoint}/draft/$draftId');
    debugPrint('[CustomerRegistration] DELETE draft complete draftId=$draftId');
  }

  @override
  Future<CreateBpResponse> createBusinessPartner(
      Map<String, dynamic> payload) async {
    debugPrint(
        '[CustomerRegistration] POST business-partner (compatibility path)');
    final response = await _post(
      '${AppConstants.customersEndpoint}/business-partner',
      data: payload,
    );
    final result = CreateBpResponse.fromJson(_data(response));
    debugPrint('[CustomerRegistration] POST business-partner complete '
        'status=${result.status}');
    return result;
  }

  Future<Response<dynamic>> _get(String path,
          {Map<String, dynamic>? queryParameters}) async =>
      _request(() => _dio.get(path, queryParameters: queryParameters));

  Future<Response<dynamic>> _post(String path, {Object? data}) async =>
      _request(() => _dio.post(path, data: data));

  Future<Response<dynamic>> _request(
      Future<Response<dynamic>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _translate(error, ApiError.fromDio(error));
    }
  }

  /// Maps a transport failure onto the exception the callers expect.
  ///
  /// Shared with [fetchActiveRegistrationDraft], which cannot go through
  /// [_request] because it has to inspect the status code before the mapping
  /// happens — a 404 there is an answer, not an error.
  Object _translate(DioException error, ApiError apiError) {
    debugPrint('[CustomerRegistration] API failure '
        'status=${apiError.statusCode} code=${apiError.code} '
        'correlationId=${apiError.correlationId ?? 'none'}');
    final status = apiError.statusCode ?? 0;
    // A 4xx means the rep must change something; retrying the same payload
    // cannot succeed. 5xx and transport errors stay retryable.
    if (status >= 400 && status < 500) {
      return ValidationFailure(
        apiError.message ?? 'Invalid data',
        field: apiError.fieldErrors.keys.firstOrNull,
        code: apiError.code,
      );
    }
    return error;
  }

  Map<String, dynamic> _data(Response<dynamic> response) =>
      ApiEnvelope.fromBody(response.data).data;

  @override
  Future<String> uploadAttachment({
    required String localId,
    required String kind,
    required String filePath,
  }) async {
    final form = FormData.fromMap({
      'local_id': localId,
      'kind': kind,
      'file': await MultipartFile.fromFile(filePath),
    });

    final res = await _dio.post(
      '/api/v1/customers/bp/$localId/attachments',
      data: form,
    );
    return res.data['url'] as String;
  }
}

// -----------------------------------------------------------------------------
// LOCAL
// -----------------------------------------------------------------------------

class PendingSubmission {
  final String localId;
  final Map<String, dynamic> payload;
  final List<BpAttachment> attachments;
  final DateTime queuedAt;
  final int attemptCount;

  const PendingSubmission({
    required this.localId,
    required this.payload,
    required this.attachments,
    required this.queuedAt,
    this.attemptCount = 0,
  });
}

abstract class CustomerLocalDataSource {
  // Queue
  Future<String> enqueueSubmission(Map<String, dynamic> payload);
  Future<void> dequeueSubmission(String localId);
  Future<List<PendingSubmission>> pendingSubmissions();
  Future<int> pendingCount();
  Future<void> markSubmitted(String localId, {String? customerCode});
  Future<void> markRejected(String localId, String reason);
  Future<void> markAttachmentUploaded(String localId, String kind, String url);

  // In-progress form
  Future<void> writeDraft(String json);
  Future<String?> readDraft();
  Future<void> clearDraft();
}
