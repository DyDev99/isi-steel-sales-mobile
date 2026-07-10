import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/customer_credit.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/repositories/revenue_repository.dart';

class GetCustomerCredit extends UseCase<CustomerCredit, NoParams> {
  const GetCustomerCredit(this._repository);
  final RevenueRepository _repository;

  @override
  ResultFuture<CustomerCredit> call(NoParams params) =>
      _repository.getCustomerCredit();
}
