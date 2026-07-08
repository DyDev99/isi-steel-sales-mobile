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
| 3 | `RouteCheckInScreen` | Geofence status banner + fraud warnings, requires a GPS/time-stamped shopfront photo, dispatches `CheckInRequested` (runs fraud validation) | On success (`VisitStatus.checkedIn`) → Step 4. On block, shows the reason via snackbar |
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
- **`RouteDashboardCubit`** — drives the dashboard off a live stream (`WatchTodayRoutes`); recomputes progress/summary as check-ins happen anywhere in the app.
- **`RouteSyncCubit`** — mirrors the Order feature's sync cubit: `syncIfNeeded()` runs full initial sync if never synced, `refresh()` always runs delta sync.
- **`VisitCubit`** — manages offline capture data for the checked-in stop (order lines, stock updates, returns, collections, notes, photos), optimistic local updates + local persistence.

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

## 9. Known dev-only shims (flag before release)

- `kDebugForceInsideGeofence = true` in `route_transit_screen.dart` — forces "I've Arrived" unlocked regardless of real geofence. TODO in code to flip to `false`.
- Debug-only FAB on the dashboard that seeds a fixture "ISI Tower" route directly into the local DB for testing without traveling.
- `FraudPolicy` defaults intentionally permissive (won't block on mock location / VPN).
- Hardcoded `'routeId'` in the legacy `Static.myVisits` route, and hardcoded territory `'Phnom Penh'` in `RouteSyncScope.forCurrentUser`.

## 10. Open question

`ActiveRouteScreen` / `StopDetailScreen` (legacy flow) still exist alongside the guided 4-step flow. Worth confirming with the team whether they should be removed, kept as a fallback, or documented as deprecated.
