import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/discount_option.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/repositories/revenue_repository.dart';

class GetDiscountOptions extends UseCase<List<DiscountOption>, NoParams> {
  const GetDiscountOptions(this._repository);
  final RevenueRepository _repository;

  @override
  ResultFuture<List<DiscountOption>> call(NoParams params) => _repository.getDiscountOptions();
}
