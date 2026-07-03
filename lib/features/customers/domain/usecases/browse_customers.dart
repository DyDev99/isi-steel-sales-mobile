import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_paged_result.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/customer_repository.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';

class BrowseCustomers extends UseCase<CustomerPagedResult, BrowseCustomersParams> {
  const BrowseCustomers(this._repository);
  final CustomerRepository _repository;

  @override
  ResultFuture<CustomerPagedResult> call(BrowseCustomersParams params) => _repository.browse(
        page: params.page,
        pageSize: params.pageSize,
        query: params.query,
        filter: params.filter,
      );
}
