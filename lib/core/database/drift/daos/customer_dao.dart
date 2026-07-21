import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/customer_related_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/customers_table.dart';

part 'customer_dao.g.dart';

/// Sort options for [CustomerDao.browse]. Declared here so the core DAO stays
/// decoupled from the feature's domain enum; the repository maps between them.
enum CustomerBrowseSort { recentOrder, nameAsc, nearest, valueDesc }

/// A SAP customer plus its contacts, the unit the sync upsert writes atomically.
class CustomerWithContacts {
  const CustomerWithContacts(this.customer, this.contacts);
  final CustomersCompanion customer;
  final List<CustomerContactsCompanion> contacts;
}

/// Scoped accessor for the whole customer directory (master + child tables).
/// All customer reads exclude soft-deleted rows.
@DriftAccessor(
  tables: [
    Customers,
    CustomerContacts,
    CustomerNotes,
    CustomerActivities,
    CustomerFavorites,
    CustomerRecent,
    CustomerSyncMeta,
  ],
)
class CustomerDao extends DatabaseAccessor<AppDatabase>
    with _$CustomerDaoMixin {
  CustomerDao(super.db);

  // ── Directory reads ────────────────────────────────────────────────

  /// Paginated browse mirroring the legacy data source: returns up to
  /// `pageSize + 1` rows so the caller can detect "has more" without a COUNT.
  /// Search is a case-insensitive LIKE across name/code/owner/phone (FTS5 is a
  /// planned optimization, tracked separately).
  Future<List<Customer>> browse({
    required int page,
    required int pageSize,
    String query = '',
    String? territory,
    String? status,
    String? productCategory,
    String? salesOrg,
    String? division,
    CustomerBrowseSort sort = CustomerBrowseSort.nameAsc,
  }) {
    final statement = select(customers)
      ..where((t) {
        var cond = t.deleted.equals(false);
        if (territory != null) cond = cond & t.territory.equals(territory);
        if (status != null) cond = cond & t.status.equals(status);
        if (productCategory != null) {
          cond = cond & t.productsPurchased.like('%$productCategory%');
        }
        // Sales area (schema v9). Index-backed — see idx_customers_sales_org /
        // idx_customers_division. Equality, not LIKE: these are SAP codes, so a
        // partial match would silently widen the filter.
        if (salesOrg != null) cond = cond & t.salesOrg.equals(salesOrg);
        if (division != null) cond = cond & t.division.equals(division);
        final trimmed = query.trim();
        if (trimmed.isNotEmpty) {
          // SQLite's LIKE is already case-insensitive for ASCII, which covers
          // the codes and Latin names searched here.
          final like = '%$trimmed%';
          cond = cond &
              (t.shopName.like(like) |
                  t.customerCode.like(like) |
                  t.ownerName.like(like) |
                  t.phone.like(like) |
                  // v9 fields — the brief's requirement that typing "PRD" or
                  // "Steel" finds customers by sales area, not just by name.
                  t.enName.like(like) |
                  t.khName.like(like) |
                  t.salesOrg.like(like) |
                  t.division.like(like));
        }
        return cond;
      })
      ..orderBy([(t) => _ordering(t, sort)])
      ..limit(pageSize + 1, offset: page * pageSize);
    return statement.get();
  }

  OrderingTerm _ordering($CustomersTable t, CustomerBrowseSort sort) {
    return switch (sort) {
      CustomerBrowseSort.recentOrder =>
        OrderingTerm(expression: t.lastOrderDate, mode: OrderingMode.desc),
      CustomerBrowseSort.nameAsc => OrderingTerm(expression: t.shopName),
      // Distance is computed client-side from GPS; fall back to freshness.
      CustomerBrowseSort.nearest =>
        OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      CustomerBrowseSort.valueDesc =>
        OrderingTerm(expression: t.lifetimeValue, mode: OrderingMode.desc),
    };
  }

  Stream<List<Customer>> watchByTerritory(String territory) {
    return (select(customers)
          ..where(
              (t) => t.territory.equals(territory) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.shopName)]))
        .watch();
  }

  Future<Customer?> getById(String id) {
    return (select(customers)
          ..where((t) => t.id.equals(id) & t.deleted.equals(false)))
        .getSingleOrNull();
  }

  Future<List<CustomerContact>> fetchContacts(String customerId) {
    return (select(customerContacts)
          ..where((t) => t.customerId.equals(customerId)))
        .get();
  }

  Future<int> countByTerritory(String territory) async {
    final countExp = customers.id.count();
    final query = selectOnly(customers)
      ..where(customers.territory.equals(territory) &
          customers.deleted.equals(false))
      ..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  // ── Sync writes (the only path that populates customers/contacts) ───

  /// Atomically replaces each customer and its contacts. Mirrors the legacy
  /// transactional upsert (minus the FTS index, handled by [browse]'s LIKE).
  Future<void> upsertCustomers(List<CustomerWithContacts> records) async {
    if (records.isEmpty) return;
    await transaction(() async {
      for (final record in records) {
        final id = record.customer.id.value;
        await into(customers).insert(record.customer,
            onConflict: DoUpdate((_) => record.customer));
        await (delete(customerContacts)..where((t) => t.customerId.equals(id)))
            .go();
        for (final contact in record.contacts) {
          await into(customerContacts).insert(contact);
        }
      }
    });
  }

  Future<void> markDeleted(List<String> ids) async {
    if (ids.isEmpty) return;
    await (update(customers)..where((t) => t.id.isIn(ids)))
        .write(const CustomersCompanion(deleted: Value(true)));
  }

  Future<int> softDelete(String id) {
    return (update(customers)..where((t) => t.id.equals(id)))
        .write(const CustomersCompanion(deleted: Value(true)));
  }

  // ── Notes (rep-owned) ──────────────────────────────────────────────

  Future<List<CustomerNote>> fetchNotes(String customerId) {
    return (select(customerNotes)
          ..where((t) => t.customerId.equals(customerId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<void> addNote(CustomerNotesCompanion note) =>
      into(customerNotes).insert(note);

  // ── Activities (rep-owned) ─────────────────────────────────────────

  Future<List<CustomerActivity>> fetchActivities(String customerId) {
    return (select(customerActivities)
          ..where((t) => t.customerId.equals(customerId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<void> addActivity(CustomerActivitiesCompanion activity) =>
      into(customerActivities).insert(activity);

  // ── Favorites / recent (local UI state) ────────────────────────────

  Future<void> toggleFavorite(String customerId) async {
    final existing = await (select(customerFavorites)
          ..where((t) => t.customerId.equals(customerId)))
        .getSingleOrNull();
    if (existing != null) {
      await (delete(customerFavorites)
            ..where((t) => t.customerId.equals(customerId)))
          .go();
    } else {
      await into(customerFavorites).insert(
        CustomerFavoritesCompanion.insert(
          customerId: customerId,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<List<Customer>> fetchFavorites() {
    final query = select(customerFavorites).join([
      innerJoin(
          customers, customers.id.equalsExp(customerFavorites.customerId)),
    ])
      ..where(customers.deleted.equals(false))
      ..orderBy([
        OrderingTerm(
            expression: customerFavorites.createdAt, mode: OrderingMode.desc)
      ]);
    return query.map((row) => row.readTable(customers)).get();
  }

  Future<void> recordViewed(String customerId) {
    return into(customerRecent).insertOnConflictUpdate(
      CustomerRecentCompanion.insert(
        customerId: customerId,
        viewedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<List<Customer>> fetchRecent({int limit = 20}) {
    final query = select(customerRecent).join([
      innerJoin(customers, customers.id.equalsExp(customerRecent.customerId)),
    ])
      ..where(customers.deleted.equals(false))
      ..orderBy([
        OrderingTerm(
            expression: customerRecent.viewedAt, mode: OrderingMode.desc)
      ])
      ..limit(limit);
    return query.map((row) => row.readTable(customers)).get();
  }

  // ── Sync metadata ──────────────────────────────────────────────────

  Future<DateTime?> getLastSyncedAt(String entity) async {
    final row = await (select(customerSyncMeta)
          ..where((t) => t.entity.equals(entity)))
        .getSingleOrNull();
    return row?.lastSyncedAt;
  }

  Future<void> setLastSyncedAt(String entity, DateTime at) {
    return into(customerSyncMeta).insertOnConflictUpdate(
      CustomerSyncMetaCompanion.insert(
        entity: entity,
        lastSyncedAt: Value(at),
      ),
    );
  }
}
