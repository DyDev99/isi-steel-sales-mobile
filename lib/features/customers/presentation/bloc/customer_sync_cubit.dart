import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_sync_state.dart';

/// Drives the customer directory's sync banner: runs the initial pull once
/// (first launch, detected via an empty `customer_sync_meta`), and a delta
/// pull on-demand (pull-to-refresh) — same shape as `order`'s `SyncCubit`.
class CustomerSyncCubit extends Cubit<CustomerSyncState> {
  CustomerSyncCubit({
    required RunCustomerInitialSync runInitialSync,
    required RunCustomerDeltaSync runDeltaSync,
    required GetCustomerLastSyncedAt getLastSyncedAt,
  })  : _runInitialSync = runInitialSync,
        _runDeltaSync = runDeltaSync,
        _getLastSyncedAt = getLastSyncedAt,
        super(const CustomerSyncIdle());

  final RunCustomerInitialSync _runInitialSync;
  final RunCustomerDeltaSync _runDeltaSync;
  final GetCustomerLastSyncedAt _getLastSyncedAt;

  Future<void> syncIfNeeded() async {
    final lastSynced = await _getLastSyncedAt(const NoParams());
    final needsInitial =
        lastSynced.when(success: (at) => at == null, failure: (_) => true);
    if (needsInitial) await _run(isInitial: true);
  }

  Future<void> refresh() => _run(isInitial: false);

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
