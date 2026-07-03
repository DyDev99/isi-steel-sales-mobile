import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_repository.dart';

class FetchFavoriteCustomers extends UseCase<List<Customer>, NoParams> {
  const FetchFavoriteCustomers(this._repository);
  final CustomerRepository _repository;

  @override
  ResultFuture<List<Customer>> call(NoParams params) => _repository.fetchFavorites();
}
