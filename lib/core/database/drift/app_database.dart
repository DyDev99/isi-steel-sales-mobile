import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/connection/database_connection.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/app_metadata_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/cart_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/catalog_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/customer_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/route_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/route_telemetry_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/order_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/visit_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/daos/workflow_state_dao.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/migrations/schema_migrations.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/app_metadata_table.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/cart_items_table.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/catalog_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/customer_related_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/customers_table.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/order_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/route_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/visit_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/workflow_state_table.dart';
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
    // Orders domain (T1.5b, v12) — ported from the plaintext `catalog.db`.
    Quotations,
    SalesOrders,
    SyncQueue,
    // Resume pointer (T1.5b, v13) — the last table in the plaintext `routes.db`.
    WorkflowState,
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
    // Orders domain + resume pointer (T1.5b).
    QuotationDao,
    SalesOrderDao,
    SyncQueueDao,
    WorkflowStateDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the production database for the current platform.
  ///
  /// **On Android/iOS** this is what the name says: SQLCipher, keyed by the
  /// composite passphrase resolved through [keyProvider], refusing to open at
  /// all if encryption is not active (ADR-008).
  ///
  /// **On web** there is no SQLCipher and no persistence — the executor is an
  /// in-memory `sqlite3.wasm` database and [keyProvider] is ignored (ADR-010).
  /// The name is kept because renaming it would churn every call site to
  /// describe a platform difference that this class deliberately does not have;
  /// the platform split lives entirely in `connection/database_connection.dart`,
  /// which is the one file to read for the real guarantees.
  factory AppDatabase.encrypted(AppDatabaseKeyProvider keyProvider) =>
      AppDatabase(openAppDatabaseConnection(keyProvider));

  /// Single source of truth in [kCurrentSchemaVersion]; bumped per schema change.
  @override
  int get schemaVersion => kCurrentSchemaVersion;

  /// Create/upgrade/registry logic lives in the migrations module (T1.4).
  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);
}
