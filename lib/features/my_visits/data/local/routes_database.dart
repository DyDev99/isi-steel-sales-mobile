import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens (once, as a lazy singleton via DI) and owns the schema for the
/// route-management feature. Own `routes.db` file, separate from the
/// product catalog's `catalog.db` — same hand-written-SQL approach.
class RoutesDatabase {
  RoutesDatabase._(this.db);
  final Database db;

  static Future<RoutesDatabase> open({String fileName = 'routes.db'}) async {
    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, fileName);
    final db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return RoutesDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        contact TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        territory TEXT NOT NULL,
        territory_type TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        geofence_radius_override REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE routes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        rep_id TEXT NOT NULL,
        rep_name TEXT NOT NULL,
        territory TEXT NOT NULL,
        visit_date TEXT NOT NULL,
        planned_start TEXT NOT NULL,
        planned_end TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_routes_rep ON routes(rep_id)');

    await db.execute('''
      CREATE TABLE stops (
        id TEXT PRIMARY KEY,
        route_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        sequence INTEGER NOT NULL,
        planned_arrival TEXT NOT NULL,
        planned_departure TEXT NOT NULL,
        status TEXT NOT NULL,
        actual_arrival TEXT,
        actual_departure TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_stops_route ON stops(route_id)');
    await db.execute('CREATE INDEX idx_stops_customer ON stops(customer_id)');

    await db.execute('''
      CREATE TABLE location_samples (
        id TEXT PRIMARY KEY,
        route_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL NOT NULL,
        speed REAL NOT NULL,
        heading REAL NOT NULL,
        altitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        is_mocked INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_samples_route ON location_samples(route_id)');

    await db.execute('''
      CREATE TABLE checkins (
        id TEXT PRIMARY KEY,
        stop_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL NOT NULL,
        distance_from_customer REAL NOT NULL,
        is_mocked INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_checkins_stop ON checkins(stop_id)');

    await db.execute('''
      CREATE TABLE checkouts (
        id TEXT PRIMARY KEY,
        stop_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        duration_minutes INTEGER NOT NULL,
        visit_summary TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_checkouts_stop ON checkouts(stop_id)');

    await db.execute('''
      CREATE TABLE visit_orders (
        id TEXT PRIMARY KEY,
        stop_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        unit_price REAL NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_visit_orders_stop ON visit_orders(stop_id)');

    await db.execute('''
      CREATE TABLE visit_stock_updates (
        id TEXT PRIMARY KEY,
        stop_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        counted_quantity REAL NOT NULL,
        notes TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_stock_updates_stop ON visit_stock_updates(stop_id)');

    await db.execute('''
      CREATE TABLE visit_returns (
        id TEXT PRIMARY KEY,
        stop_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        reason TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_returns_stop ON visit_returns(stop_id)');

    await db.execute('''
      CREATE TABLE visit_collections (
        id TEXT PRIMARY KEY,
        stop_id TEXT NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL,
        reference TEXT NOT NULL,
        notes TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_collections_stop ON visit_collections(stop_id)');

    await db.execute('''
      CREATE TABLE visit_notes (
        id TEXT PRIMARY KEY,
        stop_id TEXT NOT NULL,
        type TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_notes_stop ON visit_notes(stop_id)');

    await db.execute('''
      CREATE TABLE visit_photos (
        id TEXT PRIMARY KEY,
        stop_id TEXT NOT NULL,
        url TEXT NOT NULL,
        caption TEXT NOT NULL,
        taken_at TEXT NOT NULL,
        is_signature INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_photos_stop ON visit_photos(stop_id)');

    await db.execute('''
      CREATE TABLE fraud_flags (
        id TEXT PRIMARY KEY,
        route_id TEXT NOT NULL,
        stop_id TEXT,
        type TEXT NOT NULL,
        detail TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        blocked INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_fraud_flags_route ON fraud_flags(route_id)');

    await db.execute('''
      CREATE TABLE sync_meta (
        entity TEXT PRIMARY KEY,
        last_synced_at TEXT
      )
    ''');
  }
}
