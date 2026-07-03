import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class GetWarehouseStock extends UseCase<List<Product>, ProductCodeParams> {
  const GetWarehouseStock(this._repository);
  final ProductRepository _repository;

  @override
  ResultFuture<List<Product>> call(ProductCodeParams params) =>
      _repository.getWarehouseStock(params.code);
}
