import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_sync_scope.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_route_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/run_route_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/run_route_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/route_sync_state.dart';

/// Mirrors `order`'s `SyncCubit` shape exactly.
class RouteSyncCubit extends Cubit<RouteSyncState> {
  RouteSyncCubit({
    required RunRouteInitialSync runInitialSync,
    required RunRouteDeltaSync runDeltaSync,
    required GetRouteLastSyncedAt getLastSyncedAt,
    required SessionManager sessionManager,
  })  : _runInitialSync = runInitialSync,
        _runDeltaSync = runDeltaSync,
        _getLastSyncedAt = getLastSyncedAt,
        _sessionManager = sessionManager,
        super(const RouteSyncIdle());

  final RunRouteInitialSync _runInitialSync;
  final RunRouteDeltaSync _runDeltaSync;
  final GetRouteLastSyncedAt _getLastSyncedAt;
  final SessionManager _sessionManager;

  Future<void> syncIfNeeded() async {
    final lastSynced = await _getLastSyncedAt(const NoParams());
    final needsInitial = lastSynced.when(success: (at) => at == null, failure: (_) => true);
    if (needsInitial) await _run(isInitial: true);
  }

  Future<void> refresh() => _run(isInitial: false);

  Future<void> _run({required bool isInitial}) async {
    emit(RouteSyncInProgress(isInitial: isInitial));
    final scope = RouteSyncScope.forCurrentUser(_sessionManager);
    final result = isInitial ? await _runInitialSync(scope) : await _runDeltaSync(scope);
    result.when(
      success: (r) => emit(RouteSyncSucceeded(upserted: r.upserted, syncedAt: r.syncedAt)),
      failure: (f) => emit(RouteSyncFailed(f.message)),
    );
  }
}
