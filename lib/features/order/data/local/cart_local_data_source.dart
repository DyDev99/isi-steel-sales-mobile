import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_database.dart';
import 'package:sqflite/sqflite.dart';

/// Only owns the `cart_items`/`pending_orders` tables — [CartRepositoryImpl]
/// composes this with [ProductLocalDataSource] to rehydrate full [CartItem]s,
/// so product-joining logic isn't duplicated here.
abstract interface class CartLocalDataSource {
  Future<List<DataMap>> fetchCartRows();
  Future<void> upsertItem(DataMap row);
  Future<void> removeItem(String id);
  Future<void> clearCart();

  Future<void> insertPendingOrder(DataMap row);
  Future<List<DataMap>> fetchPendingOrders();
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  const CartLocalDataSourceImpl(this._catalogDb);
  final CatalogDatabase _catalogDb;
  Database get _db => _catalogDb.db;

  @override
  Future<List<DataMap>> fetchCartRows() async {
    try {
      return _db.query('cart_items', orderBy: 'created_at ASC');
    } catch (e) {
      throw CacheException(message: 'Failed to load cart: $e');
    }
  }

  @override
  Future<void> upsertItem(DataMap row) async {
    try {
      await _db.insert('cart_items', row, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save cart item: $e');
    }
  }

  @override
  Future<void> removeItem(String id) async {
    try {
      await _db.delete('cart_items', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw CacheException(message: 'Failed to remove cart item: $e');
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      await _db.delete('cart_items');
    } catch (e) {
      throw CacheException(message: 'Failed to clear cart: $e');
    }
  }

  @override
  Future<void> insertPendingOrder(DataMap row) async {
    try {
      await _db.insert('pending_orders', row);
    } catch (e) {
      throw CacheException(message: 'Failed to save order: $e');
    }
  }

  @override
  Future<List<DataMap>> fetchPendingOrders() async {
    try {
      return _db.query('pending_orders', orderBy: 'created_at DESC');
    } catch (e) {
      throw CacheException(message: 'Failed to load orders: $e');
    }
  }
}
