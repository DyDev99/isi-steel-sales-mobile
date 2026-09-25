import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/auth/protected_feature.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_profile.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/get_depot_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/run_depot_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/usecases/run_depot_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/depots/presentation/bloc/depot_sync_state.dart';

/// Drives the depot directory's sync banner: runs the initial pull once
/// (first launch, detected via an empty `depot_sync_meta`), and a delta
/// pull on-demand (pull-to-refresh) — same shape as `order`'s `SyncCubit`.
class DepotSyncCubit extends Cubit<DepotSyncState> with ProtectedFeature {
  DepotSyncCubit({
    required RunDepotInitialSync runInitialSync,
    required RunDepotDeltaSync runDeltaSync,
    required GetDepotLastSyncedAt getLastSyncedAt,
    required this.session,
    required AppLogger logger,
  })  : _logger = logger,
        _runInitialSync = runInitialSync,
        _runDeltaSync = runDeltaSync,
        _getLastSyncedAt = getLastSyncedAt,
        super(const DepotSyncIdle());

  final RunDepotInitialSync _runInitialSync;
  final RunDepotDeltaSync _runDeltaSync;
  final GetDepotLastSyncedAt _getLastSyncedAt;
  final AppLogger _logger;

  /// Supplied by [ProtectedFeature]; the shared gate every protected loader
  /// checks, rather than a rule re-derived here.
  @override
  final SessionManager session;

  /// Either spelling of "may read the depot directory".
  ///
  /// Accepting only `depots.read` blocked the sync for every sales rep on
  /// the running backend, whose role grants `outlets.read` for the same
  /// capability — the client refused a call the user was entitled to make.
  @override
  Set<String> get requiredPermissions => Permissions.canReadDepots;

  Future<void> syncIfNeeded() async {
    // `/mobile/depots` requires `depots.read`, so a call without a
    // session or without the grant can only ever be rejected — see
    // [ProtectedFeature].
    //
    // Logged rather than returned silently: "no depots appeared and nothing
    // was logged" is indistinguishable from a sync that never ran, and that
    // ambiguity is what sends someone reading this code instead of the log.
    if (!canLoad) {
      _logger.info('depots.sync.skipped', fields: {'reason': blockedReason});
      return;
    }

    final lastSynced = await _getLastSyncedAt(const NoParams());
    final needsInitial =
        lastSynced.when(success: (at) => at == null, failure: (_) => true);
    if (needsInitial) await _run(isInitial: true);
  }

  /// Pull-to-refresh. Also gated: an explicit gesture still cannot succeed
  /// without a session, and silently doing nothing beats a spurious error.
  Future<void> refresh() async {
    if (!canLoad) {
      _logger.info('depots.sync.skipped',
          fields: {'reason': blockedReason, 'trigger': 'refresh'});
      return;
    }
    return _run(isInitial: false);
  }

  Future<void> _run({required bool isInitial}) async {
    emit(DepotSyncInProgress(isInitial: isInitial));
    final result = isInitial
        ? await _runInitialSync(const NoParams())
        : await _runDeltaSync(const NoParams());
    result.when(
      success: (r) => emit(DepotSyncSucceeded(
          upserted: r.upserted, deleted: r.deleted, syncedAt: r.syncedAt)),
      failure: (f) => emit(DepotSyncFailed(f.message)),
    );
  }
}
