import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/pending_order.dart';

abstract interface class CartRepository {
  ResultFuture<List<CartItem>> fetchCart();
  ResultFuture<void> addItem(CartItem item);
  ResultFuture<void> updateItem(CartItem item);
  ResultFuture<void> removeItem(String cartItemId);
  ResultFuture<void> clearCart();

  /// Writes a `pending_orders` row from the current cart and clears it —
  /// works fully offline, the row is picked up by a future Order-sync
  /// pipeline (out of scope here beyond the stub entry point).
  ResultFuture<PendingOrder> checkout({String? leadId});
  ResultFuture<List<PendingOrder>> fetchPendingOrders();

  /// Live stream of pending (offline) orders: emits the current list on listen,
  /// then re-emits whenever an order is checked out — so the Orders dashboard
  /// updates the moment a quote/order is placed, no manual reload.
  Stream<List<PendingOrder>> watchPendingOrders();
}
