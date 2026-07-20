import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/customer_sap_remote_datasource.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/sap_customer_mapper.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/customer_sync_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/customer_sync_page.dart';

/// Adapts the SAP customer master onto the sync port the repository consumes.
///
/// The only implementation of [CustomerSyncSource] — the in-memory generator it
/// used to sit alongside has been deleted, so every customer row in the local
/// database now originates in SAP.
///
/// The indirection is still worth keeping: the repository depends on the port,
/// not on this class, which is what lets the repository be unit-tested without
/// an HTTP stack and what would let a second source (a bulk import, a replay
/// fixture) be added without touching it.
class SapCustomerSyncSource implements CustomerSyncSource {
  const SapCustomerSyncSource(this._sap, {String? salesOrg, String? division})
      : _salesOrg = salesOrg,
        _division = division;

  final CustomerSapRemoteDataSource _sap;

  /// Optional sales-area scoping. Left null, the sync pulls the whole customer
  /// master for the connection.
  final String? _salesOrg;
  final String? _division;

  @override
  Future<CustomerInitialPage> fetchInitial({
    required int page,
    required int pageSize,
  }) async {
    // The repository's loop is 0-based; SAP's `page` parameter is 1-based and
    // defaults to 1 (technical document §5.3). Converting here keeps the
    // off-by-one in one place instead of leaking into the repository.
    final sapPage = await _sap.fetchPage(
      page: page + 1,
      pageSize: pageSize,
      salesOrg: _salesOrg,
      division: _division,
    );

    return CustomerInitialPage(
      items: sapPage.toCustomerModels(syncedAt: DateTime.now().toUtc()),
      hasMore: sapPage.hasMore,
    );
  }

  /// Reconciles against the full customer list.
  ///
  /// **Why this is a full pull, not a delta.** The SAP façade exposes no
  /// changed-since endpoint and no per-record modification timestamp
  /// (`SapAPI_Technical_Document_v1_BP.docx` §5) — `GetPaging` filters on
  /// customer number, sales org, division and name, none of which express
  /// "changed after T". So [since] cannot be pushed down to the server.
  ///
  /// Re-paging everything and upserting is still correct: the upsert is
  /// idempotent and keyed on the SAP customer number, so unchanged rows are
  /// rewritten with identical values.
  ///
  /// **Deletions are deliberately not inferred here.** It is tempting to treat
  /// "present locally, absent from the pull" as deleted, but a pull truncated by
  /// a dropped connection or a mid-sync SAP error is indistinguishable from a
  /// genuinely shorter list — and acting on that would wipe the rep's customer
  /// directory offline, with no way to get it back until connectivity returns.
  /// Reconciling deletions safely needs either a tombstone feed from SAP or a
  /// verified-complete-pull signal; until one exists, [CustomerDeltaPage.deletedIds]
  /// stays empty and stale rows are left in place.
  @override
  Future<CustomerDeltaPage> fetchDelta({required DateTime since}) async {
    final syncedAt = DateTime.now().toUtc();
    final upserted = <CustomerModel>[];

    var page = 1;
    while (true) {
      final sapPage = await _sap.fetchPage(
        page: page,
        pageSize: _deltaPageSize,
        salesOrg: _salesOrg,
        division: _division,
      );

      upserted.addAll(sapPage.toCustomerModels(syncedAt: syncedAt));

      if (!sapPage.hasMore || sapPage.rows.isEmpty) break;
      page++;

      // Hard stop. `hasMore` derives from SAP's own totalPages; if that value
      // were ever wrong this loop would page forever against a live ERP.
      if (page > _maxPages) break;
    }

    return CustomerDeltaPage(upserted: upserted, deletedIds: const []);
  }

  /// The technical document (§6.4) advises keeping page size at 50 or below.
  static const _deltaPageSize = 50;

  /// 50 × 500 = 25,000 customers, comfortably above the 1,240 the document's
  /// own example reports, while still bounding a runaway loop.
  static const _maxPages = 500;
}
