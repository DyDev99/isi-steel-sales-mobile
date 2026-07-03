import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/pending_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';

class FetchPendingOrders extends UseCase<List<PendingOrder>, NoParams> {
  const FetchPendingOrders(this._repository);
  final CartRepository _repository;

  @override
  ResultFuture<List<PendingOrder>> call(NoParams params) => _repository.fetchPendingOrders();
}
