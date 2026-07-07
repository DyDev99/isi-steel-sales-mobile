import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sales_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sales_order_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class CreateSalesOrder extends UseCase<SalesOrder, CreateSalesOrderParams> {
  const CreateSalesOrder(this._repository);
  final SalesOrderRepository _repository;

  @override
  ResultFuture<SalesOrder> call(CreateSalesOrderParams params) =>
      _repository.createFromQuotation(params.quotation, items: params.items);
}
