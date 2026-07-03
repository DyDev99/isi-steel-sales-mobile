import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/local/route_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/remote/route_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_sync_result.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_sync_scope.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/repositories/route_sync_repository.dart';

const _routesEntity = 'routes';

/// Mirrors `order`'s `SyncRepositoryImpl` method-for-method — the only
/// repository allowed to touch [RouteRemoteDataSource].
class RouteSyncRepositoryImpl implements RouteSyncRepository {
  const RouteSyncRepositoryImpl({
    required RouteRemoteDataSource remote,
    required RouteLocalDataSource local,
    required NetworkInfo network,
  })  : _remote = remote,
        _local = local,
        _network = network;

  final RouteRemoteDataSource _remote;
  final RouteLocalDataSource _local;
  final NetworkInfo _network;

  static const _pageSize = 50;

  @override
  ResultFuture<DateTime?> lastSyncedAt() async {
    try {
      return Success(await _local.getLastSyncedAt(_routesEntity));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<RouteSyncResult> runInitialSync(RouteSyncScope scope) async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      var page = 0;
      var total = 0;
      while (true) {
        final result = await _remote.fetchInitial(scope: scope, page: page, pageSize: _pageSize);
        await _local.upsertCustomers(result.customers);
        if (result.routes.isNotEmpty) {
          await _local.upsertRoutes(result.routes);
          total += result.routes.length;
        }
        if (!result.hasMore) break;
        page++;
      }

      final now = DateTime.now();
      await _local.setLastSyncedAt(_routesEntity, now);
      return Success(RouteSyncResult(upserted: total, deleted: 0, syncedAt: now));
    } on ServerException catch (e) {
      return Failed(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<RouteSyncResult> runDeltaSync(RouteSyncScope scope) async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      final since = await _local.getLastSyncedAt(_routesEntity);
      if (since == null) return runInitialSync(scope);

      final delta = await _remote.fetchDelta(scope: scope, since: since);
      await _local.upsertCustomers(delta.customers);
      if (delta.routes.isNotEmpty) await _local.upsertRoutes(delta.routes);

      final now = DateTime.now();
      await _local.setLastSyncedAt(_routesEntity, now);
      return Success(RouteSyncResult(upserted: delta.routes.length, deleted: 0, syncedAt: now));
    } on ServerException catch (e) {
      return Failed(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }
}
