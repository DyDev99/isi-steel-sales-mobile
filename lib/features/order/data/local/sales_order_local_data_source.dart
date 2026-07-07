import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/mock_latency.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class SalesOrderLocalDataSource {
  Future<void> insertSalesOrder(DataMap row);
  Future<DataMap?> getById(String id);
  Future<List<DataMap>> fetchAll();
}

class SalesOrderLocalDataSourceImpl implements SalesOrderLocalDataSource {
  const SalesOrderLocalDataSourceImpl(this._catalogDb);
  final CatalogDatabase _catalogDb;
  Database get _db => _catalogDb.db;

  @override
  Future<void> insertSalesOrder(DataMap row) async {
    try {
      await _db.insert('sales_orders', row, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save sales order: $e');
    }
  }

  @override
  Future<DataMap?> getById(String id) async {
    try {
      final rows = await _db.query('sales_orders', where: 'id = ?', whereArgs: [id], limit: 1);
      return rows.isEmpty ? null : rows.first;
    } catch (e) {
      throw CacheException(message: 'Failed to load sales order $id: $e');
    }
  }

  @override
  Future<List<DataMap>> fetchAll() async {
    try {
      await MockLatency.tick(); // simulate a slow sales-orders API
      return _db.query('sales_orders', orderBy: 'created_at DESC');
    } catch (e) {
      throw CacheException(message: 'Failed to load sales orders: $e');
    }
  }
}
