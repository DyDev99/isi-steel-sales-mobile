import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_sync_page.dart';

/// The SAP customer master, as seen from the mobile app. Only ever called
/// by the sync repository — this is intentionally the single choke point
/// through which a `Customer` row can come into existence locally.
abstract interface class CustomerRemoteDataSource {
  Future<CustomerInitialPage> fetchInitial(
      {required int page, required int pageSize});
  Future<CustomerDeltaPage> fetchDelta({required DateTime since});
}
