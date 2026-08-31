import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/sap_reference_options.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_datasources.dart';

class BusinessPartnerSubmitResult {
  const BusinessPartnerSubmitResult(
      {required this.localId, this.queuedOffline = false, this.customerCode});
  final String localId;
  final bool queuedOffline;
  final String? customerCode;
}

/// The form the rep should be editing, plus whether it was resumed.
///
/// The flag exists so the UI can tell the rep *why* the form arrived
/// half-filled. Silently restoring someone's half-finished registration and
/// saying nothing looks like a bug from the other side of the screen.
class OpenedRegistrationDraft {
  const OpenedRegistrationDraft({required this.draft, required this.resumed});

  final CustomerRegistrationDraft draft;
  final bool resumed;
}

abstract interface class BusinessPartnerRepository {
  Future<CustomerReferenceCatalogue> fetchReferences({
    Iterable<String>? kinds,
    String? search,
  });

  /// The ERP catalogues the registration dropdowns read, cache-first.
  ///
  /// Never throws and never returns nothing usable: a network failure falls back
  /// to the last cached copy, and an empty cache falls back to the built-in
  /// lists. A rep must always be able to finish a registration, so an
  /// unreachable reference endpoint degrades the *accuracy* of the dropdowns,
  /// never their availability.
  Future<SapReferenceOptions> loadReferenceOptions();

  /// Resumes the rep's open registration form, or starts a new one.
  ///
  /// Always prefer this over [createServerDraft] when opening the form: a rep
  /// who backed out mid-registration, or whose handset died, has a draft
  /// waiting on the server, and creating another one abandons their typing and
  /// leaves a stale draft behind.
  Future<OpenedRegistrationDraft> openDraft();

  /// Unconditionally starts a new form. Prefer [openDraft].
  Future<CustomerRegistrationDraft> createServerDraft();
  Future<CustomerRegistrationDraft> updateServerDraft({
    required String draftId,
    required Map<String, dynamic> changedFields,
  });
  Future<BusinessPartnerSubmitResult> submitServerDraft(String draftId);
  Future<List<CustomerRegistrationDraft>> fetchServerDrafts();
  Future<CustomerRegistrationDraft> fetchServerDraft(String draftId);
  Future<void> deleteServerDraft(String draftId);

  /// Legacy one-shot submission. Retained while the form is migrated to the
  /// server-owned draft lifecycle.
  Future<BusinessPartnerSubmitResult> submit(Map<String, dynamic> payload);
  Future<void> saveDraft(BpCustomerDraft draft);
  Future<void> clearDraft();
}
