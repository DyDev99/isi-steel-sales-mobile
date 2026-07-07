import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product_category.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/repositories/revenue_repository.dart';

class GetCategories extends UseCase<List<ProductCategory>, NoParams> {
  const GetCategories(this._repository);
  final RevenueRepository _repository;

  @override
  ResultFuture<List<ProductCategory>> call(NoParams params) => _repository.getCategories();
}
