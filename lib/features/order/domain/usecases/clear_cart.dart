import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';

class ClearCart extends UseCase<void, NoParams> {
  const ClearCart(this._repository);
  final CartRepository _repository;

  @override
  ResultFuture<void> call(NoParams params) => _repository.clearCart();
}
