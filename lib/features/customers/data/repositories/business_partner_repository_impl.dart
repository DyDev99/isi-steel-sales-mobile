import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_datasources.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/business_partner_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_reference_cache.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/sap_reference_options.dart';
import 'package:isi_steel_sales_mobile/core/logging/debug_trace.dart';

/// Submission is server-queued: a successful response means the platform
/// accepted the BP for HQ/SAP processing, not that SAP assigned a number.
/// Console tracer, sharing the registration channel so the reference load
/// reads in sequence with the draft and submit steps.
const _trace = DebugTrace('registration');

class BusinessPartnerRepositoryImpl implements BusinessPartnerRepository {
  const BusinessPartnerRepositoryImpl(this._remote, [this._references]);
  final CustomerRemoteDataSource _remote;

  /// Optional so an existing test can construct this without a Hive box; when
  /// absent the dropdowns fall back to the built-in lists.
  final CustomerReferenceCache? _references;

  @override
  Future<CustomerReferenceCatalogue> fetchReferences({
    Iterable<String>? kinds,
    String? search,
  }) =>
      _remote.fetchRegistrationReferences(kinds: kinds, search: search);

  @override
  Future<SapReferenceOptions> loadReferenceOptions() async {
    final cache = _references;

    // Fresh cache wins outright — these change rarely and the form opens on a
    // counter in a market, where a needless round trip is a stalled rep.
    final fresh = cache?.readFresh();
    if (fresh != null && !fresh.isEmpty) {
      _trace.ok('refs', 'cache hit', {
        'catalogues': fresh.catalogues.length,
        'synced': fresh.synchronisedAt?.toIso8601String(),
      });
      return SapReferenceOptions(fresh);
    }

    try {
      final fetched = await _remote.fetchRegistrationReferences();
      if (!fetched.isEmpty) {
        await cache?.write(fetched);
        _trace.ok('refs', 'loaded from ERP', {
          'catalogues': fetched.catalogues.length,
          // The per-catalogue counts, so "did CustomerGroup arrive?" is
          // answerable at a glance instead of by inspecting a dropdown whose
          // built-in fallback happens to look identical.
          'counts': fetched.catalogues.entries
              .map((e) => '${e.key}:${e.value.length}')
              .join(' '),
        });
        return SapReferenceOptions(fetched);
      }
      _trace.warn('refs', 'server sent no catalogues — using built-in lists');
    } on Object catch (error) {
      // Still swallowed: reference codes are an accuracy improvement on the
      // built-in lists, not a precondition for registering a shop, so a failure
      // here must never surface as an error the rep has to clear.
      //
      // But it is no longer *silent*. The built-in lists were corrected against
      // the live catalogues, so a failed load renders almost identically to a
      // successful one — which made "did the ERP data actually load?"
      // unanswerable without a packet capture.
      _trace.fail(
          'refs', 'load failed — falling back', {'error': error.runtimeType});
    }

    // Stale beats empty: an out-of-date ERP list still contains the codes a rep
    // needs far more often than the built-in list does.
    final stale = cache?.readStale();
    if (stale != null && !stale.isEmpty) {
      _trace.warn('refs', 'using stale cache', {
        'catalogues': stale.catalogues.length,
        'synced': stale.synchronisedAt?.toIso8601String(),
      });
      return SapReferenceOptions(stale);
    }

    _trace.warn('refs', 'using built-in lists — dropdowns are not live');
    return SapReferenceOptions.empty;
  }

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
