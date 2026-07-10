import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_activity_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_note_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_note.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_paged_result.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_repository.dart';

/// Local-read only, same shape as `order`'s `ProductRepositoryImpl` — this
/// repository never touches the network; that door is `CustomerSyncRepository`.
class CustomerRepositoryImpl implements CustomerRepository {
  const CustomerRepositoryImpl(this._local);
  final CustomerLocalDataSource _local;

  @override
  ResultFuture<CustomerPagedResult> browse({
    required int page,
    required int pageSize,
    String query = '',
    CustomerFilter filter = const CustomerFilter(),
  }) async {
    try {
      final rows = await _local.browse(
          page: page, pageSize: pageSize, query: query, filter: filter);
      final hasMore = rows.length > pageSize;
      final items = hasMore ? rows.sublist(0, pageSize) : rows;
      return Success(
          CustomerPagedResult(items: items, page: page, hasMore: hasMore));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<Customer> getById(String id) async {
    try {
      final customer = await _local.getById(id);
      if (customer == null) {
        return const Failed(CacheFailure(message: 'Customer not found.'));
      }
      return Success(customer);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> toggleFavorite(String customerId) async {
    try {
      await _local.toggleFavorite(customerId);
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<Customer>> fetchFavorites() async {
    try {
      return Success(await _local.fetchFavorites());
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<Customer>> fetchRecent() async {
    try {
      return Success(await _local.fetchRecent());
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> recordViewed(String customerId) async {
    try {
      await _local.recordViewed(customerId);
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<CustomerNote>> fetchNotes(String customerId) async {
    try {
      return Success(await _local.fetchNotes(customerId));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> addNote(String customerId, String body) async {
    try {
      await _local.addNote(CustomerNoteModel(
        id: '$customerId-NOTE-${DateTime.now().microsecondsSinceEpoch}',
        customerId: customerId,
        body: body,
        createdAt: DateTime.now(),
      ));
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<CustomerActivity>> fetchActivities(
      String customerId) async {
    try {
      return Success(await _local.fetchActivities(customerId));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> addActivity(CustomerActivity activity) async {
    try {
      await _local.addActivity(CustomerActivityModel(
        id: activity.id,
        customerId: activity.customerId,
        type: activity.type,
        summary: activity.summary,
        createdAt: activity.createdAt,
      ));
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }
}
