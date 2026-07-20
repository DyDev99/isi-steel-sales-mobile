import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/customer_sync_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_sync_result.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_sync_repository.dart';

const _customersEntity = 'customers';

/// The only repository allowed to touch [CustomerSyncSource] — this
/// is where "a Customer row only ever comes from SAP" is enforced: nothing
/// in this feature calls `_local.upsertCustomers` except the two sync
/// methods below.
class CustomerSyncRepositoryImpl implements CustomerSyncRepository {
  const CustomerSyncRepositoryImpl({
    required CustomerSyncSource remote,
    required CustomerLocalDataSource local,
    required NetworkInfo network,
  })  : _remote = remote,
        _local = local,
        _network = network;

  final CustomerSyncSource _remote;
  final CustomerLocalDataSource _local;
  final NetworkInfo _network;

  static const _pageSize = 200;

  @override
  ResultFuture<DateTime?> lastSyncedAt() async {
    try {
      return Success(await _local.getLastSyncedAt(_customersEntity));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<CustomerSyncResult> runInitialSync() async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      var page = 0;
      var total = 0;
      while (true) {
        final result =
            await _remote.fetchInitial(page: page, pageSize: _pageSize);
        if (result.items.isNotEmpty) {
          await _local.upsertCustomers(result.items);
          total += result.items.length;
        }
        if (!result.hasMore) break;
        page++;
      }

      final now = DateTime.now();
      await _local.setLastSyncedAt(_customersEntity, now);
      return Success(
          CustomerSyncResult(upserted: total, deleted: 0, syncedAt: now));
    } on ServerException catch (e) {
      return Failed(
          ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<CustomerSyncResult> runDeltaSync() async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      final since = await _local.getLastSyncedAt(_customersEntity);
      if (since == null) return runInitialSync();

      final delta = await _remote.fetchDelta(since: since);
      if (delta.upserted.isNotEmpty) {
        await _local.upsertCustomers(delta.upserted);
      }
      if (delta.deletedIds.isNotEmpty) {
        await _local.markDeleted(delta.deletedIds);
      }

      final now = DateTime.now();
      await _local.setLastSyncedAt(_customersEntity, now);
      return Success(CustomerSyncResult(
        upserted: delta.upserted.length,
        deleted: delta.deletedIds.length,
        syncedAt: now,
      ));
    } on ServerException catch (e) {
      return Failed(
          ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }
}
