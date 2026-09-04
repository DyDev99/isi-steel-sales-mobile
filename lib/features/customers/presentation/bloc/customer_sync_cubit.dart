import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/auth/protected_feature.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_profile.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_sync_state.dart';

/// Drives the customer directory's sync banner: runs the initial pull once
/// (first launch, detected via an empty `customer_sync_meta`), and a delta
/// pull on-demand (pull-to-refresh) — same shape as `order`'s `SyncCubit`.
class CustomerSyncCubit extends Cubit<CustomerSyncState> with ProtectedFeature {
  CustomerSyncCubit({
    required RunCustomerInitialSync runInitialSync,
    required RunCustomerDeltaSync runDeltaSync,
    required GetCustomerLastSyncedAt getLastSyncedAt,
    required this.session,
    required AppLogger logger,
  })  : _logger = logger,
        _runInitialSync = runInitialSync,
        _runDeltaSync = runDeltaSync,
        _getLastSyncedAt = getLastSyncedAt,
        super(const CustomerSyncIdle());

  final RunCustomerInitialSync _runInitialSync;
  final RunCustomerDeltaSync _runDeltaSync;
  final GetCustomerLastSyncedAt _getLastSyncedAt;
  final AppLogger _logger;

  /// Supplied by [ProtectedFeature]; the shared gate every protected loader
  /// checks, rather than a rule re-derived here.
  @override
  final SessionManager session;

  /// Either spelling of "may read the customer directory".
  ///
  /// Accepting only `customers.read` blocked the sync for every sales rep on
  /// the running backend, whose role grants `outlets.read` for the same
  /// capability — the client refused a call the user was entitled to make.
  @override
  Set<String> get requiredPermissions => Permissions.canReadCustomers;

  Future<void> syncIfNeeded() async {
    // `/mobile/customers` requires `customers.read`, so a call without a
    // session or without the grant can only ever be rejected — see
    // [ProtectedFeature].
    //
    // Logged rather than returned silently: "no customers appeared and nothing
    // was logged" is indistinguishable from a sync that never ran, and that
    // ambiguity is what sends someone reading this code instead of the log.
    if (!canLoad) {
      _logger.info('customers.sync.skipped', fields: {'reason': blockedReason});
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
      _logger.info('customers.sync.skipped',
          fields: {'reason': blockedReason, 'trigger': 'refresh'});
      return;
    }
    return _run(isInitial: false);
  }

  Future<void> _run({required bool isInitial}) async {
    emit(CustomerSyncInProgress(isInitial: isInitial));
    final result = isInitial
        ? await _runInitialSync(const NoParams())
        : await _runDeltaSync(const NoParams());
    result.when(
      success: (r) => emit(CustomerSyncSucceeded(
          upserted: r.upserted, deleted: r.deleted, syncedAt: r.syncedAt)),
      failure: (f) => emit(CustomerSyncFailed(f.message)),
    );
  }
}
