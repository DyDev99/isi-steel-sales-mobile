import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_draft.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_sync_repository.dart';

/// Registers a shop the rep visited.
///
/// Goes through [CustomerSyncRepository] rather than `CustomerRepository`
/// because it writes: reads are local-only, and the sync repository is the one
/// door to the network. The created customer lands in `Draft` and cannot trade
/// until someone holding `customers.approve` activates it.
class CreateCustomer extends UseCase<Customer, CustomerDraft> {
  const CreateCustomer(this._repository);

  final CustomerSyncRepository _repository;

  @override
  ResultFuture<Customer> call(CustomerDraft params) =>
      _repository.createCustomer(params);
}
