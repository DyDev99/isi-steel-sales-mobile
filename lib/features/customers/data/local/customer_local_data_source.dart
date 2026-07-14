import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_activity_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_note_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';

/// Local persistence contract for the customer directory. Backed by the single
/// encrypted Drift database (see [CustomerDriftLocalDataSource]); the legacy
/// plaintext `customers.db` implementation was retired in the T2 cutover.
abstract interface class CustomerLocalDataSource {
  /// Returns up to `pageSize + 1` rows so the caller can detect "has more"
  /// without a separate COUNT query.
  Future<List<CustomerModel>> browse({
    required int page,
    required int pageSize,
    String query,
    CustomerFilter filter,
  });

  Future<CustomerModel?> getById(String id);

  Future<void> toggleFavorite(String customerId);
  Future<List<CustomerModel>> fetchFavorites();
  Future<List<CustomerModel>> fetchRecent();
  Future<void> recordViewed(String customerId);

  Future<List<CustomerNoteModel>> fetchNotes(String customerId);
  Future<void> addNote(CustomerNoteModel note);

  Future<List<CustomerActivityModel>> fetchActivities(String customerId);
  Future<void> addActivity(CustomerActivityModel activity);

  /// Batched, transactional upsert into the customer + contact tables. The only
  /// write path that may populate `customers` — called exclusively by the sync
  /// repository.
  Future<void> upsertCustomers(List<CustomerModel> customers);
  Future<void> markDeleted(List<String> ids);

  Future<DateTime?> getLastSyncedAt(String entity);
  Future<void> setLastSyncedAt(String entity, DateTime at);
}
