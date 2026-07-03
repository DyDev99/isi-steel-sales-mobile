import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';

class FetchCustomerActivities extends UseCase<List<CustomerActivity>, CustomerIdParams> {
  const FetchCustomerActivities(this._repository);
  final CustomerRepository _repository;

  @override
  ResultFuture<List<CustomerActivity>> call(CustomerIdParams params) =>
      _repository.fetchActivities(params.customerId);
}
