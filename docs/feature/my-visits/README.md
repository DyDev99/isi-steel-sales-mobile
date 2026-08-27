# My Visits

> **Purpose:** route execution — a rep is assigned a daily route of ordered
> customer stops, walks each one with geofence-verified check-in/out, captures
> market data, and can pivot straight into a quotation.
> **Code:** `lib/features/my_visits/`
> **Verified:** 2026-08-27, branch `web` @ `142de9b`.

The second-largest feature in the app (7 screens, 25 widgets, 10 blocs, 30 use
cases, 24 entities, 11 local data sources) and the one that most depends on the
app working with no signal.

---

## Documents

| Document | What it covers |
|---|---|
| [architecture.md](architecture.md) | The architecture report and redesign plan — every screen, bloc, nav helper, and the `WorkflowSession` resume path, traced from source. |
| [workflow.md](workflow.md) | Folder structure and the step-by-step visit workflow. |
| [api.md](api.md) | Backend API specification for routes and visits. **Status: proposal to the backend team**, derived from the shipped client — where the client already parses a field, that field is a hard requirement. Items marked **OPEN** are still undecided. |

---

## Screens

| Screen | File |
|---|---|
| Stops check-in | `presentation/screens/stops_check_in_screen.dart` |
| Stop dashboard | `presentation/screens/stop_dashboard/stop_dashboard_screen.dart` |
| Stop information | `presentation/screens/stop_information/stop_information_screen.dart` |
| Order history (per stop) | `presentation/screens/stop_information/order_history_screen.dart` |
| Promotions (per stop) | `presentation/screens/stop_information/promotions_screen.dart` |
| Inventory visible (depot stock audit) | `presentation/screens/inventory_visible/inventory_visible_screen.dart` |
| Inventory completion | `presentation/screens/inventory_visible/inventory_completion_screen.dart` |

Reached via `MainShell` tab 2, or directly at `/my-visits` (which builds
`StopDashboardScreen` with its own providers).

---

## State

| Bloc / Cubit | Responsibility |
|---|---|
| `ActiveRouteBloc` | The route currently being executed |
| `RouteDashboardCubit` | Route-level summary |
| `StopDashboardCubit` | One stop's dashboard |
| `VisitCubit` | Check-in / check-out and visit capture |
| `LocationTrackingCubit` | Continuous telemetry during a route |
| `RouteSyncCubit` | Route pull and visit push |
| `ResumableVisitCubit` | Surfaces the "continue where you left off" banner; refreshed when the user returns to shell tab 0 |
| `NavigationStateCubit` | Persisted workflow position |
| `DepotSelectionCubit` | Depot chosen for the stock audit |
| `DepotStockCountCubit` | ⚠ **Registered in DI but consumed by no screen** — see Known gaps |

---

## Data

| Domain repository | Purpose |
|---|---|
| `RouteRepository` | Route plans and stops |
| `VisitRepository` | Visit records and check-in/out |
| `RouteSyncRepository` / `VisitSyncRepository` | Delta pull and batch push |
| `LocationSampleRepository` | Telemetry samples |
| `ActiveWorkflowRepository` | The resume pointer |

Tables: `route_tables.dart`, `visit_tables.dart`, `workflow_state_table.dart`.
DAOs: `route_dao.dart`, `visit_dao.dart`, `route_telemetry_dao.dart`,
`workflow_state_dao.dart`.

`data/local/` still holds both `*_local_data_source.dart` (legacy `sqflite`) and
`*_drift_local_data_source.dart` (current) — the legacy pair exists for the
one-time import path, not as a live persistence route.

---

## Offline behaviour

This feature is the reason the app is offline-first. A rep on a rural route has
no signal for hours.

| Action | Offline |
|---|---|
| View today's route and stops | ✅ Fully |
| Check in / check out | ✅ Recorded locally; geofence verdict marked unverified when location is unavailable |
| Capture stock counts, market data, photos | ✅ Fully local |
| Resume an interrupted visit | ✅ From the local `workflow_state` row — survives a process kill |
| Location telemetry | ✅ Buffered locally, pushed on reconnect |
| Pull a new route | ❌ Needs connectivity |
| Push completed visits | ❌ Queued; drains on reconnect |

---

## Resumability

An interrupted visit resumes into the exact screen it left, driven by a single
registry in `presentation/navigation/resume_workflow_dispatcher.dart`. A builder
that cannot rebuild (stop reassigned, args stale) returns `null` and the
dispatcher degrades to guided stop resume rather than routing to a broken
screen. Adding a resumable screen is one registry entry.

Design rationale: [../../adr/ADR-0007-workflow-session.md](../../adr/ADR-0007-workflow-session.md).
Route table and dispatch flow: [../../blueprint/navigation-architecture.md](../../blueprint/navigation-architecture.md#resumable-workflows-my_visits).

---

## Device capabilities

Location (fine, coarse, and background), foreground service for telemetry, camera
and gallery for capture, gallery save via `gal`, and Google Maps for the transit
view. Permission table and failure behaviour:
[../../blueprint/device-integration.md](../../blueprint/device-integration.md).

---

## Tests

`test/features/my_visits/` — 19 files, the densest feature coverage in the repo:
route/visit Drift data sources, sync scope and failure paths, dashboard cubit,
stop distance sorting, stock level, inventory visibility, workflow step updates,
route feed fixtures, screen layout.

---

## Known gaps

- **`DepotStockCountCubit` and `DepotStockCountState` are dead wiring.** Both are
  registered in `my_visits_injection.dart`, but no screen consumes them.
  `inventory_visible_screen.dart` — which *is* the depot stock visual audit —
  renders **mock data** from its own file instead. Either wire the cubit or
  remove the registration; leaving both invites someone to "fix" the mock by
  duplicating the cubit's logic a third time.
- **[api.md](api.md) is a proposal, not a contract.** Items marked **OPEN** are
  unresolved with the backend team.
- **No requirement documents** — geofence tolerance, fraud policy, and check-in
  rules are enforced in code without testable acceptance criteria.

---

## Related

- [../../blueprint/offline-architecture.md](../../blueprint/offline-architecture.md)
- [../../blueprint/sync-architecture.md](../../blueprint/sync-architecture.md) — the target engine; sync here is still per-feature
- [../../blueprint/performance-audit.md](../../blueprint/performance-audit.md) — the depot-stock and check-in findings
- [../order/README.md](../order/README.md) — where a stop pivots into a quotation
