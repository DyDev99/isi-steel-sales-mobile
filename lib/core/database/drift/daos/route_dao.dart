import 'package:drift/drift.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/customers_table.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/route_tables.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/tables/syncable_table.dart';

part 'route_dao.g.dart';

/// A route plan plus its stops — the unit the sync upsert writes atomically.
///
/// Cross-table atomicity like this was structurally impossible under the old
/// three-plaintext-database split and is a named benefit of ADR-001.
class RouteWithStops {
  const RouteWithStops(this.route, this.stops);

  final RoutesCompanion route;
  final List<RouteStopsCompanion> stops;
}

/// A stop joined to the customer it visits.
///
/// The domain's `RouteStop` embeds the whole customer record, not an id, so the
/// read has to join. Under the old split that join was impossible across
/// database files — `routes.db` kept a denormalised copy of `customers` to fake
/// it, which is exactly the duplication T1.5 removes. One database, one real
/// join, one source of truth (ADR-001).
class RouteStopWithCustomer {
  const RouteStopWithCustomer(this.stop, this.customer);

  final RouteStopRow stop;

  /// Drift's data class for `customers`, which predates the `Row` suffix
  /// convention the T1.5 tables adopt. Renaming it would ripple through the
  /// already-shipped T2 customer code for no functional gain — tracked as
  /// follow-up naming drift, not fixed in passing (`playbook` §8).
  final Customer customer;
}

/// Scoped accessor for the route aggregate: plans, stops, and the delta cursor.
///
/// Replaces the hand-written SQL in `my_visits/data/local/route_local_data_source.dart`
/// (ADR-004: generated DAOs give compile-time safety the raw-SQL version could
/// not). Reads exclude soft-deleted rows — a row pending a delete-push is still
/// on disk (`docs/DATABASE_GUIDE.md` §3.1) but must not be shown to the user.
@DriftAccessor(tables: [Routes, RouteStops, RouteSyncMeta, Customers])
class RouteDao extends DatabaseAccessor<AppDatabase> with _$RouteDaoMixin {
  RouteDao(super.db);

  // ── Reads ───────────────────────────────────────────────────────────

  /// Routes planned for the calendar day containing [day].
  ///
  /// Compares against a half-open `[startOfDay, nextDay)` range rather than
  /// formatting a date string: `visit_date` is stored as an ISO-8601 UTC text
  /// column (`build.yaml`), so a string prefix match would break across
  /// timezones — exactly the ambiguity that build config exists to avoid.
  Future<List<RouteRow>> fetchRoutesForDay(DateTime day) {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(routes)
          ..where((t) => t.deleted.equals(false))
          ..where((t) => t.visitDate.isBiggerOrEqualValue(start))
          ..where((t) => t.visitDate.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.plannedStart)]))
        .get();
  }

  Future<RouteRow?> getRoute(String routeId) => (select(routes)
        ..where((t) => t.id.equals(routeId))
        ..where((t) => t.deleted.equals(false)))
      .getSingleOrNull();

  /// Stops of a route in visit order.
  Future<List<RouteStopRow>> fetchStops(String routeId) => (select(routeStops)
        ..where((t) => t.routeId.equals(routeId))
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
      .get();

  /// Stops joined to their customers, in visit order.
  ///
  /// An `innerJoin` rather than N per-stop lookups: a route has dozens of stops
  /// and the per-stop variant is the N+1 pattern `playbook` §9 rejects. The join
  /// is safe to make inner because `customer_id` is a non-null FK — a stop
  /// cannot exist without its customer.
  Future<List<RouteStopWithCustomer>> fetchStopsWithCustomers(
    String routeId,
  ) async {
    final query = select(routeStops).join([
      innerJoin(customers, customers.id.equalsExp(routeStops.customerId)),
    ])
      ..where(routeStops.routeId.equals(routeId))
      ..where(routeStops.deleted.equals(false))
      ..orderBy([OrderingTerm.asc(routeStops.sequence)]);

    final rows = await query.get();
    return rows
        .map((row) => RouteStopWithCustomer(
              row.readTable(routeStops),
              row.readTable(customers),
            ))
        .toList();
  }

  /// Reactive equivalent of [fetchRoutesForDay] — the UI rebuilds itself when
  /// a sync writes new plans, with no manual refresh
  /// (`docs/OFFLINE_FIRST.md` §1).
  Stream<List<RouteRow>> watchRoutesForDay(DateTime day) {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(routes)
          ..where((t) => t.deleted.equals(false))
          ..where((t) => t.visitDate.isBiggerOrEqualValue(start))
          ..where((t) => t.visitDate.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.plannedStart)]))
        .watch();
  }

  // ── Local mutations (mark dirty; the repository enqueues the sync row) ──
  //
  // These set `dirty`/`sync_state` but deliberately do NOT enqueue sync work:
  // per ADR-003 point 3 and ADR-006, the repository decides "this mutation
  // needs to sync" and wraps the write + the queue insert in ONE transaction.
  // The DAO only has to be transaction-composable, not sync-aware.

  Future<void> updateRouteStatus(String routeId, String status) =>
      (update(routes)..where((t) => t.id.equals(routeId))).write(
        RoutesCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now().toUtc()),
          dirty: const Value(true),
          syncState: const Value(SyncStates.dirty),
        ),
      );

  Future<void> updateStopStatus(
    String stopId, {
    required String status,
    DateTime? actualArrival,
    DateTime? actualDeparture,
  }) =>
      (update(routeStops)..where((t) => t.id.equals(stopId))).write(
        RouteStopsCompanion(
          status: Value(status),
          // Absent() rather than Value(null): omitting a field must leave the
          // stored value alone, not overwrite a recorded arrival with null.
          actualArrival: actualArrival == null
              ? const Value.absent()
              : Value(actualArrival),
          actualDeparture: actualDeparture == null
              ? const Value.absent()
              : Value(actualDeparture),
          updatedAt: Value(DateTime.now().toUtc()),
          dirty: const Value(true),
          syncState: const Value(SyncStates.dirty),
        ),
      );

  // ── Sync writes (pull) ──────────────────────────────────────────────

  /// Upserts routes and their stops in a single transaction.
  ///
  /// Stops are replaced wholesale per route rather than merged: the plan is
  /// SAP-owned, so a stop the server no longer sends has been removed from the
  /// plan and must not linger locally.
  ///
  /// A stop whose `customer_id` is not in the customer directory is rejected by
  /// the foreign key. That is deliberate — see [upsertRouteAttributesOnCustomer]
  /// for why route sync must not invent customers.
  Future<void> upsertRoutesWithStops(List<RouteWithStops> items) {
    return transaction(() async {
      for (final item in items) {
        await into(routes).insertOnConflictUpdate(item.route);
        final routeId = item.route.id.value;
        await (delete(routeStops)..where((t) => t.routeId.equals(routeId)))
            .go();
        for (final stop in item.stops) {
          await into(routeStops).insertOnConflictUpdate(stop);
        }
      }
    });
  }

  /// Applies the two route-execution attributes onto an **existing** customer.
  ///
  /// The legacy `routes.db` kept its own denormalised `customers` table; T1.5
  /// drops it because [Customers] is the single source of truth (ADR-001) and is
  /// SAP-controlled — "overwritten wholesale on every sync, never merged
  /// locally". Route sync therefore may not create or overwrite a customer; it
  /// may only contribute the two fields the customer directory doesn't carry.
  ///
  /// Returns the number of rows updated: `0` means the customer directory has
  /// not synced this customer yet, which the caller should treat as "skip this
  /// stop", not as an error.
  Future<int> upsertRouteAttributesOnCustomer(
    String customerId, {
    String? territoryType,
    double? geofenceRadiusOverride,
  }) =>
      (update(customers)..where((t) => t.id.equals(customerId))).write(
        CustomersCompanion(
          territoryType: territoryType == null
              ? const Value.absent()
              : Value(territoryType),
          geofenceRadiusOverride: geofenceRadiusOverride == null
              ? const Value.absent()
              : Value(geofenceRadiusOverride),
        ),
      );

  /// True when [customerId] exists in the directory — lets an import or sync
  /// skip orphan stops instead of triggering an FK violation.
  Future<bool> customerExists(String customerId) async {
    final row = await (select(customers)..where((t) => t.id.equals(customerId)))
        .getSingleOrNull();
    return row != null;
  }

  // ── Delta cursor ────────────────────────────────────────────────────

  Future<DateTime?> getLastSyncedAt(String entity) async {
    final row = await (select(routeSyncMeta)
          ..where((t) => t.entity.equals(entity)))
        .getSingleOrNull();
    return row?.lastSyncedAt;
  }

  Future<void> setLastSyncedAt(String entity, DateTime at) =>
      into(routeSyncMeta).insertOnConflictUpdate(
        RouteSyncMetaCompanion.insert(
          entity: entity,
          lastSyncedAt: Value(at),
        ),
      );
}
