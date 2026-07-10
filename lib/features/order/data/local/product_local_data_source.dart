import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/mock_latency.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_database.dart';
import 'package:isi_steel_sales_mobile/features/order/data/models/category_model.dart';
import 'package:isi_steel_sales_mobile/features/order/data/models/product_model.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';
import 'package:sqflite/sqflite.dart';

const _productColumns = '''
  p.*, pr.cost_price, pr.standard_price, pr.wholesale_price, pr.dealer_price,
  pr.vip_price, pr.credit_price, pr.cash_price, pr.promotion_price,
  pr.promotion_type, pr.promotion_label, pr.currency,
  s.quantity AS stock_quantity, s.reserved AS reserved_quantity
''';
const _productJoins = '''
  FROM products p
  LEFT JOIN prices pr ON pr.product_id = p.id
  LEFT JOIN stock s ON s.product_id = p.id AND s.warehouse_code = p.warehouse_code
''';

abstract interface class ProductLocalDataSource {
  /// Returns up to `pageSize + 1` rows so the caller can detect "has more"
  /// without a separate COUNT query.
  Future<List<ProductModel>> browse({
    required int page,
    required int pageSize,
    String query = '',
    ProductFilter filter = const ProductFilter(),
  });

  /// Exact number of products matching [query] + [filter] — powers the live
  /// "Showing N products" counter without paging through the whole result set.
  Future<int> count({
    String query,
    ProductFilter filter,
  });

  Future<ProductModel?> getById(String id);
  Future<ProductModel?> getByBarcode(String barcode);
  Future<List<String>> fetchBrands();

  /// One representative row per distinct [ProductModel.code] sharing [familyId].
  Future<List<ProductModel>> getVariantsByFamily(String familyId);

  /// Every warehouse row sharing [code].
  Future<List<ProductModel>> getRowsByCode(String code);

  Future<void> toggleFavorite(String productId);
  Future<List<ProductModel>> fetchFavorites();
  Future<List<ProductModel>> fetchRecent();
  Future<void> recordViewed(String productId);

  Future<List<CategoryModel>> fetchCategories();
  Future<void> upsertCategories(List<CategoryModel> categories);

  /// Batched, transactional upsert into `products`/`prices`/`stock`/`products_fts`.
  Future<void> upsertProducts(List<ProductModel> products);
  Future<void> markDeleted(List<String> ids);

  Future<DateTime?> getLastSyncedAt(String entity);
  Future<void> setLastSyncedAt(String entity, DateTime at);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  const ProductLocalDataSourceImpl(this._catalogDb);
  final CatalogDatabase _catalogDb;
  Database get _db => _catalogDb.db;

  @override
  Future<List<ProductModel>> browse({
    required int page,
    required int pageSize,
    String query = '',
    ProductFilter filter = const ProductFilter(),
  }) async {
    try {
      await MockLatency.tick(); // simulate a slow catalog API
      final offset = page * pageSize;
      final limit = pageSize + 1;
      final (where, args) = _buildFilterWhere(filter);

      final orderBy = switch (filter.sortBy) {
        ProductSortBy.nameAsc => 'p.name ASC',
        ProductSortBy.priceAsc =>
          'COALESCE(pr.promotion_price, pr.standard_price, 0) ASC',
        ProductSortBy.priceDesc =>
          'COALESCE(pr.promotion_price, pr.standard_price, 0) DESC',
        ProductSortBy.stockDesc =>
          '(COALESCE(s.quantity, 0) - COALESCE(s.reserved, 0)) DESC',
        ProductSortBy.relevance => 'p.updated_at DESC',
      };

      final sanitized = _sanitizeQuery(query);
      late final String sql;
      late final List<Object?> allArgs;

      if (sanitized.isEmpty) {
        sql = '''
          SELECT $_productColumns
          $_productJoins
          WHERE ${where.join(' AND ')}
          ORDER BY $orderBy
          LIMIT ? OFFSET ?
        ''';
        allArgs = [...args, limit, offset];
      } else {
        final match = _buildMatchExpression(sanitized);
        sql = '''
          SELECT $_productColumns
          FROM products_fts f
          JOIN products p ON p.id = f.product_id
          LEFT JOIN prices pr ON pr.product_id = p.id
          LEFT JOIN stock s ON s.product_id = p.id AND s.warehouse_code = p.warehouse_code
          WHERE products_fts MATCH ? AND ${where.join(' AND ')}
          ORDER BY $orderBy
          LIMIT ? OFFSET ?
        ''';
        allArgs = [match, ...args, limit, offset];
      }

      final rows = await _db.rawQuery(sql, allArgs);
      return rows.map(ProductModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to browse products: $e');
    }
  }

  @override
  Future<int> count({
    String query = '',
    ProductFilter filter = const ProductFilter(),
  }) async {
    try {
      final (where, args) = _buildFilterWhere(filter);
      final sanitized = _sanitizeQuery(query);
      late final String sql;
      late final List<Object?> allArgs;

      if (sanitized.isEmpty) {
        sql = '''
          SELECT COUNT(*) AS c
          $_productJoins
          WHERE ${where.join(' AND ')}
        ''';
        allArgs = args;
      } else {
        final match = _buildMatchExpression(sanitized);
        sql = '''
          SELECT COUNT(*) AS c
          FROM products_fts f
          JOIN products p ON p.id = f.product_id
          LEFT JOIN prices pr ON pr.product_id = p.id
          LEFT JOIN stock s ON s.product_id = p.id AND s.warehouse_code = p.warehouse_code
          WHERE products_fts MATCH ? AND ${where.join(' AND ')}
        ''';
        allArgs = [match, ...args];
      }

      final rows = await _db.rawQuery(sql, allArgs);
      return Sqflite.firstIntValue(rows) ?? 0;
    } catch (e) {
      throw CacheException(message: 'Failed to count products: $e');
    }
  }

  /// Shared WHERE builder for [browse] and [count] so the two never drift.
  /// Returns the accumulated predicates (always including the soft-delete
  /// guard) and their positional args. FTS `MATCH` is handled separately by
  /// each caller since it changes the FROM clause, not the WHERE facets.
  (List<String>, List<Object?>) _buildFilterWhere(ProductFilter filter) {
    final where = <String>['p.deleted = 0'];
    final args = <Object?>[];

    void addEq(String column, Object? value) {
      if (value == null) return;
      where.add('p.$column = ?');
      args.add(value);
    }

    addEq('category_id', filter.categoryId);
    addEq('brand', filter.brand);
    addEq('warehouse_code', filter.warehouseCode);
    // Sequential attribute filters (size/length/mesh/quality + the
    // category-dependent diameter/thickness/material). Columns are declared
    // NOT NULL in the products table, so a plain `=` is safe and index-able.
    addEq('size', filter.size);
    addEq('length', filter.length);
    addEq('width', filter.width);
    addEq('height', filter.height);
    addEq('grade', filter.grade);
    addEq('diameter', filter.diameter);
    addEq('thickness', filter.thickness);
    addEq('material', filter.material);

    if (filter.availableOnly) {
      where.add('(COALESCE(s.quantity, 0) - COALESCE(s.reserved, 0)) > 0');
    }
    return (where, args);
  }

  @override
  Future<ProductModel?> getById(String id) async {
    try {
      final rows = await _db.rawQuery(
        'SELECT $_productColumns $_productJoins WHERE p.id = ? AND p.deleted = 0 LIMIT 1',
        [id],
      );
      return rows.isEmpty ? null : ProductModel.fromRow(rows.first);
    } catch (e) {
      throw CacheException(message: 'Failed to load product $id: $e');
    }
  }

  @override
  Future<ProductModel?> getByBarcode(String barcode) async {
    try {
      final rows = await _db.rawQuery(
        'SELECT $_productColumns $_productJoins WHERE p.barcode = ? AND p.deleted = 0 LIMIT 1',
        [barcode],
      );
      return rows.isEmpty ? null : ProductModel.fromRow(rows.first);
    } catch (e) {
      throw CacheException(message: 'Failed to look up barcode $barcode: $e');
    }
  }

  @override
  Future<List<ProductModel>> getVariantsByFamily(String familyId) async {
    try {
      final rows = await _db.rawQuery(
        '''
          SELECT $_productColumns
          $_productJoins
          WHERE p.family_id = ? AND p.deleted = 0
          GROUP BY p.code
          ORDER BY p.name ASC
        ''',
        [familyId],
      );
      return rows.map(ProductModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load product variants: $e');
    }
  }

  @override
  Future<List<ProductModel>> getRowsByCode(String code) async {
    try {
      final rows = await _db.rawQuery(
        '''
          SELECT $_productColumns
          $_productJoins
          WHERE p.code = ? AND p.deleted = 0
          ORDER BY p.warehouse_code ASC
        ''',
        [code],
      );
      return rows.map(ProductModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load warehouse stock: $e');
    }
  }

  @override
  Future<List<String>> fetchBrands() async {
    try {
      final rows = await _db.rawQuery(
        'SELECT DISTINCT brand FROM products WHERE deleted = 0 ORDER BY brand ASC',
      );
      return rows.map((r) => r['brand'] as String).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load brands: $e');
    }
  }

  @override
  Future<void> toggleFavorite(String productId) async {
    try {
      final existing = await _db
          .query('favorites', where: 'product_id = ?', whereArgs: [productId]);
      if (existing.isNotEmpty) {
        await _db.delete('favorites',
            where: 'product_id = ?', whereArgs: [productId]);
      } else {
        await _db.insert('favorites', {
          'product_id': productId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw CacheException(message: 'Failed to toggle favorite: $e');
    }
  }

  @override
  Future<List<ProductModel>> fetchFavorites() async {
    try {
      final rows = await _db.rawQuery('''
        SELECT $_productColumns
        FROM favorites fav
        JOIN products p ON p.id = fav.product_id
        LEFT JOIN prices pr ON pr.product_id = p.id
        LEFT JOIN stock s ON s.product_id = p.id AND s.warehouse_code = p.warehouse_code
        WHERE p.deleted = 0
        ORDER BY fav.created_at DESC
      ''');
      return rows.map(ProductModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load favorites: $e');
    }
  }

  @override
  Future<List<ProductModel>> fetchRecent() async {
    try {
      final rows = await _db.rawQuery('''
        SELECT $_productColumns
        FROM recent_products rp
        JOIN products p ON p.id = rp.product_id
        LEFT JOIN prices pr ON pr.product_id = p.id
        LEFT JOIN stock s ON s.product_id = p.id AND s.warehouse_code = p.warehouse_code
        WHERE p.deleted = 0
        ORDER BY rp.viewed_at DESC
        LIMIT 20
      ''');
      return rows.map(ProductModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load recent products: $e');
    }
  }

  @override
  Future<void> recordViewed(String productId) async {
    try {
      await _db.insert(
        'recent_products',
        {
          'product_id': productId,
          'viewed_at': DateTime.now().toIso8601String()
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to record viewed product: $e');
    }
  }

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      await MockLatency.tick(); // simulate a slow categories API
      final rows = await _db.query('categories', orderBy: 'sort_order ASC');
      return rows.map(CategoryModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load categories: $e');
    }
  }

  @override
  Future<void> upsertCategories(List<CategoryModel> categories) async {
    try {
      final batch = _db.batch();
      for (final c in categories) {
        batch.insert('categories', c.toRow(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw CacheException(message: 'Failed to save categories: $e');
    }
  }

  @override
  Future<void> upsertProducts(List<ProductModel> products) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();
        for (final product in products) {
          batch.insert('products', product.toProductRow(),
              conflictAlgorithm: ConflictAlgorithm.replace);
          batch.insert('prices', product.toPriceRow(),
              conflictAlgorithm: ConflictAlgorithm.replace);
          batch.insert('stock', product.toStockRow(),
              conflictAlgorithm: ConflictAlgorithm.replace);
          batch.delete('products_fts',
              where: 'product_id = ?', whereArgs: [product.id]);
          batch.insert('products_fts', product.toFtsRow());
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw CacheException(message: 'Failed to save synced products: $e');
    }
  }

  @override
  Future<void> markDeleted(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await _db.transaction((txn) async {
        final placeholders = List.filled(ids.length, '?').join(',');
        await txn.rawUpdate(
            'UPDATE products SET deleted = 1 WHERE id IN ($placeholders)', ids);
        final batch = txn.batch();
        for (final id in ids) {
          batch
              .delete('products_fts', where: 'product_id = ?', whereArgs: [id]);
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw CacheException(message: 'Failed to apply deletions: $e');
    }
  }

  @override
  Future<DateTime?> getLastSyncedAt(String entity) async {
    try {
      final rows = await _db
          .query('sync_meta', where: 'entity = ?', whereArgs: [entity]);
      if (rows.isEmpty) return null;
      final raw = rows.first['last_synced_at'] as String?;
      return raw == null ? null : DateTime.parse(raw);
    } catch (e) {
      throw CacheException(message: 'Failed to read sync metadata: $e');
    }
  }

  @override
  Future<void> setLastSyncedAt(String entity, DateTime at) async {
    try {
      await _db.insert(
        'sync_meta',
        {'entity': entity, 'last_synced_at': at.toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to write sync metadata: $e');
    }
  }

  static String _sanitizeQuery(String raw) =>
      raw.replaceAll(RegExp(r'[^\w\s.]'), ' ').trim();

  static String _buildMatchExpression(String sanitized) {
    final words = sanitized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words
        .map((w) =>
            '(code:$w* OR name:$w* OR barcode:$w* OR sku:$w* OR brand:$w*)')
        .join(' AND ');
  }
}
