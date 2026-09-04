import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class ReplaceCart extends UseCase<void, ReplaceCartParams> {
  const ReplaceCart(this._repository);
  final CartRepository _repository;

  @override
  ResultFuture<void> call(ReplaceCartParams params) =>
      _repository.replaceCartWith(params.items,
          editingQuotationId: params.editingQuotationId);
}
