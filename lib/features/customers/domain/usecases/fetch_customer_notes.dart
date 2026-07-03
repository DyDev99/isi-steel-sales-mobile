import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_note.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';

class FetchCustomerNotes extends UseCase<List<CustomerNote>, CustomerIdParams> {
  const FetchCustomerNotes(this._repository);
  final CustomerRepository _repository;

  @override
  ResultFuture<List<CustomerNote>> call(CustomerIdParams params) => _repository.fetchNotes(params.customerId);
}
