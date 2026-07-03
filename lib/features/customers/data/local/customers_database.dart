import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens (once, as a lazy singleton via DI) and owns the schema for the
/// offline customer directory. Mirrors `order`'s `CatalogDatabase` — plain
/// `sqflite` + hand-written SQL, own database file so this feature's data
/// lifecycle (wiped on logout, resynced per territory) is independent of
/// the product catalog's.
class CustomersDatabase {
  CustomersDatabase._(this.db);
  final Database db;

  static Future<CustomersDatabase> open({String fileName = 'customers.db'}) async {
    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, fileName);
    final db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return CustomersDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    // ── SAP-controlled: overwritten wholesale on every sync, never merged
    // locally since reps have no write path to these columns. ──────────
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        sap_customer_id TEXT NOT NULL,
        customer_code TEXT NOT NULL,
        shop_name TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        whatsapp TEXT,
        address TEXT NOT NULL,
        province TEXT NOT NULL,
        district TEXT NOT NULL,
        territory TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        credit_limit REAL NOT NULL,
        status TEXT NOT NULL,
        assigned_rep_id TEXT NOT NULL,
        assigned_rep_name TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        origin_lead_id TEXT,
        products_purchased TEXT NOT NULL DEFAULT '',
        last_order_date TEXT,
        last_visit_date TEXT,
        lifetime_value REAL NOT NULL DEFAULT 0,
        open_opportunity_count INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE UNIQUE INDEX idx_customers_sap_id ON customers(sap_customer_id)');
    await db.execute('CREATE INDEX idx_customers_territory ON customers(territory)');
    await db.execute('CREATE INDEX idx_customers_rep ON customers(assigned_rep_id)');
    await db.execute('CREATE INDEX idx_customers_status ON customers(status)');

    await db.execute('''
      CREATE VIRTUAL TABLE customers_fts USING fts4(
        customer_id, shop_name, customer_code, owner_name, phone
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_contacts (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_customer_contacts_customer ON customer_contacts(customer_id)');

    // ── Rep-owned: written locally, queued for push independently of the
    // SAP sync above — see `CustomerLocalDataSource.fetchUnsyncedNotes`. ──
    await db.execute('''
      CREATE TABLE customer_notes (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_customer_notes_customer ON customer_notes(customer_id)');

    await db.execute('''
      CREATE TABLE customer_activities (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        type TEXT NOT NULL,
        summary TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_customer_activities_customer ON customer_activities(customer_id)');

    await db.execute('''
      CREATE TABLE customer_favorites (
        customer_id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_recent (
        customer_id TEXT PRIMARY KEY,
        viewed_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_sync_meta (
        entity TEXT PRIMARY KEY,
        last_synced_at TEXT
      )
    ''');
  }
}
