import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/paged_result.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class GetProductsByCategory extends UseCase<PagedResult<Product>, CategoryPageParams> {
  const GetProductsByCategory(this._repository);
  final ProductRepository _repository;

  @override
  ResultFuture<PagedResult<Product>> call(CategoryPageParams params) => _repository.getProductsByCategory(
        categoryId: params.categoryId,
        page: params.page,
        pageSize: params.pageSize,
      );
}
