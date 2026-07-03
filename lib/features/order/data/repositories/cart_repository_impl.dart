import 'dart:convert';
import 'dart:math';

import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/cart_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/product_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/pending_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';

const _taxRate = 0.10;

/// Composes [CartLocalDataSource] (cart_items/pending_orders tables) with
/// [ProductLocalDataSource] to rehydrate full [CartItem]s — product-joining
/// logic isn't duplicated here.
class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl({required CartLocalDataSource cartLocal, required ProductLocalDataSource productLocal})
      : _cartLocal = cartLocal,
        _productLocal = productLocal;

  final CartLocalDataSource _cartLocal;
  final ProductLocalDataSource _productLocal;

  @override
  ResultFuture<List<CartItem>> fetchCart() async {
    try {
      return Success(await _hydrateCartRows(await _cartLocal.fetchCartRows()));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> addItem(CartItem item) => _saveItem(item);

  @override
  ResultFuture<void> updateItem(CartItem item) => _saveItem(item);

  ResultFuture<void> _saveItem(CartItem item) async {
    try {
      await _cartLocal.upsertItem({
        'id': item.id,
        'product_id': item.product.id,
        'quantity': item.quantity,
        'unit': item.unit,
        'discount_percent': item.discountPercent,
        'lead_id': item.leadId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> removeItem(String cartItemId) async {
    try {
      await _cartLocal.removeItem(cartItemId);
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> clearCart() async {
    try {
      await _cartLocal.clearCart();
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<PendingOrder> checkout({String? leadId}) async {
    try {
      final items = await _hydrateCartRows(await _cartLocal.fetchCartRows());
      if (items.isEmpty) {
        return const Failed(CacheFailure(message: 'Cart is empty.'));
      }

      final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineSubtotal);
      final discount = items.fold<double>(0, (sum, i) => sum + i.lineDiscount);
      final taxable = subtotal - discount;
      final tax = taxable * _taxRate;
      final total = taxable + tax;

      final order = PendingOrder(
        id: _newId(),
        items: items,
        subtotal: subtotal,
        tax: tax,
        discount: discount,
        total: total,
        status: PendingOrderStatus.pendingSync,
        createdAt: DateTime.now(),
        leadId: leadId,
      );

      await _cartLocal.insertPendingOrder({
        'id': order.id,
        'lead_id': order.leadId,
        'items_json': jsonEncode(items
            .map((i) => {
                  'productId': i.product.id,
                  'quantity': i.quantity,
                  'unit': i.unit,
                  'discountPercent': i.discountPercent,
                })
            .toList()),
        'subtotal': order.subtotal,
        'tax': order.tax,
        'discount': order.discount,
        'total': order.total,
        'status': order.status.name,
        'created_at': order.createdAt.toIso8601String(),
      });
      await _cartLocal.clearCart();
      return Success(order);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<PendingOrder>> fetchPendingOrders() async {
    try {
      final rows = await _cartLocal.fetchPendingOrders();
      final orders = <PendingOrder>[];
      for (final row in rows) {
        final rawItems = (jsonDecode(row['items_json'] as String) as List).cast<DataMap>();
        final items = <CartItem>[];
        for (final raw in rawItems) {
          final product = await _productLocal.getById(raw['productId'] as String);
          if (product == null) continue;
          items.add(CartItem(
            id: '${row['id']}_${raw['productId']}',
            product: product,
            quantity: (raw['quantity'] as num).toDouble(),
            unit: raw['unit'] as String,
            discountPercent: (raw['discountPercent'] as num).toDouble(),
            leadId: row['lead_id'] as String?,
          ));
        }
        orders.add(PendingOrder(
          id: row['id'] as String,
          items: items,
          subtotal: (row['subtotal'] as num).toDouble(),
          tax: (row['tax'] as num).toDouble(),
          discount: (row['discount'] as num).toDouble(),
          total: (row['total'] as num).toDouble(),
          status: PendingOrderStatus.values.firstWhere((s) => s.name == row['status']),
          createdAt: DateTime.parse(row['created_at'] as String),
          leadId: row['lead_id'] as String?,
        ));
      }
      return Success(orders);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  Future<List<CartItem>> _hydrateCartRows(List<DataMap> rows) async {
    final items = <CartItem>[];
    for (final row in rows) {
      final product = await _productLocal.getById(row['product_id'] as String);
      if (product == null) continue;
      items.add(CartItem(
        id: row['id'] as String,
        product: product,
        quantity: (row['quantity'] as num).toDouble(),
        unit: row['unit'] as String,
        discountPercent: (row['discount_percent'] as num).toDouble(),
        leadId: row['lead_id'] as String?,
      ));
    }
    return items;
  }

  static String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';
}
