import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sales_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sales_order_repository.dart';

class WatchSalesOrders extends StreamUseCase<List<SalesOrder>, NoParams> {
  const WatchSalesOrders(this._repository);
  final SalesOrderRepository _repository;

  @override
  Stream<List<SalesOrder>> call(NoParams params) => _repository.watchSalesOrders();
}
