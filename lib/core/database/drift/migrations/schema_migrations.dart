import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';

/// The single source of truth for the encrypted database's schema version.
/// Bump this by exactly one whenever a schema change ships, and add the matching
/// step to [_stepwiseMigrations].
const int kCurrentSchemaVersion = 14;

/// Keys under which the migrator records bookkeeping in `app_metadata`, so the
/// on-device schema history is auditable and a failed/partial upgrade is
/// detectable.
class SchemaMetadataKeys {
  SchemaMetadataKeys._();

  static const String schemaVersion = 'schema.version';
  static const String createdAt = 'schema.created_at';
  static const String lastMigratedAt = 'schema.last_migrated_at';
  static const String lastMigratedFrom = 'schema.last_migrated_from';
}

/// A single stepwise migration: transforms the schema from version `v-1` to `v`.
/// Must be idempotent-safe and self-contained.
typedef SchemaMigrationStep = Future<void> Function(
  Migrator migrator,
  AppDatabase db,
);

/// Ordered registry of stepwise migrations, keyed by the version they upgrade
/// *to*. v1 is the initial `createAll`, so the first entry here will be `2`.
///
final Map<int, SchemaMigrationStep> _stepwiseMigrations =
    <int, SchemaMigrationStep>{
  // v2 (T2): first feature entity ported into the encrypted single DB.
  2: (m, db) async => m.createTable(db.customers),
  // v3 (T2): customer child tables (contacts, notes, activities, favorites,
  // recent, sync meta).
  3: (m, db) async {
    await m.createTable(db.customerContacts);
    await m.createTable(db.customerNotes);
    await m.createTable(db.customerActivities);
    await m.createTable(db.customerFavorites);
    await m.createTable(db.customerRecent);
    await m.createTable(db.customerSyncMeta);
  },
  // v4 (T3): product catalog master data.
  4: (m, db) async {
    await m.createTable(db.categories);
    await m.createTable(db.products);
    await m.createTable(db.prices);
    await m.createTable(db.stock);
  },
  // v5 (T3): catalog read-side state (favorites, recent, sync meta).
  5: (m, db) async {
    await m.createTable(db.productFavorites);
    await m.createTable(db.recentProducts);
    await m.createTable(db.catalogSyncMeta);
  },
  // v6 (T5): local cart.
  6: (m, db) async => m.createTable(db.cartItems),
  // v7 (T1.5): route domain, ported off the plaintext `routes.db`.
  //
  // The two customer columns are added *before* the route tables because
  // `route_stops.customer_id` is a real FK to `customers` — an integrity
  // guarantee the old three-database split made impossible (ADR-001).
  7: (m, db) async {
    await m.addColumn(db.customers, db.customers.territoryType);
    await m.addColumn(db.customers, db.customers.geofenceRadiusOverride);
    await m.createTable(db.routes);
    await m.createTable(db.routeStops);
    await m.createTable(db.locationSamples);
    await m.createTable(db.fraudFlags);
    await m.createTable(db.routeSyncMeta);
  },
  // v8 (T1.5): visit captures, ported off the plaintext `routes.db`. Separate
  // from v7 so a failure here leaves a coherent v7 schema rather than a
  // half-built route domain.
  8: (m, db) async {
    await m.createTable(db.visitCheckIns);
    await m.createTable(db.visitCheckOuts);
    await m.createTable(db.visitOrderLines);
    await m.createTable(db.visitStockUpdates);
    await m.createTable(db.visitReturns);
    await m.createTable(db.visitCollections);
    await m.createTable(db.visitNotes);
    await m.createTable(db.visitPhotos);
  },
  // v9: SAP sales-area and commercial attributes on `customers`.
  //
  // Purely additive — every column is nullable or defaulted, so existing rows
  // upgrade without a rewrite and no data is touched. The two indexes back the
  // Sales Organization / Division filters (DATABASE_GUIDE.md §3).
  9: (m, db) async {
    await m.addColumn(db.customers, db.customers.salesOrg);
    await m.addColumn(db.customers, db.customers.division);
    await m.addColumn(db.customers, db.customers.distributionChannel);
    await m.addColumn(db.customers, db.customers.customerGroup);
    await m.addColumn(db.customers, db.customers.priceGroup);
    await m.addColumn(db.customers, db.customers.enName);
    await m.addColumn(db.customers, db.customers.khName);
    await m.addColumn(db.customers, db.customers.creditBalance);
    await m.addColumn(db.customers, db.customers.currency);
    await m.addColumn(db.customers, db.customers.taxNumber);
    await m.addColumn(db.customers, db.customers.totalOrders);
    await m.addColumn(db.customers, db.customers.createdAt);
    await m.addColumn(db.customers, db.customers.syncState);

    // `IF NOT EXISTS` keeps the step re-runnable after a crash mid-upgrade,
    // which DATABASE_GUIDE.md §5 requires of every migration.
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_customers_sales_org '
      'ON customers (sales_org);',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_customers_division '
      'ON customers (division);',
    );
  },
  // v10: three-tier stock status replaces numeric stock counting.
  //
  // `visit_stock_updates` is recreated (TableMigration) because two changes
  // can't be done additively: `stop_id` becomes nullable (depot counts have no
  // route stop) and `counted_quantity REAL` is dropped in favour of
  // `stock_level TEXT`. Existing counts are preserved, not discarded, via the
  // most conservative faithful mapping a raw count allows: 0 → 'low'
  // (out of stock), anything positive → 'medium' (stock was present, but a
  // unit count carries no defensible medium/high boundary). All other columns
  // — including the SyncableTable sync bookkeeping — copy across unchanged, so
  // a row captured offline before the upgrade still pushes after it.
  10: (m, db) async {
    // When the walk starts below v8, step 8's createTable already produced the
    // *current* (stock_level) shape — transforming a column that never existed
    // would fail, so the rebuild only runs for databases that really carry the
    // legacy quantity column.
    final columns = await db
        .customSelect("PRAGMA table_info('visit_stock_updates');")
        .get();
    final hasLegacyQuantity =
        columns.any((row) => row.data['name'] == 'counted_quantity');

    if (hasLegacyQuantity) {
      // TableMigration is drift's documented mechanism for column-shape
      // changes; marked experimental upstream but covered by the v9→v10
      // migration test.
      await m.alterTable(
        // ignore: experimental_member_use
        TableMigration(
          db.visitStockUpdates,
          newColumns: [db.visitStockUpdates.depotId],
          columnTransformer: {
            db.visitStockUpdates.stockLevel: const CustomExpression<String>(
              "CASE WHEN counted_quantity <= 0 THEN 'low' ELSE 'medium' END",
            ),
          },
        ),
      );
    }
    // TableMigration recreates the table; re-assert the stop index and add the
    // depot one. IF NOT EXISTS keeps the step re-runnable after a crash
    // mid-upgrade (DATABASE_GUIDE.md §5).
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_visit_stock_updates_stop '
      'ON visit_stock_updates (stop_id);',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_visit_stock_updates_depot '
      'ON visit_stock_updates (depot_id);',
    );
  },
  // v11: per-line product customization on the local cart.
  //
  // Purely additive — a single nullable TEXT column holding the customization
  // JSON blob (measurements, appearance, drawing path, notes). `cart_items` is
  // local-only and never synced, so no sync bookkeeping is involved; existing
  // rows upgrade untouched (null = a plain catalog line).
  //
  // The existence guard is required, not defensive padding. `m.createTable` in
  // step 6 builds `cart_items` from the *current* table definition, which
  // already includes this column — so a device walking from below v6 arrives
  // here with the column present and `ALTER TABLE ... ADD COLUMN` fails with
  // "duplicate column name". Step 10 guards the same hazard the same way.
  //
  // (Latent until schema v12 shipped: before then no migration walk reached
  // step 11 from below v6 in the covered paths, so the bug never fired.)
  11: (m, db) async {
    final columns =
        await db.customSelect("PRAGMA table_info('cart_items');").get();
    final alreadyPresent =
        columns.any((row) => row.data['name'] == 'customization_json');
    if (alreadyPresent) return;
    await m.addColumn(db.cartItems, db.cartItems.customizationJson);
  },
  // v12 (T1.5b): Orders domain, ported off the plaintext `catalog.db`.
  //
  // Creates the tables only — no data is copied here. The import from the
  // legacy file is a one-shot bootstrap step (`LegacyOrdersImporter`), not a
  // migration, for the same reason v7/v8 did it that way: a migration runs
  // inside drift's schema transaction and must stay deterministic, while the
  // import has to reconcile rows and decide whether purging the plaintext
  // source is safe.
  //
  // The two indexes are the ones `catalog.db` carried; they back the queue's
  // status filter and its per-quotation lookup.
  12: (m, db) async {
    await m.createTable(db.quotations);
    await m.createTable(db.salesOrders);
    await m.createTable(db.syncQueue);
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_status '
      'ON sync_queue (status);',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_quotation '
      'ON sync_queue (quotation_id);',
    );
  },
  // v13 (T1.5b): the resume pointer — the last live table in `routes.db`.
  //
  // Separate from v12 so a failure here leaves a coherent Orders schema rather
  // than a half-built cutover, matching the v7/v8 split.
  13: (m, db) async => m.createTable(db.workflowState),
  // v14: catalog taxonomy reset — no schema change, a data reset.
  //
  // The demo catalog's categories moved from invented steel groupings to the
  // ones derived from SAP's material master, so every `category_id` on disk
  // changed. Categories carry no tombstone (they are reference data replaced
  // wholesale on sync, not a syncable entity), so the retired rows would
  // survive and orphan `categoriesWithProducts()` — the product finder would
  // open on categories that dead-end on the first tap.
  //
  // Products go too: theirs point at category ids that no longer exist, which
  // reads as "catalog populated" while every guided-filter query returns
  // nothing. Child rows are deleted ahead of products because prices/stock
  // carry a foreign key onto it.
  //
  // Clearing `catalog_sync_meta` is the load-bearing line: `getLastSyncedAt`
  // is what `syncIfNeeded()` uses to choose initial vs delta, so leaving it
  // set would delta against the tables just emptied and repopulate almost
  // nothing.
  14: (m, db) async {
    await db.customStatement('DELETE FROM prices;');
    await db.customStatement('DELETE FROM stock;');
    await db.customStatement('DELETE FROM favorites;');
    await db.customStatement('DELETE FROM recent_products;');
    await db.customStatement('DELETE FROM products;');
    await db.customStatement('DELETE FROM categories;');
    await db.customStatement('DELETE FROM catalog_sync_meta;');
  },
};

/// Builds the [MigrationStrategy] for [db]: creates the schema on first run,
/// walks stepwise migrations on upgrade, records the version registry after
/// every transition, and enforces foreign keys on every connection.
MigrationStrategy buildMigrationStrategy(AppDatabase db) {
  return MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await db.appMetadataDao
          .setValue(SchemaMetadataKeys.schemaVersion, '$kCurrentSchemaVersion');
      await db.appMetadataDao.setValue(SchemaMetadataKeys.createdAt, _nowIso());
    },
    onUpgrade: (migrator, from, to) async {
      for (var v = from + 1; v <= to; v++) {
        final step = _stepwiseMigrations[v];
        if (step != null) {
          await step(migrator, db);
        }
      }
      await db.appMetadataDao.setValue(SchemaMetadataKeys.schemaVersion, '$to');
      await db.appMetadataDao
          .setValue(SchemaMetadataKeys.lastMigratedFrom, '$from');
      await db.appMetadataDao
          .setValue(SchemaMetadataKeys.lastMigratedAt, _nowIso());
    },
    beforeOpen: (details) async {
      await db.customStatement('PRAGMA foreign_keys = ON;');
    },
  );
}

String _nowIso() => DateTime.now().toUtc().toIso8601String();
