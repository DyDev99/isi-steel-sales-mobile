# My Visits — Workflow & Structure

Route management and fraud-safe field-visit capture for sales reps. A rep is assigned a daily route with ordered customer stops, walks through each stop with geofence-verified check-in/out, captures market data, and can pivot straight into building a quotation.

## 1. Folder structure (clean architecture)

```
my_visits/
├── data/
│   ├── local/        # sqlite/drift local DB, route + visit local data sources
│   ├── mock/          # mock route generator (dev backend)
│   ├── models/        # DTOs / JSON-serializable models
│   ├── remote/        # RouteRemoteDataSource + paginated RouteSyncPage
│   ├── repositories/  # repository implementations (impl of domain/repositories)
│   └── services/      # GeolocatorTrackingService (real GPS stream)
├── domain/
│   ├── entities/       # RoutePlan, RouteStop, VisitStatus, CheckInRecord, FraudFlag, ...
│   ├── repositories/    # abstract repository contracts
│   ├── services/       # GeofenceService, FraudDetectionService (pure business rules)
│   └── usecases/        # one class per action (CheckIn, AddOrderLine, RunRouteInitialSync, ...)
├── presentation/
│   ├── bloc/            # ActiveRouteBloc, LocationTrackingCubit, RouteDashboardCubit, RouteSyncCubit, VisitCubit
│   ├── screens/         # see workflow below
│   ├── widgets/         # stop cards, maps, capture bottom sheets, timeline, etc.
│   ├── models/          # VisitRecord (history UI model)
│   ├── mock/            # visit history mock data
│   └── services/        # CameraProofPhotoService (stamped proof photo)
└── my_visits_injection.dart   # DI wiring
```

## 2. Two navigation paths

There are two ways into this feature — they share the same blocs/entities but are separate UI flows.

### A. Guided field flow (current / canonical)
`MyVisitsDashboardScreen` → `RouteDispatchScreen` → `RouteTransitScreen` → `RouteCheckInScreen` → `RouteStockCountScreen` → hands off to the **Order** feature's `ShopListScreen`.

Entered from `HomeScreen`'s "Start Route" CTA. Uses classic `Navigator.push` with `RouteSettings(name: ...)` (not go_router) so screens can `popUntil` a named route.

### B. Legacy / alternate single-screen flow
`ActiveRouteScreen` → `StopDetailScreen`, wired via `AppPages.onGenerateRoute` under `Static.myVisits` (`lib/routes/app_page.dart`), currently loading a hardcoded `'routeId'`. Same underlying blocs, but check-in/out and all capture types (order/stock/return/collection/note/photo/signature) happen on one screen via bottom sheets, instead of the 4-step guided flow. Appears to be an earlier iteration — confirm with the team whether to deprecate.

### C. Visit history (read-only, mock data only)
`MyVisitsHistoryScreen` → `VisitHistoryDetailScreen`, reached via "View History" on the dashboard. Not wired to any bloc/repository/DB — pure UI backed by static mock data.

## 3. Step-by-step: guided flow

| Step | Screen | What happens | Next |
|---|---|---|---|
| 0 | `MyVisitsDashboardScreen` | Syncs routes (`RouteSyncCubit.syncIfNeeded()`), shows today's routes + summary cards | Tap a route → Step 1 |
| 1 | `RouteDispatchScreen` | Ordered stop list, live distance, status pills. Starts GPS tracking. Keeps a `BlocListener<LocationTrackingCubit>` alive underneath child screens to keep geofence status live | Tap a stop / CTA → dispatches `StartDayRequested` + `StopSelected` → Step 2 |
| 2 | `RouteTransitScreen` | Live map + distance/ETA to the stop. "I've Arrived" is locked until `insideGeofence == true` | Tap "I've Arrived" → Step 3 |
| 3 | `RouteCheckInScreen` | Geofence status banner + fraud warnings; captures one or more GPS/time-stamped shopfront photos — each capture writes straight into `VisitCubit` state (Drift-persisted immediately, list-based) instead of being staged in widget state, so photos survive rebuilds/navigation/app kill; dispatches `CheckInRequested` (runs fraud validation) once at least one photo exists | On success (`VisitStatus.checkedIn`) → Step 4. On block, shows the reason via snackbar |
| 4 | `RouteStockCountScreen` | Rapid on-shelf SKU counter, flags out-of-stock items as quotation opportunities. "Done" persists stock updates, dispatches `CheckOutRequested` (completes the visit), then `popUntil` back to Step 1 and pushes `ShopListScreen` (Order feature) pre-filtered by stop/territory | Rep either returns to Dispatch for the next stop or builds a quotation immediately |

Ending the day (`EndDayRequested`, found in the legacy `ActiveRouteScreen`) marks the route `completed`.

## 4. State machines

**`RouteStatus`** (route-level): `planned → published → inProgress → completed`
- `inProgress` set on `StartDayRequested`; `completed` set on `EndDayRequested`.

**`VisitStatus`** (stop-level): `pending → enRoute → arrived → checkedIn → checkedOut`, or `→ missed`
- `pending → checkedIn`: on `CheckInRequested`, gated by geofence + fraud validation.
- `checkedIn → checkedOut`: on `CheckOutRequested`, only if currently `checkedIn`.
- `→ missed`: on `NextStopRequested`, if the rep advances past a stop never checked out.
- Only `checkedOut` counts as complete (`VisitStatus.isComplete`).

## 5. State management (bloc/cubit)

- **`ActiveRouteBloc`** — the central state machine: Start Day → Navigate → Arrive → Geofence Validation → Check In → Visit → Check Out → Next Stop → End Day. Runs fraud validation on check-in, persists `CheckInRecord`/`CheckOutRecord`, drives `currentStopIndex`.
- **`LocationTrackingCubit`** — starts/stops the GPS stream, persists samples, flags "impossible travel speed" fraud.
- **`RouteDashboardCubit`** — drives the dashboard off a live stream (`WatchTodayRoutes`); recomputes progress/summary as check-ins happen anywhere in the app. `RouteDashboardScreen` appends a `RouteCardSkeleton` shimmer below the list while a sync is in-flight, instead of leaving trailing space blank.
- **`RouteSyncCubit`** — mirrors the Order feature's sync cubit: `syncIfNeeded()` runs full initial sync if never synced, `refresh()` always runs delta sync. `RouteDashboardScreen`'s listener reacts to both `RouteSyncSucceeded` (reload) and `RouteSyncFailed` (SnackBar with the failure message) — a sync failure is no longer silently swallowed.
- **`VisitCubit`** — manages offline capture data for the checked-in stop (order lines, stock updates, returns, collections, notes, photos), optimistic local updates + local persistence. `RouteCheckInScreen` writes each captured photo here immediately (`addPhoto` per shot), not just at final submit.

## 6. Domain usecases (grouped)

- **Route lifecycle**: `GetRoute`, `FetchTodayRoutes`, `WatchTodayRoutes`, `UpdateRouteStatus`, `UpdateStopStatus`
- **Check-in / check-out**: `CheckIn`, `CheckOut`
- **Visit capture**: `AddOrderLine`, `AddStockUpdate`, `AddReturn`, `AddCollection`, `AddVisitNote`, `AddVisitPhoto`, `FetchVisitData`
- **Location & fraud**: `RecordLocationSample`, `FetchLocationSamples`, `RecordFraudFlag`
- **Sync**: `GetRouteLastSyncedAt`, `RunRouteInitialSync`, `RunRouteDeltaSync`

## 7. Geofence & fraud

- **`GeofenceService`** — Haversine distance vs. a stop's `geofenceRadiusMeters` → `insideGeofence`/`distanceMeters`.
- **`FraudDetectionService`** — `validateCheckIn()` combines geofence + GPS accuracy (default max 30m) + mock-location + VPN heuristic into a pass/fail (or allowed-with-warning) result. `isImpossibleTravel()` flags GPS pairs implying > 150 km/h.
- **`FraudPolicy`** — configurable thresholds; currently permissive by default (`blockOnMockLocation: false`, `blockOnVpn: false`) for dev/testability — flip before shipping.
- **`FraudFlag` types**: `mockLocation`, `impossibleSpeed`, `poorAccuracy`, `vpnDetected`.

## 8. Sync

- `RouteSyncRepositoryImpl` mirrors the Order feature's sync repository. Initial sync pages through the backend (`pageSize = 50`), upserting customers + routes each page. Delta sync fetches everything changed since the last-synced timestamp in one call (falls back to full initial sync if never synced).
- Currently backed by `MockRouteRemoteDataSource`, generating in-memory data scoped to a hardcoded territory (`'Phnom Penh'`) since `User` has no territory field yet.
- Local DB is the single source of truth for the UI; `RouteDashboardCubit` reads from it via a live stream, and the dashboard re-subscribes whenever `RouteSyncSucceeded` fires.
- **Hard cross-feature ordering dependency: customer sync must run before route sync.** `route_stops.customer_id` is a real foreign key into `customers` (`PRAGMA foreign_keys = ON`, `core/database/drift/migrations/schema_migrations.dart`), and `RouteDriftLocalDataSource.upsertCustomers` only *updates* an existing customer row (ADR-001 — Customers is SAP-owned, route sync may never invent one). If the customer directory hasn't synced yet, every stop's customer is unknown, the `route_stops` insert throws a FK violation, and the **entire** `upsertRoutesWithStops` transaction aborts — zero routes persist, not just the affected stops. `CustomerSyncCubit.syncIfNeeded()` is triggered at app-shell startup (`main_shell.dart`'s `initState`, alongside `ResumableVisitCubit.refresh()`) specifically to win this race as early as possible; a Customers-tab visit still runs its own `syncIfNeeded()` too (idempotent, checked against the persisted watermark).
- **`visit_date` must be anchored to the UTC calendar day, not local time.** `RouteDao.fetchRoutesForDay`/`watchRoutesForDay` filter by `DateTime.utc(day.year, day.month, day.day)`. `MockRouteRemoteDataSource._rebaseToToday()` deliberately reinterprets asset dates as UTC before re-anchoring for exactly this reason — in a positive-UTC-offset zone (Cambodia, UTC+7), a naive local-midnight date lands on the *previous* UTC day and silently falls outside every "today" query. Any new sync/seed/test code touching `visitDate` must follow the same convention.

## 9. Known dev-only shims (flag before release)

- `kDebugForceInsideGeofence = true` in `route_transit_screen.dart` — forces "I've Arrived" unlocked regardless of real geofence. TODO in code to flip to `false`.
- Debug-only FAB on the dashboard seeds two fixtures directly into the local DB for testing without traveling: `seedIsiTowerTestRoute` (one 3-stop route, today) and `seedMockRoutesForDates` (5 routes on 2026-07-20, 4 on 2026-07-21 — exercises the calendar's multi-day date filtering). Both borrow real, already-synced customer IDs so the `route_stops.customer_id` FK resolves, and both need at least that many customers already synced locally (throw a `StateError` otherwise). Any `visitDate` in these fixtures must be UTC-anchored (§8) — a local-midnight `DateTime` silently lands on the wrong day in Cambodia's UTC+7.
- `FraudPolicy` defaults intentionally permissive (won't block on mock location / VPN).
- Hardcoded `'routeId'` in the legacy `Static.myVisits` route, and hardcoded territory `'Phnom Penh'` in `RouteSyncScope.forCurrentUser`.

## 10. Known bugs fixed (root causes, for future reference)

1. **Tab switch destroyed all tab state, including this feature's sync cubits.** Fix lives outside this folder (`lib/features/shell/presentation/main_shell.dart`) but explains why My Visits looked broken/reset on every tab switch: the shell's `IndexedStack` was wrapped in a `KeyedSubtree` keyed on the active tab index, so switching tabs gave Flutter a new widget identity and tore down + rebuilt *every* tab — including recreating the factory-registered `RouteDashboardCubit`/`RouteSyncCubit` from scratch, re-running sync each time. Fixed by dropping the per-tab key so `IndexedStack` actually preserves state as intended.
2. **Check-in photo lost on rebuild/navigation/app kill.** `RouteCheckInScreen` stored the captured proof photo in a local `StatefulWidget` field (`_proof`), singular, only pushed into `VisitCubit`/persistence at final submit. Fixed by writing each capture straight into `VisitCubit` (already Drift-persisted, already list-based) as soon as it's taken — see §3/§5.
3. **Route sync silently failing, dashboard permanently stuck on "No local data found."** Root cause: the customer/route sync FK ordering dependency described in §8, combined with the dashboard only listening for `RouteSyncSucceeded` and silently dropping `RouteSyncFailed`. Fixed by triggering customer sync at shell startup and surfacing sync failures via SnackBar.
4. **Seeded test routes invisible to "today."** `seed_isi_tower_test_route.dart`'s `visitDate` was built from local midnight instead of UTC (the same class of bug §8's UTC day-window note describes). Fixed by anchoring to `DateTime.utc(...)`.

## 11. Open question

`ActiveRouteScreen` / `StopDetailScreen` (legacy flow) still exist alongside the guided 4-step flow. Worth confirming with the team whether they should be removed, kept as a fallback, or documented as deprecated.
