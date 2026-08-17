import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/mock/mock_customer_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_draft.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_sync_page.dart';

/// Offline stand-in for [CustomerRemoteDataSource], used for demo builds and
/// widget tests. Mirrors the real contract closely enough that swapping in
/// [ApiCustomerRemoteDataSource] changes no caller — including the one-based
/// paging and the server-supplied `syncTimestamp`.
class MockCustomerRemoteDataSource implements CustomerRemoteDataSource {
  MockCustomerRemoteDataSource() : _all = MockCustomerData.generate();
  final List<CustomerModel> _all;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<CustomerInitialPage> fetchInitial({
    required int page,
    required int pageSize,
  }) async {
    await _latency();
    // One-based, matching the API.
    final start = (page - 1) * pageSize;
    if (start >= _all.length) {
      return CustomerInitialPage(
        items: const [],
        hasMore: false,
        syncTimestamp: DateTime.now().toUtc(),
        pageSize: pageSize,
      );
    }
    final end = (start + pageSize).clamp(0, _all.length);
    return CustomerInitialPage(
      items: _all.sublist(start, end),
      hasMore: end < _all.length,
      syncTimestamp: DateTime.now().toUtc(),
      pageSize: pageSize,
    );
  }

  @override
  Future<CustomerDeltaPage> fetchDelta({
    required DateTime since,
    int page = 1,
    int pageSize = 200,
  }) async {
    await _latency();
    // Mock backend has no real change feed yet — nothing changed since the
    // last sync. The timestamp still advances so the watermark behaves.
    return CustomerDeltaPage(
      upserted: const [],
      deletedIds: const [],
      hasMore: false,
      syncTimestamp: DateTime.now().toUtc(),
    );
  }

  @override
  Future<CustomerModel> fetchById(String id) async {
    await _latency();
    return _all.firstWhere(
      (c) => c.id == id,
      orElse: () => throw StateError('No mock customer with id "$id".'),
    );
  }

  /// Creation has no mock backing: a fabricated id would be indistinguishable
  /// from a real one until the next sync deleted it. Run against the live API
  /// to register a customer.
  @override
  Future<CustomerModel> create(CustomerDraft draft) async {
    await _latency();
    throw const ServerException(
      message: 'Registering a customer requires the live API.',
      statusCode: 501,
    );
  }
}
