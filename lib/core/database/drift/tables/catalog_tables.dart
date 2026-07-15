import 'package:drift/drift.dart';

/// Offline product catalog master data (Blueprint Layer 1), ported from the
/// legacy `catalog.db` into the single encrypted database. SAP-controlled:
/// replaced wholesale on sync. Transactional tables (cart, quotations, sales
/// orders, sync queue) are ported in a separate slice.

class Categories extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_products_code', columns: {#code})
@TableIndex(name: 'idx_products_barcode', columns: {#barcode})
@TableIndex(name: 'idx_products_category', columns: {#categoryId})
@TableIndex(name: 'idx_products_brand', columns: {#brand})
@TableIndex(name: 'idx_products_sku', columns: {#sku})
@TableIndex(name: 'idx_products_warehouse', columns: {#warehouseCode})
@TableIndex(name: 'idx_products_family', columns: {#familyId})
class Products extends Table {
  @override
  String get tableName => 'products';

  TextColumn get id => text()();
  TextColumn get familyId => text()();
  TextColumn get familyName => text()();
  TextColumn get code => text()();
  TextColumn get sku => text()();
  TextColumn get materialCode => text()();
  TextColumn get barcode => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get categoryId => text()();
  TextColumn get subCategory => text()();
  TextColumn get brand => text()();
  TextColumn get grade => text()();
  TextColumn get material => text()();
  TextColumn get size => text()();
  RealColumn get diameter => real()();
  RealColumn get thickness => real()();
  RealColumn get length => real()();
  RealColumn get width => real()();
  RealColumn get height => real()();
  RealColumn get weight => real()();
  TextColumn get unit => text()();
  TextColumn get warehouseCode => text()();
  TextColumn get territory => text()();
  TextColumn get businessUnit => text()();
  TextColumn get imageUrl => text()();
  BoolColumn get isMto => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  RealColumn get maxStock => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Prices extends Table {
  @override
  String get tableName => 'prices';

  TextColumn get productId => text().references(Products, #id)();
  RealColumn get costPrice => real()();
  RealColumn get standardPrice => real()();
  RealColumn get wholesalePrice => real()();
  RealColumn get dealerPrice => real()();
  RealColumn get vipPrice => real()();
  RealColumn get creditPrice => real()();
  RealColumn get cashPrice => real()();
  RealColumn get promotionPrice => real().nullable()();
  TextColumn get promotionType => text().nullable()();
  TextColumn get promotionLabel => text().nullable()();
  TextColumn get currency => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId};
}

@TableIndex(name: 'idx_stock_warehouse', columns: {#warehouseCode})
class Stock extends Table {
  @override
  String get tableName => 'stock';

  TextColumn get productId => text().references(Products, #id)();
  TextColumn get warehouseCode => text()();
  RealColumn get quantity => real()();
  RealColumn get reserved => real()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId, warehouseCode};
}

// ── Local UI state + sync bookkeeping (read side) ────────────────────

class ProductFavorites extends Table {
  @override
  String get tableName => 'favorites';

  TextColumn get productId => text().references(Products, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId};
}

class RecentProducts extends Table {
  @override
  String get tableName => 'recent_products';

  TextColumn get productId => text().references(Products, #id)();
  DateTimeColumn get viewedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId};
}

class CatalogSyncMeta extends Table {
  @override
  String get tableName => 'catalog_sync_meta';

  TextColumn get entity => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {entity};
}
