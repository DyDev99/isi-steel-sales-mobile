import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/pending_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';

/// Live stream of pending offline orders for the Orders dashboard — emits the
/// current list immediately, then again after every checkout.
class WatchPendingOrders extends StreamUseCase<List<PendingOrder>, NoParams> {
  const WatchPendingOrders(this._repository);
  final CartRepository _repository;

  @override
  Stream<List<PendingOrder>> call(NoParams params) => _repository.watchPendingOrders();
}
