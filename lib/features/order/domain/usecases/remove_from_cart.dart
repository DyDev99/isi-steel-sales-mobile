import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class RemoveFromCart extends UseCase<void, CartItemIdParams> {
  const RemoveFromCart(this._repository);
  final CartRepository _repository;

  @override
  ResultFuture<void> call(CartItemIdParams params) => _repository.removeItem(params.cartItemId);
}
