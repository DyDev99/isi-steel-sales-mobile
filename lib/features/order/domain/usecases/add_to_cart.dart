import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';

class AddToCart extends UseCase<void, CartItem> {
  const AddToCart(this._repository);
  final CartRepository _repository;

  @override
  ResultFuture<void> call(CartItem params) => _repository.addItem(params);
}
