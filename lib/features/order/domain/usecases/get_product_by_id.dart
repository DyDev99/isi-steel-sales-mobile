import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class GetProductById extends UseCase<Product, ProductIdParams> {
  const GetProductById(this._repository);
  final ProductRepository _repository;

  @override
  ResultFuture<Product> call(ProductIdParams params) =>
      _repository.getProduct(params.productId);
}
