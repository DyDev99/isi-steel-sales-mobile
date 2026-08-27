// =============================================================================
// customer_repository.dart
//
// Path: lib/features/customer/domain/repositories/customer_repository.dart
//
// Domain-layer contract. The bloc depends ONLY on this — never on Dio, never
// on the local DB. That is what lets you unit-test AddCustomerBloc with a fake.
// =============================================================================

import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_note.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_paged_result.dart';

/// Outcome of a submit attempt.
///
/// `queuedOffline == true` means the record is safely on disk and will sync
/// later — it does NOT mean SAP accepted it. The UI must say so, otherwise a
/// rep writes an order against a customer code that does not exist yet.
class SubmitResult {
  final bool queuedOffline;

  /// Local tracking id. Present in both online and offline cases.
  final String localId;

  /// SAP customer number. Null until HQ approves and SAP assigns it.
  final String? customerCode;

  const SubmitResult({
    required this.localId,
    this.queuedOffline = false,
    this.customerCode,
  });
}

/// Thrown for anything the rep can act on (validation rejected by the
/// middleware, duplicate name, expired session). The bloc surfaces
/// [message] directly.
class CustomerSubmitException implements Exception {
  final String message;
  final String? sapField;

  const CustomerSubmitException(this.message, {this.sapField});

  @override
  String toString() => message;
}

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
