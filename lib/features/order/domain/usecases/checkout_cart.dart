import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/pending_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class CheckoutCart extends UseCase<PendingOrder, CheckoutParams> {
  const CheckoutCart(this._repository);
  final CartRepository _repository;

  @override
  ResultFuture<PendingOrder> call(CheckoutParams params) =>
      _repository.checkout(leadId: params.leadId);
}
