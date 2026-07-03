import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class RecordViewed extends UseCase<void, ProductIdParams> {
  const RecordViewed(this._repository);
  final ProductRepository _repository;

  @override
  ResultFuture<void> call(ProductIdParams params) => _repository.recordViewed(params.productId);
}
