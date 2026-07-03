import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_sync_result.dart';

/// The only door into the remote SAP customer feed. Deliberately separate
/// from [CustomerRepository] — reads always go local, sync is the one path
/// allowed to write a `Customer` row, which is how the "SAP-created only"
/// entry rule is enforced structurally rather than by convention.
abstract interface class CustomerSyncRepository {
  ResultFuture<DateTime?> lastSyncedAt();
  ResultFuture<CustomerSyncResult> runInitialSync();
  ResultFuture<CustomerSyncResult> runDeltaSync();
}
