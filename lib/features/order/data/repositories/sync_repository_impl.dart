import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/product_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/product_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_result.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_scope.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_repository.dart';

const _productsEntity = 'products';

/// The only repository allowed to touch [ProductRemoteDataSource] — every
/// read repository in this feature reads local-only, so this is where
/// "never download the full catalog again" and "pull only what changed"
/// actually live.
class SyncRepositoryImpl implements SyncRepository {
  const SyncRepositoryImpl({
    required ProductRemoteDataSource remote,
    required ProductLocalDataSource local,
    required NetworkInfo network,
  })  : _remote = remote,
        _local = local,
        _network = network;

  final ProductRemoteDataSource _remote;
  final ProductLocalDataSource _local;
  final NetworkInfo _network;

  static const _pageSize = 500;

  @override
  ResultFuture<DateTime?> lastSyncedAt() async {
    try {
      return Success(await _local.getLastSyncedAt(_productsEntity));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<SyncResult> runInitialSync(SyncScope scope) async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      final categories = await _remote.fetchCategories();
      await _local.upsertCategories(categories);

      var page = 0;
      var total = 0;
      while (true) {
        final result = await _remote.fetchInitial(scope: scope, page: page, pageSize: _pageSize);
        if (result.items.isNotEmpty) {
          await _local.upsertProducts(result.items);
          total += result.items.length;
        }
        if (!result.hasMore) break;
        page++;
      }

      final now = DateTime.now();
      await _local.setLastSyncedAt(_productsEntity, now);
      return Success(SyncResult(upserted: total, deleted: 0, syncedAt: now));
    } on ServerException catch (e) {
      return Failed(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<SyncResult> runDeltaSync(SyncScope scope) async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      final since = await _local.getLastSyncedAt(_productsEntity);
      if (since == null) return runInitialSync(scope);

      final delta = await _remote.fetchDelta(scope: scope, since: since);
      if (delta.upserted.isNotEmpty) await _local.upsertProducts(delta.upserted);
      if (delta.deletedIds.isNotEmpty) await _local.markDeleted(delta.deletedIds);

      final now = DateTime.now();
      await _local.setLastSyncedAt(_productsEntity, now);
      return Success(SyncResult(
        upserted: delta.upserted.length,
        deleted: delta.deletedIds.length,
        syncedAt: now,
      ));
    } on ServerException catch (e) {
      return Failed(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }
}
