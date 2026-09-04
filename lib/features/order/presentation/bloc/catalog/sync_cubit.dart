import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_scope.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/count_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/run_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/run_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_state.dart';

/// Drives the sync progress banner: runs the initial pull once (first
/// launch, detected via an empty `sync_meta`), and a delta pull on-demand
/// (catalog pull-to-refresh).
class SyncCubit extends Cubit<SyncState> {
  SyncCubit({
    required RunInitialSync runInitialSync,
    required RunDeltaSync runDeltaSync,
    required GetLastSyncedAt getLastSyncedAt,
    required CountProducts countProducts,
    required SessionManager sessionManager,
  })  : _runInitialSync = runInitialSync,
        _runDeltaSync = runDeltaSync,
        _getLastSyncedAt = getLastSyncedAt,
        _countProducts = countProducts,
        _sessionManager = sessionManager,
        super(const SyncIdle());

  final RunInitialSync _runInitialSync;
  final RunDeltaSync _runDeltaSync;
  final GetLastSyncedAt _getLastSyncedAt;
  final CountProducts _countProducts;
  final SessionManager _sessionManager;

  /// Runs the initial pull when the device has never synced **or** when it has
  /// a sync timestamp but no catalog behind it.
  ///
  /// The timestamp alone is not enough evidence. A device that synced under a
  /// previous taxonomy, or whose catalog was cleared by a migration, carries a
  /// perfectly good "last synced" date over an empty products table — and the
  /// old check read that as "nothing to do", leaving the rep on an empty
  /// category picker with no way to recover. When the timestamp and the
  /// catalog disagree, the catalog wins.
  Future<void> syncIfNeeded() async {
    final lastSynced = await _getLastSyncedAt(const NoParams());
    final neverSynced =
        lastSynced.when(success: (at) => at == null, failure: (_) => true);

    if (neverSynced) return _run(isInitial: true);

    final count = await _countProducts(
      const BrowseProductsParams(page: 0, pageSize: 1),
    );
    final catalogEmpty =
        count.when(success: (n) => n == 0, failure: (_) => false);
    if (catalogEmpty) await _run(isInitial: true);
  }

  Future<void> refresh() => _run(isInitial: false);

  Future<void> _run({required bool isInitial}) async {
    emit(SyncInProgress(isInitial: isInitial));
    final scope = SyncScope.forCurrentUser(_sessionManager);
    final result =
        isInitial ? await _runInitialSync(scope) : await _runDeltaSync(scope);
    result.when(
      success: (r) => emit(SyncSucceeded(
          upserted: r.upserted, deleted: r.deleted, syncedAt: r.syncedAt)),
      failure: (f) => emit(SyncFailed(f.message)),
    );
  }
}
