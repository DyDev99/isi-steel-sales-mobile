# ADR-011 — Local mirror tables carry no foreign keys; the backend owns referential integrity

- **Status**: Accepted
- **Date**: 2026-08-24
- **Supersedes**: the referential-integrity claim in ADR-001 (that ADR's other decisions stand)
- **Related**: ADR-002 (offline-first), ADR-004 (DAO pattern), ADR-006 (sync engine), `docs/DATABASE_GUIDE.md` §3, `docs/backend-document.md` §5, `docs/customers-guidline-integrateion-mobile.md`

---

## Context

ADR-001 consolidated three plaintext `sqflite` files into one encrypted Drift
database and listed **real referential integrity** among the wins: with one file,
`route_stops.customer_id` could finally be a genuine foreign key into `customers`,
and visit captures could cascade from the stop they belong to. That was
structurally impossible before, and it was adopted as a benefit in its own right.

In production shape, those constraints cost data rather than protecting it. Two
failures were reproduced against the v17 schema.

### Failure 1 — one unknown customer destroyed the rep's entire day

`RouteDao.upsertRoutesWithStops` writes a route and all of its stops in one
transaction. With `PRAGMA foreign_keys = ON` and
`route_stops.customer_id REFERENCES customers (id)`, a single stop referencing a
customer the directory had not pulled yet aborted the whole transaction:

```
SqliteException(787): FOREIGN KEY constraint failed
routes persisted: 0    stops persisted: 0
```

A five-stop day where four stops were perfectly valid persisted **nothing**.

This is not an edge case. Routes and customers arrive from **two different
endpoints**, paged independently, scoped differently — the route feed returns the
customers on a rep's routes, the directory returns the customers assigned to that
rep, and `GET /mobile/customers` pages at 200 rows. Nothing in
`docs/backend-document.md` promises an arrival order, and
`docs/customers-guidline-integrateion-mobile.md` documents scoping that makes a
permanent mismatch legitimate. The schema demanded an ordering guarantee the
server never offered.

The workaround already in the code shows the cost being paid elsewhere:
`RouteDao.customerExists` exists purely so imports can *skip orphan stops*, and
`VisitStockUpdates.depotId` already carries the comment *"No FK: depot counts may
reference customers synced later than the capture."* The exception had been
discovered piecemeal; this ADR generalises it.

### Failure 2 — a routine sync silently deleted captured field work

Every `visit_*` table cascaded from `route_stops`, and route sync **replaces** a
route's stops on each run (delete-then-insert). So an ordinary delta erased work
the rep had captured and not yet pushed:

```
BEFORE re-sync: check_ins=1 notes=1
AFTER  re-sync: check_ins=0 notes=0
```

`docs/backend-document.md` §5.2 states that re-sending the complete current set
every time is *"acceptable and expected"*. The client therefore destroyed
first-hand captures in response to documented, correct server behaviour. The same
cascade reached `fraud_flags.stop_id` — compliance evidence deleted by a route
refresh, which inverts the purpose of the flag.

`docs/SYNC_ENGINE.md` §5 classifies these captures as client-authoritative: the
server has no competing version of an observation a rep made. Losing one is the
exact failure the offline-first design exists to prevent (ADR-002).

## Decision

**Tables that mirror backend-owned state carry no foreign keys. The device stores
what it was sent and renders it.**

The backend validates these relationships before the row is ever transmitted, so
re-enforcing them on the device adds no correctness and converts benign ordering
differences into data loss.

Removed in schema v18:

| Constraint | Failure it caused |
|---|---|
| `route_stops.route_id`, `route_stops.customer_id` | 1 |
| `customer_contacts/notes/activities/favorites/recent.customer_id` | 1 (same class) |
| `visit_*.stop_id` (8 tables) | 2 |
| `fraud_flags.stop_id` | 2, on compliance evidence |

Kept, because they have no data-loss path:

| Constraint | Why it still earns its place |
|---|---|
| `prices`, `stock`, `favorites`, `recent_products` → `products` | Parent and children arrive in one payload from one endpoint; no ordering hazard exists |
| `location_samples.route_id`, `fraud_flags.route_id` (cascade) | Nothing hard-deletes a route — sync upserts — so the cascade never fires in normal operation, and it gives correct cleanup if a route is ever purged |

Two supporting changes make the removal actually work:

1. **`route_customers`** — a new flat table holding the customer rows the route
   feed already sends (`docs/backend-document.md` §7.1 `CustomerStopInfo`). Route
   sync stores them instead of discarding them, so a stop renders from the route
   feed alone. This also removes `my_visits`' dependency on the customer
   feature's tables, which `CLAUDE.md` §4 forbids independently.

2. **`fetchStopsWithCustomers` uses a `leftOuterJoin`.** The inner join was
   justified in a comment by the very foreign key being removed (*"safe to make
   inner because `customer_id` is a non-null FK"*). Left unchanged it would have
   inherited the same failure in a worse form — a stop silently missing from the
   rep's day instead of a loud error.

## Consequences

**Positive**

- A rep keeps their whole route when one customer is unrecognised, and keeps
  every capture across a re-sync. Both are covered by regression tests
  (`mirror_table_resilience_test.dart`).
- Route sync and customer sync are genuinely independent; the ordering
  dependency `docs/ARCHITECTURE.md` §4 imposed on them is gone, along with the
  `customerExists` skip-logic it forced.
- The device stops enforcing a rule it holds only partial data for. Scoping means
  a rep legitimately sees route stops for customers outside their directory
  scope; the old schema treated that legitimate state as corruption.

**Negative**

- SQLite no longer prevents an orphan row. This is accepted deliberately: an
  orphan is invisible (every read filters by its parent id) and self-heals on the
  next sync, whereas the constraint's failure mode was permanent loss of data
  that existed nowhere else.
- `route_customers` duplicates customer fields already in `customers`. This is
  the payload's own copy, used only to render stops, and never read by the
  Customers feature — the two are separate feeds with separate owners, not two
  representations of one truth.
- v18 rebuilds 15 tables via `TableMigration`. Covered by
  `adr011_v17_to_v18_migration_test.dart`, which asserts row preservation,
  content integrity, the fail-closed geofence backfill, and constraint removal.
- ADR-001's integrity claim no longer holds. Its other decisions — one encrypted
  database, one migrator, generated DAOs, cross-entity transactions — are
  unaffected, and cross-table atomicity is what makes the new write paths safe.

## Alternatives considered

**Keep the constraints, filter orphans before writing.** Rejected: it preserves
the route by *dropping the stop*, so the rep still cannot see or check into a
visit the server assigned them. It also puts the burden on every future sync path
to remember the workaround — which is how `depotId` and `customerExists` came to
exist in the first place.

**Remove every foreign key, including catalog.** Rejected as broader than the
evidence. Catalog children arrive in the same payload as their parent, so no
ordering hazard exists and nothing is lost by leaving them enforced.
