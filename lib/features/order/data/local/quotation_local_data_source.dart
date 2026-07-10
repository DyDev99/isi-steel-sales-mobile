import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/mock_latency.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class QuotationLocalDataSource {
  Future<void> insertQuotation(DataMap row);
  Future<void> updateQuotation(DataMap row);
  Future<void> deleteQuotation(String id);
  Future<DataMap?> getById(String id);
  Future<List<DataMap>> fetchAll();
}

class QuotationLocalDataSourceImpl implements QuotationLocalDataSource {
  const QuotationLocalDataSourceImpl(this._catalogDb);
  final CatalogDatabase _catalogDb;
  Database get _db => _catalogDb.db;

  @override
  Future<void> insertQuotation(DataMap row) async {
    try {
      await _db.insert('quotations', row,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheException(message: 'Failed to save quotation: $e');
    }
  }

  @override
  Future<void> updateQuotation(DataMap row) async {
    try {
      await _db
          .update('quotations', row, where: 'id = ?', whereArgs: [row['id']]);
    } catch (e) {
      throw CacheException(message: 'Failed to update quotation: $e');
    }
  }

  @override
  Future<void> deleteQuotation(String id) async {
    try {
      await _db.delete('quotations', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw CacheException(message: 'Failed to delete quotation $id: $e');
    }
  }

  @override
  Future<DataMap?> getById(String id) async {
    try {
      final rows = await _db.query('quotations',
          where: 'id = ?', whereArgs: [id], limit: 1);
      return rows.isEmpty ? null : rows.first;
    } catch (e) {
      throw CacheException(message: 'Failed to load quotation $id: $e');
    }
  }

  @override
  Future<List<DataMap>> fetchAll() async {
    try {
      await MockLatency.tick(); // simulate a slow quotations API
      return _db.query('quotations', orderBy: 'created_at DESC');
    } catch (e) {
      throw CacheException(message: 'Failed to load quotations: $e');
    }
  }
}
