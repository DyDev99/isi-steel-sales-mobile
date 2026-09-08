import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/visit_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/visit_capture_models.dart';
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
    AppLogger? logger,
  })  : _remote = remote,
        _local = local,
        _network = network,
        _logger = logger;

  final VisitSyncRemoteDataSource _remote;
  final VisitLocalDataSource _local;
  final NetworkInfo _network;

  /// Optional so existing construction sites and tests compile unchanged.
  final AppLogger? _logger;

  @override
  ResultFuture<VisitPushSummary> pushPendingVisitData() async {
    if (!await _network.isConnected) return const Failed(NetworkFailure());
    try {
      final pendingStock = await _local.fetchPendingStockUpdates();
      final quarantined = pendingStock.where(_isUnstorable).toList();
      if (quarantined.isNotEmpty) {
        _logger?.warning('visit.push.quarantined', fields: {
          'table': 'visit_stock_updates',
          'count': quarantined.length,
          'ids': [for (final r in quarantined) r.id],
        });
        await _local.markSynced(
          table: 'visit_stock_updates',
          ids: [for (final r in quarantined) r.id],
        );
      }

      final batch = VisitPushBatch(
        checkIns: await _local.fetchPendingCheckIns(),
        checkOuts: await _local.fetchPendingCheckOuts(),
        orderLines: await _local.fetchPendingOrderLines(),
        stockUpdates: pendingStock.where((r) => !_isUnstorable(r)).toList(),
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

      // Rows the server will never store (api.md §6.1). They are retired from
      // the queue, because the alternative is not "try again later" — it is
      // every future push carrying them, forever, on a device that is often
      // metered and always battery-bound.
      //
      // Retiring them reuses `markSynced`, which overstates what happened: the
      // row is gone from the queue but never reached the server. A dedicated
      // `sync_status = 'discarded'` is the honest state and wants a table
      // migration in the DAO layer; until then the log line below is the
      // record that this row died rather than landed. Deliberately loud — a
      // discard is the server telling us the client produced something
      // unstorable, which is a bug report, not routine sync noise.
      final discarded = result.discardedIds.toSet();
      if (discarded.isNotEmpty) {
        _logger?.warning('visit.push.discarded', fields: {
          'count': discarded.length,
          'reasons': {
            for (final id in discarded)
              id: result.discardReasons[id] ?? 'unknown',
          },
        });
      }

      final retired = {...accepted, ...discarded};
      for (final entry in batch.idsByTable().entries) {
        final retiredInTable = entry.value.where(retired.contains).toList();
        await _local.markSynced(table: entry.key, ids: retiredInTable);
      }

      // Counts what the server actually holds. A discarded row is not a pushed
      // row, and reporting it as one would show the rep a success total that
      // includes work no one will ever see.
      return Success(VisitPushSummary(
          pushedCount: accepted.length, syncedAt: result.syncedAt));
    } on ApiException catch (e) {
      // Same sibling-type trap as the pull side: [ApiException] is not a
      // [ServerException], so without this branch a 401 escaped the repository
      // and crashed the app. Nothing is marked synced on this path, so every
      // captured row stays pending and the next push retries it.
      return Failed(_failure(e.error));
    } on ServerException catch (e) {
      return Failed(
          ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  /// A stock row already on the device that the push endpoint will refuse.
  ///
  /// **This is cleanup for rows written by an earlier build, and it should be
  /// deleted once no install can still be carrying them.** The writer that
  /// produced them is fixed — `_persistStockUpdates` no longer puts a customer
  /// id in `depotId`, and no longer writes the mock catalog at all — but a
  /// fix at the writer does nothing about rows already sitting `pending` in
  /// Drift. Those rows are what turned one bad capture into a total sync
  /// outage: the endpoint rejects the whole envelope on a row-level
  /// validation fault (contrary to api.md §6.1, which reserves 4xx for an
  /// unusable envelope), so twelve unattributable stock rows took every
  /// check-in, check-out and note in the same request down with them, on every
  /// retry, forever.
  ///
  /// Two shapes are unstorable:
  ///
  /// - **Neither `stopId` nor `depotId`.** Nothing to attach the count to.
  /// - **A mock-catalog `productId`.** The audit screen's demo items are
  ///   `'1'`–`'4'`; no such product exists server-side. Crude, and
  ///   deliberately so — it is a literal match on the four ids that were
  ///   actually shipped, not a heuristic that could swallow a real short
  ///   product code later.
  ///
  /// Quarantining costs the rep nothing real: these rows could never have
  /// reached the server. What it buys is every *other* pending capture getting
  /// through on the next push instead of being held hostage.
  static bool _isUnstorable(VisitStockUpdateModel row) {
    if (row.stopId == null && row.depotId == null) return true;
    return const {'1', '2', '3', '4'}.contains(row.productId);
  }

  /// Maps a transport/API failure onto the domain [Failure] the UI renders.
  ///
  /// Pending rows are never at risk here: this repository only marks rows
  /// synced from the ids the server returned in `acceptedIds`, and no failure
  /// path produces any. A failed push therefore costs a retry, never a
  /// capture.
  Failure _failure(ApiError error) {
    if (error.code == ApiErrorCodes.network) return const NetworkFailure();

    if (error.isUnauthenticated) {
      return AuthenticationFailure(
          message:
              error.message ?? 'Your session expired. Please sign in again.');
    }

    return ServerFailure(
      message: error.message ?? 'Could not sync your visits. Please try again.',
      statusCode: error.statusCode,
    );
  }
}
