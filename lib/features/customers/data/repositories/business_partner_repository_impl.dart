import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_datasources.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/business_partner_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';

/// Submission is server-queued: a successful response means the platform
/// accepted the BP for HQ/SAP processing, not that SAP assigned a number.
class BusinessPartnerRepositoryImpl implements BusinessPartnerRepository {
  const BusinessPartnerRepositoryImpl(this._remote);
  final CustomerRemoteDataSource _remote;

  @override
  Future<CustomerReferenceCatalogue> fetchReferences({
    Iterable<String>? kinds,
    String? search,
  }) =>
      _remote.fetchRegistrationReferences(kinds: kinds, search: search);

  @override
  Future<OpenedRegistrationDraft> openDraft() async {
    // Ask what the rep already has before making anything. Creating first and
    // reconciling later would strand the half-finished form they left behind.
    final active = await _remote.fetchActiveRegistrationDraft();

    if (active != null && active.isResumable) {
      return OpenedRegistrationDraft(draft: active, resumed: true);
    }

    // Either nothing is open, or what is open has already been submitted and
    // can no longer be edited. Both mean: start a fresh form.
    return OpenedRegistrationDraft(
      draft: await _remote.createRegistrationDraft(),
      resumed: false,
    );
  }

  @override
  Future<CustomerRegistrationDraft> createServerDraft() =>
      _remote.createRegistrationDraft();

  @override
  Future<CustomerRegistrationDraft> updateServerDraft({
    required String draftId,
    required Map<String, dynamic> changedFields,
  }) =>
      _remote.updateRegistrationDraft(
        draftId: draftId,
        changedFields: changedFields,
      );

  @override
  Future<BusinessPartnerSubmitResult> submitServerDraft(String draftId) async {
    final response = await _remote.submitRegistrationDraft(draftId);
    return _submitResult(response);
  }

  @override
  Future<List<CustomerRegistrationDraft>> fetchServerDrafts() =>
      _remote.fetchRegistrationDrafts();

  @override
  Future<CustomerRegistrationDraft> fetchServerDraft(String draftId) =>
      _remote.fetchRegistrationDraft(draftId);

  @override
  Future<void> deleteServerDraft(String draftId) =>
      _remote.deleteRegistrationDraft(draftId);

  @override
  Future<BusinessPartnerSubmitResult> submit(
      Map<String, dynamic> payload) async {
    final response = await _remote.createBusinessPartner(payload);
    return _submitResult(response);
  }

  BusinessPartnerSubmitResult _submitResult(CreateBpResponse response) =>
      BusinessPartnerSubmitResult(
        localId: response.localId,
        customerCode: response.customerCode,
        // "Submitted" means accepted by the platform and awaiting SAP push;
        // it is successful, not an offline queue fallback.
        queuedOffline: false,
      );

  // Draft persistence will be backed by the encrypted draft store once its
  // schema is added. These no-ops deliberately do not affect submission.
  @override
  Future<void> saveDraft(BpCustomerDraft draft) async {}
  @override
  Future<void> clearDraft() async {}
}
