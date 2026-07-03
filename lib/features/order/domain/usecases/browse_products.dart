import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/paged_result.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class BrowseProducts extends UseCase<PagedResult<Product>, BrowseProductsParams> {
  const BrowseProducts(this._repository);
  final ProductRepository _repository;

  @override
  ResultFuture<PagedResult<Product>> call(BrowseProductsParams params) => params.query.isEmpty
      ? _repository.getProducts(page: params.page, pageSize: params.pageSize, filter: params.filter)
      : _repository.searchProducts(
          page: params.page,
          pageSize: params.pageSize,
          query: params.query,
          filter: params.filter,
        );
}
