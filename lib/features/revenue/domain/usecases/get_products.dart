import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/repositories/revenue_repository.dart';

class GetProducts extends UseCase<List<Product>, NoParams> {
  const GetProducts(this._repository);
  final RevenueRepository _repository;

  @override
  ResultFuture<List<Product>> call(NoParams params) =>
      _repository.getProducts();
}
