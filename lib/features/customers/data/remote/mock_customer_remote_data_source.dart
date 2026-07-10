import 'package:isi_steel_sales_mobile/features/customers/data/mock/mock_customer_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_sync_page.dart';

class MockCustomerRemoteDataSource implements CustomerRemoteDataSource {
  MockCustomerRemoteDataSource() : _all = MockCustomerData.generate();
  final List<CustomerModel> _all;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<CustomerInitialPage> fetchInitial(
      {required int page, required int pageSize}) async {
    await _latency();
    final start = page * pageSize;
    if (start >= _all.length) {
      return const CustomerInitialPage(items: [], hasMore: false);
    }
    final end = (start + pageSize).clamp(0, _all.length);
    return CustomerInitialPage(
      items: _all.sublist(start, end),
      hasMore: end < _all.length,
    );
  }

  @override
  Future<CustomerDeltaPage> fetchDelta({required DateTime since}) async {
    await _latency();
    // Mock backend has no real change feed yet — nothing changed since the
    // last sync.
    return const CustomerDeltaPage(upserted: [], deletedIds: []);
  }
}
