import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_database.dart';
import 'package:sqflite/sqflite.dart';

/// Only owns the `cart_items` table — [CartRepositoryImpl] composes this
/// with [ProductLocalDataSource] to rehydrate full [CartItem]s, so
/// product-joining logic isn't duplicated here.
abstract interface class CartLocalDataSource {
  Future<List<DataMap>> fetchCartRows();
  Future<void> upsertItem(DataMap row);
  Future<void> removeItem(String id);
  Future<void> clearCart();

  /// Clears `cart_items` and batch-inserts [rows] in one transaction — used
  /// to seed the cart from a `Quotation`/`SalesOrder` rather than one-by-one
  /// upserts.
  Future<void> replaceCart(List<DataMap> rows);
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
      await _db.insert('cart_items', row,
          conflictAlgorithm: ConflictAlgorithm.replace);
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
  Future<void> replaceCart(List<DataMap> rows) async {
    try {
      await _db.transaction((txn) async {
        await txn.delete('cart_items');
        final batch = txn.batch();
        for (final row in rows) {
          batch.insert('cart_items', row,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw CacheException(message: 'Failed to replace cart: $e');
    }
  }
}
