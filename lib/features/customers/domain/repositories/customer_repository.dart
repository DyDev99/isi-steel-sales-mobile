import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_note.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_paged_result.dart';

/// Read/write against the local customer directory only — this feature
/// never talks to the remote API directly for reads (see
/// `CustomerSyncRepository` for the only door into the remote source).
abstract interface class CustomerRepository {
  ResultFuture<CustomerPagedResult> browse({
    required int page,
    required int pageSize,
    String query = '',
    CustomerFilter filter = const CustomerFilter(),
  });

  ResultFuture<Customer> getById(String id);

  ResultFuture<void> toggleFavorite(String customerId);
  ResultFuture<List<Customer>> fetchFavorites();
  ResultFuture<List<Customer>> fetchRecent();
  ResultFuture<void> recordViewed(String customerId);

  ResultFuture<List<CustomerNote>> fetchNotes(String customerId);
  ResultFuture<void> addNote(String customerId, String body);

  ResultFuture<List<CustomerActivity>> fetchActivities(String customerId);
  ResultFuture<void> addActivity(CustomerActivity activity);
}
