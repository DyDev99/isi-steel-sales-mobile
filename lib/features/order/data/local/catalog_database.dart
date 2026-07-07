import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens (once, as a lazy singleton via DI) and owns the schema for the
/// offline product catalog. Plain `sqflite` + hand-written SQL — indexed
/// columns via `CREATE INDEX`, full-text search via an FTS4 virtual table
/// (chosen over FTS5 for wider bundled-SQLite compatibility across devices
/// without adding `sqlite3_flutter_libs`).
class CatalogDatabase {
  CatalogDatabase._(this.db);
  final Database db;

  static Future<CatalogDatabase> open({String fileName = 'catalog.db'}) async {
    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, fileName);
    final db = await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
    return CatalogDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        parent_id TEXT,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_categories_parent ON categories(parent_id)');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        family_id TEXT NOT NULL,
        family_name TEXT NOT NULL,
        code TEXT NOT NULL,
        sku TEXT NOT NULL,
        material_code TEXT NOT NULL,
        barcode TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category_id TEXT NOT NULL,
        sub_category TEXT NOT NULL,
        brand TEXT NOT NULL,
        grade TEXT NOT NULL,
        material TEXT NOT NULL,
        size TEXT NOT NULL,
        diameter REAL NOT NULL,
        thickness REAL NOT NULL,
        length REAL NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        unit TEXT NOT NULL,
        warehouse_code TEXT NOT NULL,
        territory TEXT NOT NULL,
        business_unit TEXT NOT NULL,
        image_url TEXT NOT NULL,
        is_mto INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        updated_at TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0,
        min_stock REAL NOT NULL DEFAULT 0,
        max_stock REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_products_code ON products(code)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_category ON products(category_id)');
    await db.execute('CREATE INDEX idx_products_brand ON products(brand)');
    await db.execute('CREATE INDEX idx_products_sku ON products(sku)');
    await db.execute('CREATE INDEX idx_products_warehouse ON products(warehouse_code)');
    await db.execute('CREATE INDEX idx_products_family ON products(family_id)');

    // Standalone FTS4 table (not content-linked, since `products.id` is TEXT
    // and FTS4 content= tables expect rowid alignment) — searches resolve a
    // product_id here, then join back into `products`.
    await db.execute('''
      CREATE VIRTUAL TABLE products_fts USING fts4(product_id, code, name, barcode, sku, brand)
    ''');

    await db.execute('''
      CREATE TABLE prices (
        product_id TEXT PRIMARY KEY,
        cost_price REAL NOT NULL,
        standard_price REAL NOT NULL,
        wholesale_price REAL NOT NULL,
        dealer_price REAL NOT NULL,
        vip_price REAL NOT NULL,
        credit_price REAL NOT NULL,
        cash_price REAL NOT NULL,
        promotion_price REAL,
        promotion_type TEXT,
        promotion_label TEXT,
        currency TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stock (
        product_id TEXT NOT NULL,
        warehouse_code TEXT NOT NULL,
        quantity REAL NOT NULL,
        reserved REAL NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (product_id, warehouse_code)
      )
    ''');
    await db.execute('CREATE INDEX idx_stock_warehouse ON stock(warehouse_code)');

    await db.execute('''
      CREATE TABLE sync_meta (
        entity TEXT PRIMARY KEY,
        last_synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        product_id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recent_products (
        product_id TEXT PRIMARY KEY,
        viewed_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        discount_percent REAL NOT NULL DEFAULT 0,
        lead_id TEXT,
        customer_id TEXT,
        editing_quotation_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _createQuotationTables(db);
  }

  static Future<void> _createQuotationTables(Database db) async {
    await db.execute('''
      CREATE TABLE quotations (
        id TEXT PRIMARY KEY,
        customer_id TEXT,
        shop_name TEXT,
        lead_id TEXT,
        lead_display_name TEXT,
        lines_json TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        off_visit_reason TEXT,
        gps_lat REAL,
        gps_lng REAL,
        sap_draft_status TEXT NOT NULL,
        valid_until TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales_orders (
        id TEXT PRIMARY KEY,
        quotation_id TEXT NOT NULL,
        customer_id TEXT,
        shop_name TEXT,
        lead_id TEXT,
        lead_display_name TEXT,
        lines_json TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        off_visit_reason TEXT,
        sap_status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// v1 -> v2: replaces `pending_orders` with `quotations`/`sales_orders`, and
  /// extends `cart_items` with shop/quotation-editing columns. No production
  /// backend to reconcile against, so dropping `pending_orders` is safe.
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS pending_orders');
      await db.execute('ALTER TABLE cart_items ADD COLUMN customer_id TEXT');
      await db.execute('ALTER TABLE cart_items ADD COLUMN editing_quotation_id TEXT');
      await _createQuotationTables(db);
    }
  }
}
