import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sales_order.dart';

abstract interface class SalesOrderRepository {
  ResultFuture<SalesOrder> createFromQuotation(Quotation quotation,
      {required List<CartItem> items});

  ResultFuture<SalesOrder?> getSalesOrderById(String id);

  Stream<List<SalesOrder>> watchSalesOrders();
}
