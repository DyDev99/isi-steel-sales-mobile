import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';

class GetCustomerById extends UseCase<Customer, CustomerIdParams> {
  const GetCustomerById(this._repository);
  final CustomerRepository _repository;

  @override
  ResultFuture<Customer> call(CustomerIdParams params) =>
      _repository.getById(params.customerId);
}
