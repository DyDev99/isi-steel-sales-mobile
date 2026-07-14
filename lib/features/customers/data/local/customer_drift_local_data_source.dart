import 'package:isi_steel_sales_mobile/core/storage/database/drift/daos/customer_dao.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_drift_mappers.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_activity_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_note_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';

/// [CustomerLocalDataSource] backed by the single encrypted Drift database
/// (T2 cutover). Replaces the per-feature plaintext `customers.db`. Exceptions
/// are normalised to [CacheException] so the repository above is unaffected by
/// the storage swap.
class CustomerDriftLocalDataSource implements CustomerLocalDataSource {
  const CustomerDriftLocalDataSource(this._dao);

  final CustomerDao _dao;

  @override
  Future<List<CustomerModel>> browse({
    required int page,
    required int pageSize,
    String query = '',
    CustomerFilter filter = const CustomerFilter(),
  }) async {
    try {
      final rows = await _dao.browse(
        page: page,
        pageSize: pageSize,
        query: query,
        territory: filter.territory,
        status: filter.status?.name,
        productCategory: filter.productCategory,
        sort: filter.sortBy.toBrowseSort(),
      );
      return rows.map((r) => r.toModel()).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to browse customers: $e');
    }
  }

  @override
  Future<CustomerModel?> getById(String id) async {
    try {
      final row = await _dao.getById(id);
      if (row == null) return null;
      final contacts = await _dao.fetchContacts(id);
      return row.toModel(contacts: contacts.map((c) => c.toModel()).toList());
    } catch (e) {
      throw CacheException(message: 'Failed to load customer $id: $e');
    }
  }

  @override
  Future<void> toggleFavorite(String customerId) async {
    try {
      await _dao.toggleFavorite(customerId);
    } catch (e) {
      throw CacheException(message: 'Failed to toggle favorite: $e');
    }
  }

  @override
  Future<List<CustomerModel>> fetchFavorites() async {
    try {
      final rows = await _dao.fetchFavorites();
      return rows.map((r) => r.toModel()).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load favorite customers: $e');
    }
  }

  @override
  Future<List<CustomerModel>> fetchRecent() async {
    try {
      final rows = await _dao.fetchRecent();
      return rows.map((r) => r.toModel()).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load recent customers: $e');
    }
  }

  @override
  Future<void> recordViewed(String customerId) async {
    try {
      await _dao.recordViewed(customerId);
    } catch (e) {
      throw CacheException(message: 'Failed to record viewed customer: $e');
    }
  }

  @override
  Future<List<CustomerNoteModel>> fetchNotes(String customerId) async {
    try {
      final rows = await _dao.fetchNotes(customerId);
      return rows.map((r) => r.toModel()).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load notes: $e');
    }
  }

  @override
  Future<void> addNote(CustomerNoteModel note) async {
    try {
      await _dao.addNote(note.toCompanion());
    } catch (e) {
      throw CacheException(message: 'Failed to save note: $e');
    }
  }

  @override
  Future<List<CustomerActivityModel>> fetchActivities(String customerId) async {
    try {
      final rows = await _dao.fetchActivities(customerId);
      return rows.map((r) => r.toModel()).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load activities: $e');
    }
  }

  @override
  Future<void> addActivity(CustomerActivityModel activity) async {
    try {
      await _dao.addActivity(activity.toCompanion());
    } catch (e) {
      throw CacheException(message: 'Failed to save activity: $e');
    }
  }

  @override
  Future<void> upsertCustomers(List<CustomerModel> customers) async {
    try {
      await _dao.upsertCustomers(customers.map((c) => c.toRecord()).toList());
    } catch (e) {
      throw CacheException(message: 'Failed to save synced customers: $e');
    }
  }

  @override
  Future<void> markDeleted(List<String> ids) async {
    try {
      await _dao.markDeleted(ids);
    } catch (e) {
      throw CacheException(message: 'Failed to apply deletions: $e');
    }
  }

  @override
  Future<DateTime?> getLastSyncedAt(String entity) async {
    try {
      return await _dao.getLastSyncedAt(entity);
    } catch (e) {
      throw CacheException(message: 'Failed to read sync metadata: $e');
    }
  }

  @override
  Future<void> setLastSyncedAt(String entity, DateTime at) async {
    try {
      await _dao.setLastSyncedAt(entity, at);
    } catch (e) {
      throw CacheException(message: 'Failed to write sync metadata: $e');
    }
  }
}
