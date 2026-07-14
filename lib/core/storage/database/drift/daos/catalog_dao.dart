import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/storage/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/storage/database/drift/tables/catalog_tables.dart';

part 'catalog_dao.g.dart';

/// Sort options for the joined product queries.
enum ProductQuerySort { relevance, nameAsc, priceAsc, priceDesc, stockDesc }

/// Neutral browse/count criteria for the joined product queries — the Order
/// feature maps its `ProductFilter` onto this so the core DAO stays decoupled.
class ProductQuery {
  const ProductQuery({
    this.query = '',
    this.page = 0,
    this.pageSize = 30,
    this.categoryId,
    this.brand,
    this.warehouseCode,
    this.size,
    this.length,
    this.width,
    this.height,
    this.grade,
    this.diameter,
    this.thickness,
    this.material,
    this.availableOnly = false,
    this.sort = ProductQuerySort.relevance,
  });

  final String query;
  final int page;
  final int pageSize;
  final String? categoryId;
  final String? brand;
  final String? warehouseCode;
  final String? size;
  final double? length;
  final double? width;
  final double? height;
  final String? grade;
  final double? diameter;
  final double? thickness;
  final String? material;
  final bool availableOnly;
  final ProductQuerySort sort;
}

/// Scoped accessor for the offline product catalog master data. Reads exclude
/// soft-deleted products. Search uses LIKE (FTS5 is a planned optimization).
@DriftAccessor(tables: [
  Categories,
  Products,
  Prices,
  Stock,
  ProductFavorites,
  RecentProducts,
  CatalogSyncMeta,
])
class CatalogDao extends DatabaseAccessor<AppDatabase> with _$CatalogDaoMixin {
  CatalogDao(super.db);

  // ── Sync writes ────────────────────────────────────────────────────

  Future<void> upsertCategories(List<CategoriesCompanion> rows) =>
      _batchUpsert(categories, rows);

  /// Products must be upserted before prices/stock (FK references products).
  Future<void> upsertProducts(List<ProductsCompanion> rows) =>
      _batchUpsert(products, rows);

  Future<void> upsertPrices(List<PricesCompanion> rows) =>
      _batchUpsert(prices, rows);

  Future<void> upsertStock(List<StockCompanion> rows) =>
      _batchUpsert(stock, rows);

  Future<void> _batchUpsert<T extends Table, D>(
    TableInfo<T, D> table,
    List<Insertable<D>> rows,
  ) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(table, rows));
  }

  Future<void> markDeleted(List<String> ids) async {
    if (ids.isEmpty) return;
    await (update(products)..where((t) => t.id.isIn(ids)))
        .write(const ProductsCompanion(deleted: Value(true)));
  }

  // ── Catalog reads ──────────────────────────────────────────────────

  /// Paginated browse: returns up to `pageSize + 1` rows for has-more
  /// detection. Optional category/brand filters and a LIKE search over
  /// code/name/barcode/sku/brand.
  Future<List<Product>> browse({
    required int page,
    required int pageSize,
    String query = '',
    String? categoryId,
    String? brand,
  }) {
    final statement = select(products)
      ..where((t) {
        var cond = t.deleted.equals(false);
        if (categoryId != null) cond = cond & t.categoryId.equals(categoryId);
        if (brand != null) cond = cond & t.brand.equals(brand);
        final trimmed = query.trim();
        if (trimmed.isNotEmpty) {
          final like = '%$trimmed%';
          cond = cond &
              (t.code.like(like) |
                  t.name.like(like) |
                  t.barcode.like(like) |
                  t.sku.like(like) |
                  t.brand.like(like));
        }
        return cond;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.name)])
      ..limit(pageSize + 1, offset: page * pageSize);
    return statement.get();
  }

  Future<Product?> getById(String id) {
    return (select(products)
          ..where((t) => t.id.equals(id) & t.deleted.equals(false)))
        .getSingleOrNull();
  }

  Future<Product?> getByBarcode(String barcode) {
    return (select(products)
          ..where((t) => t.barcode.equals(barcode) & t.deleted.equals(false))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Product>> getByCategory(String categoryId) {
    return (select(products)
          ..where((t) =>
              t.categoryId.equals(categoryId) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Future<List<Category>> fetchCategories() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
  }

  Future<Price?> getPrice(String productId) {
    return (select(prices)..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();
  }

  /// All warehouse stock rows for a product.
  Future<List<StockData>> getWarehouseStock(String productId) {
    return (select(stock)..where((t) => t.productId.equals(productId))).get();
  }

  // ── Favorites / recent (local UI state) ────────────────────────────

  Future<void> toggleFavorite(String productId) async {
    final existing = await (select(productFavorites)
          ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();
    if (existing != null) {
      await (delete(productFavorites)
            ..where((t) => t.productId.equals(productId)))
          .go();
    } else {
      await into(productFavorites).insert(
        ProductFavoritesCompanion.insert(
          productId: productId,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<List<Product>> fetchFavorites() {
    final query = select(productFavorites).join([
      innerJoin(products, products.id.equalsExp(productFavorites.productId)),
    ])
      ..where(products.deleted.equals(false))
      ..orderBy([OrderingTerm(
          expression: productFavorites.createdAt, mode: OrderingMode.desc)]);
    return query.map((row) => row.readTable(products)).get();
  }

  Future<void> recordViewed(String productId) {
    return into(recentProducts).insertOnConflictUpdate(
      RecentProductsCompanion.insert(
        productId: productId,
        viewedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<List<Product>> fetchRecent({int limit = 20}) {
    final query = select(recentProducts).join([
      innerJoin(products, products.id.equalsExp(recentProducts.productId)),
    ])
      ..where(products.deleted.equals(false))
      ..orderBy([OrderingTerm(
          expression: recentProducts.viewedAt, mode: OrderingMode.desc)])
      ..limit(limit);
    return query.map((row) => row.readTable(products)).get();
  }

  // ── Sync metadata ──────────────────────────────────────────────────

  Future<DateTime?> getLastSyncedAt(String entity) async {
    final row = await (select(catalogSyncMeta)
          ..where((t) => t.entity.equals(entity)))
        .getSingleOrNull();
    return row?.lastSyncedAt;
  }

  Future<void> setLastSyncedAt(String entity, DateTime at) {
    return into(catalogSyncMeta).insertOnConflictUpdate(
      CatalogSyncMetaCompanion.insert(
        entity: entity,
        lastSyncedAt: Value(at),
      ),
    );
  }

  // ── Joined product queries (product + price + own-warehouse stock) ──
  //
  // These reproduce the legacy `catalog.db` SELECTs verbatim (same aliases) so
  // the Order feature's `ProductModel.fromRow` maps each `QueryRow.data`
  // unchanged. Full-text `MATCH` is replaced by a LIKE scan (FTS5 is a planned
  // optimization); everything else — the price/stock joins, availability guard
  // and COALESCE-based price/stock sorts — is preserved.

  static const String _productCols = '''
    p.*, pr.cost_price, pr.standard_price, pr.wholesale_price, pr.dealer_price,
    pr.vip_price, pr.credit_price, pr.cash_price, pr.promotion_price,
    pr.promotion_type, pr.promotion_label, pr.currency,
    s.quantity AS stock_quantity, s.reserved AS reserved_quantity''';

  static const String _productJoins = '''
    FROM products p
    LEFT JOIN prices pr ON pr.product_id = p.id
    LEFT JOIN stock s ON s.product_id = p.id AND s.warehouse_code = p.warehouse_code''';

  Set<ResultSetImplementation<dynamic, dynamic>> get _productReads =>
      {products, prices, stock};

  Future<List<QueryRow>> browseProducts(ProductQuery q) {
    final (where, vars) = _productWhere(q);
    final sql = 'SELECT $_productCols $_productJoins WHERE $where '
        'ORDER BY ${_productOrder(q.sort)} LIMIT ? OFFSET ?';
    return customSelect(
      sql,
      variables: [...vars, Variable(q.pageSize + 1), Variable(q.page * q.pageSize)],
      readsFrom: _productReads,
    ).get();
  }

  Future<int> countProducts(ProductQuery q) async {
    final (where, vars) = _productWhere(q);
    final row = await customSelect(
      'SELECT COUNT(*) AS c $_productJoins WHERE $where',
      variables: vars,
      readsFrom: _productReads,
    ).getSingle();
    return row.read<int>('c');
  }

  Future<QueryRow?> productById(String id) {
    return customSelect(
      'SELECT $_productCols $_productJoins WHERE p.id = ? AND p.deleted = 0 LIMIT 1',
      variables: [Variable(id)],
      readsFrom: _productReads,
    ).getSingleOrNull();
  }

  Future<QueryRow?> productByBarcode(String barcode) {
    return customSelect(
      'SELECT $_productCols $_productJoins WHERE p.barcode = ? AND p.deleted = 0 LIMIT 1',
      variables: [Variable(barcode)],
      readsFrom: _productReads,
    ).getSingleOrNull();
  }

  /// One representative row per distinct `code` within a family.
  Future<List<QueryRow>> variantRowsByFamily(String familyId) {
    return customSelect(
      'SELECT $_productCols $_productJoins '
      'WHERE p.family_id = ? AND p.deleted = 0 GROUP BY p.code ORDER BY p.name ASC',
      variables: [Variable(familyId)],
      readsFrom: _productReads,
    ).get();
  }

  /// Every warehouse row sharing a `code`.
  Future<List<QueryRow>> rowsByCode(String code) {
    return customSelect(
      'SELECT $_productCols $_productJoins '
      'WHERE p.code = ? AND p.deleted = 0 ORDER BY p.warehouse_code ASC',
      variables: [Variable(code)],
      readsFrom: _productReads,
    ).get();
  }

  Future<List<QueryRow>> favoriteProductRows() {
    return customSelect(
      'SELECT $_productCols FROM favorites fav '
      'JOIN products p ON p.id = fav.product_id '
      'LEFT JOIN prices pr ON pr.product_id = p.id '
      'LEFT JOIN stock s ON s.product_id = p.id AND s.warehouse_code = p.warehouse_code '
      'WHERE p.deleted = 0 ORDER BY fav.created_at DESC',
      readsFrom: {productFavorites, ..._productReads},
    ).get();
  }

  Future<List<QueryRow>> recentProductRows({int limit = 20}) {
    return customSelect(
      'SELECT $_productCols FROM recent_products rp '
      'JOIN products p ON p.id = rp.product_id '
      'LEFT JOIN prices pr ON pr.product_id = p.id '
      'LEFT JOIN stock s ON s.product_id = p.id AND s.warehouse_code = p.warehouse_code '
      'WHERE p.deleted = 0 ORDER BY rp.viewed_at DESC LIMIT ?',
      variables: [Variable(limit)],
      readsFrom: {recentProducts, ..._productReads},
    ).get();
  }

  Future<List<String>> distinctBrands() async {
    final rows = await customSelect(
      'SELECT DISTINCT brand FROM products WHERE deleted = 0 ORDER BY brand ASC',
      readsFrom: {products},
    ).get();
    return rows.map((r) => r.read<String>('brand')).toList();
  }

  /// Atomic upsert of a product bundle (master + price + own-warehouse stock).
  Future<void> upsertCatalog({
    required List<ProductsCompanion> productRows,
    required List<PricesCompanion> priceRows,
    required List<StockCompanion> stockRows,
  }) async {
    await transaction(() async {
      await batch((b) {
        b.insertAllOnConflictUpdate(products, productRows);
        b.insertAllOnConflictUpdate(prices, priceRows);
        b.insertAllOnConflictUpdate(stock, stockRows);
      });
    });
  }

  (String, List<Variable>) _productWhere(ProductQuery q) {
    final where = <String>['p.deleted = 0'];
    final vars = <Variable>[];

    void eq(String column, Object? value) {
      if (value == null) return;
      where.add('p.$column = ?');
      vars.add(Variable(value));
    }

    eq('category_id', q.categoryId);
    eq('brand', q.brand);
    eq('warehouse_code', q.warehouseCode);
    eq('size', q.size);
    eq('length', q.length);
    eq('width', q.width);
    eq('height', q.height);
    eq('grade', q.grade);
    eq('diameter', q.diameter);
    eq('thickness', q.thickness);
    eq('material', q.material);

    if (q.availableOnly) {
      where.add('(COALESCE(s.quantity, 0) - COALESCE(s.reserved, 0)) > 0');
    }

    final sanitized = q.query.replaceAll(RegExp(r'[^\w\s.]'), ' ').trim();
    if (sanitized.isNotEmpty) {
      final like = '%$sanitized%';
      where.add('(p.code LIKE ? OR p.name LIKE ? OR p.barcode LIKE ? '
          'OR p.sku LIKE ? OR p.brand LIKE ?)');
      for (var i = 0; i < 5; i++) {
        vars.add(Variable(like));
      }
    }
    return (where.join(' AND '), vars);
  }

  String _productOrder(ProductQuerySort sort) => switch (sort) {
        ProductQuerySort.nameAsc => 'p.name ASC',
        ProductQuerySort.priceAsc =>
          'COALESCE(pr.promotion_price, pr.standard_price, 0) ASC',
        ProductQuerySort.priceDesc =>
          'COALESCE(pr.promotion_price, pr.standard_price, 0) DESC',
        ProductQuerySort.stockDesc =>
          '(COALESCE(s.quantity, 0) - COALESCE(s.reserved, 0)) DESC',
        ProductQuerySort.relevance => 'p.updated_at DESC',
      };
}
