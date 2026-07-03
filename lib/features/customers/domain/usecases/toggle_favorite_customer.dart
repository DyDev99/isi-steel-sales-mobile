import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';

class ToggleFavoriteCustomer extends UseCase<void, CustomerIdParams> {
  const ToggleFavoriteCustomer(this._repository);
  final CustomerRepository _repository;

  @override
  ResultFuture<void> call(CustomerIdParams params) => _repository.toggleFavorite(params.customerId);
}
