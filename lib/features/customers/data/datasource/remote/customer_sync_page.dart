import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';

/// One page of a full customer pull.
class CustomerInitialPage {
  const CustomerInitialPage({required this.items, required this.hasMore});

  final List<CustomerModel> items;
  final bool hasMore;
}

/// The result of a reconciliation pass.
///
/// [deletedIds] is currently always empty against SAP — see
/// `SapCustomerSyncSource.fetchDelta` for why deletions cannot be safely
/// inferred from a pull that may have been truncated by a dropped connection.
/// The field remains because a backend offering a tombstone feed would populate
/// it, and the repository already handles it correctly.
class CustomerDeltaPage {
  const CustomerDeltaPage({required this.upserted, required this.deletedIds});

  final List<CustomerModel> upserted;
  final List<String> deletedIds;
}
