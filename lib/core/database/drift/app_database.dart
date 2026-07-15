import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/connection/encrypted_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/app_metadata_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/cart_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/catalog_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/customer_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/route_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/route_telemetry_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/visit_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/migrations/schema_migrations.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/app_metadata_table.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/cart_items_table.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/catalog_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/customer_related_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/customers_table.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/route_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/visit_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/secure/app_database_key_provider.dart';

part 'app_database.g.dart';

/// The single, SQLCipher-encrypted application database.
///
/// This is the one and only Drift database for the app — all feature tables
/// are added here in later tasks (T1.3 / T2), replacing the per-feature plain
/// `sqflite` stores. Keeping one database means cross-feature transactions and
/// a single, coordinated migration path.
///
/// Construct it via [AppDatabase.encrypted] so it can never be opened without
/// the SQLCipher key.
@DriftDatabase(
  tables: [
    AppMetadata,
    Customers,
    CustomerContacts,
    CustomerNotes,
    CustomerActivities,
    CustomerFavorites,
    CustomerRecent,
    CustomerSyncMeta,
    Categories,
    Products,
    Prices,
    Stock,
    ProductFavorites,
    RecentProducts,
    CatalogSyncMeta,
    CartItems,
    // Route domain (T1.5, v7) — ported from the plaintext `routes.db`.
    Routes,
    RouteStops,
    LocationSamples,
    FraudFlags,
    RouteSyncMeta,
    // Visit captures (T1.5, v8) — ported from the plaintext `routes.db`.
    VisitCheckIns,
    VisitCheckOuts,
    VisitOrderLines,
    VisitStockUpdates,
    VisitReturns,
    VisitCollections,
    VisitNotes,
    VisitPhotos,
  ],
  daos: [
    AppMetadataDao,
    CustomerDao,
    CatalogDao,
    CartDao,
    // Route domain (T1.5) — one DAO per aggregate (ADR-004).
    RouteDao,
    RouteTelemetryDao,
    VisitDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the production database backed by SQLCipher, keyed by the composite
  /// passphrase resolved through [keyProvider].
  factory AppDatabase.encrypted(AppDatabaseKeyProvider keyProvider) =>
      AppDatabase(openEncryptedDatabase(keyProvider));

  /// Single source of truth in [kCurrentSchemaVersion]; bumped per schema change.
  @override
  int get schemaVersion => kCurrentSchemaVersion;

  /// Create/upgrade/registry logic lives in the migrations module (T1.4).
  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);
}
