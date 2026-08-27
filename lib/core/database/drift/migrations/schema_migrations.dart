// ignore_for_file: experimental_member_use
import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';

/// The single source of truth for the encrypted database's schema version.
/// Bump this by exactly one whenever a schema change ships, and add the matching
/// step to [_stepwiseMigrations].
const int kCurrentSchemaVersion = 20;

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
  // v15: localisation and ERP master-data columns on the catalog.
  //
  // Products gain the Khmer name, colour, specification and SAP creation date;
  // categories become a real taxonomy node (SAP code, both names, description,
  // icon, active flag, timestamps) instead of an id/name/order triple.
  //
  // Every column is added with a default or as nullable, so this is a pure
  // widening — existing rows stay valid and no data is rewritten. The catalog
  // is re-pulled from SAP anyway; the sync watermark is cleared at the end so
  // the next open backfills the new columns rather than deltaing against rows
  // that predate them.
  15: (m, db) async {
    // Only add what is genuinely missing.
    //
    // A walk starting below v4 hits `createTable(categories/products)` first,
    // and `createTable` emits the table's *current* definition — which already
    // contains these columns. Re-adding them then fails with "duplicate column
    // name" and strands the upgrade. Same trap v10 documents for
    // `visit_stock_updates`; the fix is to ask the database what it actually
    // has rather than assuming what version it came from.
    Future<Set<String>> columnsOf(String table) async {
      final rows = await db.customSelect("PRAGMA table_info('$table');").get();
      return rows.map((r) => r.data['name'] as String).toSet();
    }

    Future<void> addMissing(
      TableInfo<Table, dynamic> table,
      Set<String> existing,
      List<GeneratedColumn<Object>> columns,
    ) async {
      for (final column in columns) {
        if (existing.contains(column.name)) continue;
        await m.addColumn(table, column);
      }
    }

    await addMissing(db.products, await columnsOf('products'), [
      db.products.nameKh,
      db.products.color,
      db.products.specification,
      db.products.createdAt,
    ]);

    await addMissing(db.categories, await columnsOf('categories'), [
      db.categories.code,
      db.categories.nameKh,
      db.categories.description,
      db.categories.descriptionKh,
      db.categories.icon,
      db.categories.active,
      db.categories.createdAt,
      db.categories.updatedAt,
    ]);

    // Forces the next sync down the initial path so the widened columns are
    // populated — a delta would only touch rows SAP happens to have changed.
    await db.customStatement('DELETE FROM catalog_sync_meta;');
  },
  // v16: `customers.sap_customer_id` becomes nullable.
  //
  // The column was `text().unique()` and the API mapper collapsed a missing
  // SAP id to `''`. SQLite treats every NULL as distinct but `''` as one
  // value, so the *second* customer without a SAP id violated the constraint
  // and aborted the entire sync batch with
  // `UNIQUE constraint failed: customers.sap_customer_id`. That is the normal
  // case, not an edge one: a customer registered in the field has no SAP
  // identity until it is approved and pushed, so a fresh territory is mostly
  // `PendingApproval` rows with none.
  //
  // `alterTable` recreates the table with the current definition and copies
  // the data across, because SQLite cannot drop a NOT NULL constraint in
  // place.
  16: (m, db) async {
    await m.alterTable(TableMigration(db.customers));

    // Existing placeholders become real absences, so they stop competing for
    // the single `''` slot the old constraint allowed.
    await db
        .customSelect(
          "UPDATE customers SET sap_customer_id = NULL "
          "WHERE sap_customer_id = '';",
        )
        .get();
  },

  // v17: cart lines carry their own agreed price and fulfillment terms.
  //
  // Both columns are additive and nullable, so this is a pure `addColumn` with
  // no data rewrite and no destructive step. Existing rows stay NULL, which the
  // repository reads as "price this line from the live catalog row" — exactly
  // the behaviour those rows already had. A rep who upgrades mid-visit finds
  // their cart unchanged.
  //
  // Why a snapshot at all: `prices` is SAP-controlled and replaced wholesale on
  // sync, so a quotation saved on Monday re-priced itself on Tuesday. The
  // stored `quotations.total` then disagreed with the lines rendered under it,
  // and the PDF the customer was holding disagreed with both.
  17: (m, db) async {
    await _addColumnIfMissing(m, db, db.cartItems, db.cartItems.unitPrice);
    await _addColumnIfMissing(
        m, db, db.cartItems, db.cartItems.fulfillmentJson);
  },

  // v18 (ADR-011): the local database becomes a flat mirror of what the
  // backend sends, instead of re-enforcing relationships the backend already
  // enforced before the row was ever transmitted.
  //
  // This removes constraints. Nothing is dropped, no column changes type, and
  // every row is copied across — `alterTable` recreates each table from its
  // current Dart definition (now without the foreign key) and moves the data.
  //
  // ## Why, concretely
  //
  // Two verified data-loss paths, both triggered by ordinary operation:
  //
  //   1. `route_stops.customer_id -> customers` aborted the *whole* route
  //      transaction (`SqliteException(787)`) when a single stop referenced a
  //      customer the directory had not pulled yet. The route feed and the
  //      customer feed are separate, independently-paged endpoints, so this is
  //      routine — and it cost the rep every stop of the day, not one.
  //
  //   2. The `visit_* -> route_stops ON DELETE CASCADE` chain silently deleted
  //      captured check-ins, notes and photos whenever route sync refreshed a
  //      route, because the refresh replaces a route's stops. The backend
  //      documents re-sending the full set as expected behaviour
  //      (`docs/integrations/backend-document.md` §5.2), so this fired on a normal delta and
  //      destroyed first-hand field work that had not been pushed yet.
  //
  // The constraints that have no such path are deliberately kept — see the
  // foreign-key test for the surviving set and the reason each one earns it.
  18: (m, db) async {
    // The route feed's own customer rows, so a stop renders without the
    // customer directory having synced first.
    await m.createTable(db.routeCustomers);

    // Backfill from the directory for stops that already exist on this device,
    // so an upgrading rep sees exactly what they saw before rather than a
    // screen of blank stop cards until the next route sync lands.
    //
    // `territory_type` falls back to 'urban' to preserve the fail-closed
    // geofence default documented on `kUnknownTerritoryFallback` — urban is the
    // tightest radius, so an unknown territory blocks a check-in rather than
    // waving it through.
    await db.customStatement(
      'INSERT OR IGNORE INTO route_customers '
      '(id, name, name_kh, code, contact, phone, address, territory, '
      'territory_type, latitude, longitude, geofence_radius_override) '
      'SELECT c.id, c.shop_name, COALESCE(c.kh_name, \'\'), c.customer_code, '
      'c.owner_name, c.phone, c.address, c.territory, '
      "COALESCE(c.territory_type, 'urban'), c.latitude, c.longitude, "
      'c.geofence_radius_override '
      'FROM customers c '
      'WHERE c.id IN (SELECT DISTINCT customer_id FROM route_stops);',
    );

    // Customer child tables — orphans here are invisible, not corrupting.
    await m.alterTable(TableMigration(db.customerContacts));
    await m.alterTable(TableMigration(db.customerNotes));
    await m.alterTable(TableMigration(db.customerActivities));
    await m.alterTable(TableMigration(db.customerFavorites));
    await m.alterTable(TableMigration(db.customerRecent));

    // Route stops (failure 1) and the fraud-flag -> stop cascade (failure 2,
    // applied to compliance evidence).
    await m.alterTable(TableMigration(db.routeStops));
    await m.alterTable(TableMigration(db.fraudFlags));

    // Visit captures (failure 2).
    await m.alterTable(TableMigration(db.visitCheckIns));
    await m.alterTable(TableMigration(db.visitCheckOuts));
    await m.alterTable(TableMigration(db.visitOrderLines));
    await m.alterTable(TableMigration(db.visitStockUpdates));
    await m.alterTable(TableMigration(db.visitReturns));
    await m.alterTable(TableMigration(db.visitCollections));
    await m.alterTable(TableMigration(db.visitNotes));
    await m.alterTable(TableMigration(db.visitPhotos));
  },

  // v19: the notification inbox becomes a first-class local mirror.
  //
  // Purely additive — three new tables, nothing existing is touched, so an
  // upgrade cannot lose or rewrite a row. `IF NOT EXISTS` on the indexes keeps
  // the step re-runnable after a crash mid-upgrade
  // (`docs/blueprints/DATABASE_GUIDE.md` §5); `createTable` is already idempotent-safe
  // here because these tables cannot exist below v19.
  //
  // ## Why the inbox needs storage at all
  //
  // `docs/features/notification-mobile.md` §1: the inbox *is* the notification
  // and push is only an accelerator, because a push routinely never arrives —
  // a flat battery, a coverage hole, an OEM battery optimiser, a rotated FCM
  // token, or a P4 that is never pushed by design. A client whose only render
  // path is the FCM callback shows a rep less than half their work.
  //
  // ## Why it is in the encrypted database rather than Hive
  //
  // A notification title and body name a customer and a route, which is PII and
  // therefore belongs in the encrypted store, not a key-value cache
  // (`docs/skills/SECURITY.md` §3, `docs/blueprints/ARCHITECTURE.md` §3). The FCM payload is
  // deliberately thinner for the same reason (§9.2): a push renders on a locked
  // screen in front of whoever is holding the phone.
  //
  // ## Why three tables and not one
  //
  //  * `notifications` is a **pull-only mirror** and carries no `SyncableTable`
  //    bookkeeping: nothing here originates on the device, and the id is the
  //    server's own so a catch-up overlapping a push cannot duplicate a row.
  //  * `notification_action_queue` is the **outbox** — the discrete acts the rep
  //    performed. ADR-006 requires a state change and its queued call to commit
  //    in one transaction, which is what `NotificationDao` enforces; a visible
  //    acknowledgement with no queued call is a route the supervisor still
  //    believes was never acknowledged.
  //  * `notification_sync_meta` holds the cursor and the reconciled counts, in
  //    the same database as the rows so sign-out drops all three together. A
  //    cursor that outlives its rows asks for "changes since" a point whose rows
  //    are gone, receives an empty delta, and leaves a permanently blank inbox
  //    with no error anywhere.
  //
  // No foreign keys, per ADR-011 — and here the reason is concrete rather than
  // precautionary: a push can land before the catch-up page that carries its
  // notification, so a queue row can legitimately reference a row this device
  // has not stored yet. Enforcing the constraint would abort that write and
  // lose the rep's acknowledgement instead of harmlessly orphaning a row.
  19: (m, db) async {
    // Guarded, not a bare `createTable`. [SchemaMigrationStep] requires every
    // step to be idempotent-safe, and `CREATE TABLE` is not: SQLite fails the
    // whole upgrade with "table already exists", which on a real device leaves
    // the user on a database that will not open.
    //
    // That is not hypothetical — it is how the migration fixtures work. They
    // build the *current* schema with Drift's own DDL and then rewind
    // `user_version`, deliberately, so a fixture cannot drift from reality. Every
    // replayed step therefore meets objects that already exist. Steps 10, 11 and
    // 15 guard the same hazard the same way.
    await _createTableIfMissing(m, db, db.notifications);
    await _createTableIfMissing(m, db, db.notificationActionQueue);
    await _createTableIfMissing(m, db, db.notificationSyncMeta);
  },
  // v20: the bundled Cambodian administrative gazetteer.
  //
  // The tables are created empty. Populating them is the seed importer's job
  // (`GeoSeedAssetLoader`), not the migrator's, for two reasons: reading a
  // 1.3 MB asset and inserting 16,000 rows inside `onUpgrade` would block the
  // first frame on the launch that happens to upgrade, and a migration that
  // depends on an asset bundle cannot be replayed by the schema fixtures,
  // which have no Flutter binding. The importer runs after startup and is
  // idempotent, so an interrupted seed simply re-runs.
  20: (m, db) async {
    await _createTableIfMissing(m, db, db.geoProvinces);
    await _createTableIfMissing(m, db, db.geoDistricts);
    await _createTableIfMissing(m, db, db.geoCommunes);
    await _createTableIfMissing(m, db, db.geoVillages);
  },
};

/// `createTable`, skipped when the table is already there.
///
/// See the note in the v19 step for why this is required rather than defensive:
/// a replayed `CREATE TABLE` aborts the entire upgrade.
Future<void> _createTableIfMissing(
  Migrator m,
  AppDatabase db,
  TableInfo<Table, dynamic> table,
) async {
  final existing = await db.customSelect(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?;",
    variables: [Variable<String>(table.actualTableName)],
  ).get();
  if (existing.isNotEmpty) return;
  await m.createTable(table);
}

/// `addColumn`, skipped when the column is already there.
///
/// [SchemaMigrationStep] requires every step to be idempotent-safe, and a bare
/// `addColumn` is not: SQLite fails the whole upgrade with
/// `duplicate column name`, which on a real device leaves the user on a
/// database that will not open.
///
/// That is not hypothetical. The migration fixtures build the *current* schema
/// with Drift's own DDL and then rewind `user_version` — deliberately, so the
/// fixture cannot drift from reality — which means every replayed step meets
/// columns that already exist. Any additive migration has to tolerate that, or
/// each new one silently breaks every fixture before it.
Future<void> _addColumnIfMissing(
  Migrator m,
  AppDatabase db,
  TableInfo<Table, dynamic> table,
  GeneratedColumn<Object> column,
) async {
  final existing = await db
      .customSelect('PRAGMA table_info(${table.actualTableName});')
      .get();
  final present =
      existing.any((row) => row.read<String>('name') == column.name);
  if (present) return;
  await m.addColumn(table, column);
}

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
