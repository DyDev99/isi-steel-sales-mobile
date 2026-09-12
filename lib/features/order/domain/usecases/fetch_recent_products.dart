import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';

class FetchRecentProducts extends UseCase<List<Product>, NoParams> {
  const FetchRecentProducts(this._repository);
  final ProductRepository _repository;

  @override
  ResultFuture<List<Product>> call(NoParams params) =>
      _repository.fetchRecent();
}
