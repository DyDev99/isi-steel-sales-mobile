import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class GetPricing extends UseCase<double, PricingParams> {
  const GetPricing(this._repository);
  final ProductRepository _repository;

  @override
  ResultFuture<double> call(PricingParams params) =>
      _repository.getPricing(params.productId, params.tier);
}
