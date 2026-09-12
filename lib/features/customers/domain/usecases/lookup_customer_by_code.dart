import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_code_lookup.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_sync_repository.dart';

/// Resolves a customer number that is not in the rep's local book.
///
/// The one customer read that is allowed to leave the device, and only on an
/// explicit full-code lookup — a number the rep typed or scanned. The browse
/// and search paths stay local by design.
class LookupCustomerByCode extends UseCase<CustomerCodeLookup, String> {
  const LookupCustomerByCode(this._repository);
  final CustomerSyncRepository _repository;

  @override
  ResultFuture<CustomerCodeLookup> call(String code) =>
      _repository.lookupByCode(code);
}
