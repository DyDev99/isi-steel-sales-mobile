import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/visit_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_push_batch.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_sync_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_push_summary.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_sync_repository.dart';

/// Push side of visit-data sync, mirroring [RouteSyncRepositoryImpl]'s pull
/// side: same `NetworkInfo`-guarded fail-fast pattern, but scoped to
/// [VisitLocalDataSource] instead of [RouteLocalDataSource] — a separate
/// repository since these are genuinely different concerns (route/customer
/// pull vs. visit-capture push).
class VisitSyncRepositoryImpl implements VisitSyncRepository {
  const VisitSyncRepositoryImpl({
    required VisitSyncRemoteDataSource remote,
    required VisitLocalDataSource local,
    required NetworkInfo network,
  })  : _remote = remote,
        _local = local,
        _network = network;

  final VisitSyncRemoteDataSource _remote;
  final VisitLocalDataSource _local;
  final NetworkInfo _network;

  @override
  ResultFuture<VisitPushSummary> pushPendingVisitData() async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      final batch = VisitPushBatch(
        checkIns: await _local.fetchPendingCheckIns(),
        checkOuts: await _local.fetchPendingCheckOuts(),
        orderLines: await _local.fetchPendingOrderLines(),
        stockUpdates: await _local.fetchPendingStockUpdates(),
        returns: await _local.fetchPendingReturns(),
        collections: await _local.fetchPendingCollections(),
        notes: await _local.fetchPendingNotes(),
        photos: await _local.fetchPendingPhotos(),
      );
      if (batch.isEmpty) {
        return Success(
            VisitPushSummary(pushedCount: 0, syncedAt: DateTime.now()));
      }

      final result = await _remote.pushVisitData(batch);
      final accepted = result.acceptedIds.toSet();
      for (final entry in batch.idsByTable().entries) {
        final acceptedInTable = entry.value.where(accepted.contains).toList();
        await _local.markSynced(table: entry.key, ids: acceptedInTable);
      }

      return Success(VisitPushSummary(
          pushedCount: accepted.length, syncedAt: result.syncedAt));
    } on ServerException catch (e) {
      return Failed(
          ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }
}
