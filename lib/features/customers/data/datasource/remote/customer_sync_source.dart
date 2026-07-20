import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/customer_sync_page.dart';

/// The port through which customer rows enter the local database.
///
/// Called only by the sync repository — deliberately the single choke point
/// through which a `Customer` row can come into existence locally. That
/// invariant is what makes "a customer always originates in SAP" enforceable
/// rather than merely intended.
///
/// The sole implementation is `SapCustomerSyncSource`
/// (`data/datasource/remote/sap/`). The interface is kept rather than folded
/// into that class because it is what the repository depends on: the repository
/// is unit-testable against a fake, and a second backend (or a replay/import
/// source) can be added without touching it.
abstract interface class CustomerSyncSource {
  /// Pulls one page of the customer master. [page] is 0-based.
  Future<CustomerInitialPage> fetchInitial({
    required int page,
    required int pageSize,
  });

  /// Fetches everything that changed since [since].
  ///
  /// **The SAP façade has no changed-since endpoint.** Its Customer controller
  /// exposes only `Read`, `GetDetail` and `GetPaging` with static filters
  /// (`SapAPI_Technical_Document_v1_BP.docx` §5) — no delta feed, and no
  /// per-record modification timestamp to filter on. `SapCustomerSyncSource`
  /// therefore satisfies this contract by re-paging the full list and
  /// reconciling, which is correct but not cheap.
  ///
  /// The parameter is kept because a backend that does offer a delta feed would
  /// honour it, and the repository already passes the correct watermark.
  Future<CustomerDeltaPage> fetchDelta({required DateTime since});
}
