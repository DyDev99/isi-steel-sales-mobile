import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_sync_result.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_sync_scope.dart';

/// Mirrors `order`'s `SyncRepository` shape exactly — the only repository
/// allowed to talk to the remote data source.
abstract interface class RouteSyncRepository {
  ResultFuture<DateTime?> lastSyncedAt();
  ResultFuture<RouteSyncResult> runInitialSync(RouteSyncScope scope);
  ResultFuture<RouteSyncResult> runDeltaSync(RouteSyncScope scope);
}
