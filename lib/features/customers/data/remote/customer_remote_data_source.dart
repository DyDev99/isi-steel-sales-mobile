import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_sync_page.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_draft.dart';

/// The SAP customer master, as seen from the mobile app. Only ever called
/// by the sync repository — this is intentionally the single choke point
/// through which a `Customer` row can come into existence locally.
abstract interface class CustomerRemoteDataSource {
  Future<CustomerInitialPage> fetchInitial({
    required int page,
    required int pageSize,
  });

  /// Records changed at or after [since], **including tombstones**.
  ///
  /// [page] exists because a delta pages like any other list: a rep returning
  /// from a week offline can easily exceed one page of changes.
  Future<CustomerDeltaPage> fetchDelta({
    required DateTime since,
    int page,
    int pageSize,
  });

  /// The full aggregate for one customer, which the list DTO deliberately does
  /// not carry — contacts, the SAP block, the street address and the metric
  /// cache all arrive here.
  Future<CustomerModel> fetchById(String id);

  /// Registers a new customer — `POST /mobile/customers`, 201.
  ///
  /// The one exception to "a Customer row only ever comes from SAP": a rep
  /// registering a shop in the field creates it here, and it lands in `Draft`
  /// where it cannot trade until someone holding `customers.approve` activates
  /// it. Requires `customers.create`; a rep without it gets 403.
  Future<CustomerModel> create(CustomerDraft draft);
}
