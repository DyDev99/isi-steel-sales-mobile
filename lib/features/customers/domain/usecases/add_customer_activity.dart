import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';

class AddCustomerActivity extends UseCase<void, AddCustomerActivityParams> {
  const AddCustomerActivity(this._repository);
  final CustomerRepository _repository;

  @override
  ResultFuture<void> call(AddCustomerActivityParams params) => _repository.addActivity(params.activity);
}
