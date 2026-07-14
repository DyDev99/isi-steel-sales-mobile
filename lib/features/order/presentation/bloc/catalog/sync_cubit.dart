import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/storage/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sync_scope.dart';
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
    required SessionManager sessionManager,
  })  : _runInitialSync = runInitialSync,
        _runDeltaSync = runDeltaSync,
        _getLastSyncedAt = getLastSyncedAt,
        _sessionManager = sessionManager,
        super(const SyncIdle());

  final RunInitialSync _runInitialSync;
  final RunDeltaSync _runDeltaSync;
  final GetLastSyncedAt _getLastSyncedAt;
  final SessionManager _sessionManager;

  Future<void> syncIfNeeded() async {
    final lastSynced = await _getLastSyncedAt(const NoParams());
    final needsInitial =
        lastSynced.when(success: (at) => at == null, failure: (_) => true);
    if (needsInitial) {
      await _run(isInitial: true);
    }
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
