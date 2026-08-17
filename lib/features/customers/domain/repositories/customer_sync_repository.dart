import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_draft.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_sync_result.dart';

/// The only door into the remote SAP customer feed. Deliberately separate
/// from [CustomerRepository] — reads always go local, sync is the one path
/// allowed to write a `Customer` row, which is how the "SAP-created only"
/// entry rule is enforced structurally rather than by convention.
abstract interface class CustomerSyncRepository {
  ResultFuture<DateTime?> lastSyncedAt();
  ResultFuture<CustomerSyncResult> runInitialSync();
  ResultFuture<CustomerSyncResult> runDeltaSync();

  /// Fetches the full aggregate for one customer and writes it to the local
  /// cache, so the detail screen keeps reading locally like every other view.
  ///
  /// The list DTO the sync loop stores is about a fifth of a customer — no
  /// street address, no contacts, no SAP block, no metric cache. This fills
  /// those in on demand rather than paying for them on every row of every
  /// page.
  ///
  /// Best-effort by design: the detail screen must still render from cache
  /// when this fails, because a rep standing in a shop with no signal needs
  /// the customer record more than anyone.
  ResultFuture<void> hydrateCustomer(String id);

  /// Registers a new customer and stores the server's version of it.
  ///
  /// The one path by which a `Customer` row is created rather than synced. It
  /// still goes through this repository because the row must land in the local
  /// cache the same way every other one does — the rep expects the shop they
  /// just registered to appear in their list immediately.
  ///
  /// **The server's response is what gets stored, not the draft.** It carries
  /// the assigned id, the `Draft` status and the SAP block the client is not
  /// allowed to set; persisting the draft instead would put a customer in the
  /// cache that the server would contradict on the next sync.
  ResultFuture<Customer> createCustomer(CustomerDraft draft);
}
