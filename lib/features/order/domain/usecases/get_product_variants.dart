import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class GetProductVariants extends UseCase<List<Product>, FamilyIdParams> {
  const GetProductVariants(this._repository);
  final ProductRepository _repository;

  @override
  ResultFuture<List<Product>> call(FamilyIdParams params) =>
      _repository.getProductVariants(params.familyId);
}
