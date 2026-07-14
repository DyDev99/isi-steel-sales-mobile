# ISI Steel Sales Mobile — Enterprise Architecture Blueprint

> Centralized enterprise mobile solution for KIC GROUP and subsidiaries.
> Offline-first sales & field-visit CRM with SAP integration.

**Status of this document:** grounded review of the *actual* codebase (633 Dart
files, 14 feature modules) as of 2026-07-14. The project already implements
Feature-First Clean Architecture with federated DI, an encrypted Drift/SQLCipher
database, and an offline sync engine. This blueprint therefore prescribes
**standardization and consolidation**, not a rewrite. Every recommendation below
is justified and mapped to a concrete file that exists today.

> **Execution log (2026-07-14) — applied & verified (`flutter analyze` clean, all 73 tests pass):**
> - Created `shared/widgets/` and consolidated the duplicate `GlassCard` +
>   `AuroraBackground` there; deleted the `core/utils` originals and the dead
>   auth-local copies (~35 imports rewritten).
> - Deleted dead/duplicate files: `verion.dart`, empty `hive/hive_service.dart`,
>   empty `secure_strorage.dart` + `file_strorage.dart` stubs, dead
>   `core/local/session_store.dart` (Hive-based).
> - Renamed `oders_card_widget.dart` → `orders_card_widget.dart` (`OrderPieCard`
>   is currently unreferenced — candidate for removal or wiring).
> - Fixed DI naming/placement: `initCustomerFeatures` → `registerHomeFeature(sl)`
>   at `features/home/home_injection.dart`. **No duplicate registration existed.**
> - Consolidated storage into `core/storage/{database/drift, secure, hive, session}`
>   and moved i18n to `core/localization/`.
> - **Session persistence uses `flutter_secure_storage`** (already true in the live
>   `AuthLocalDataSourceImpl`; the only Hive-based session store was dead and removed).
>
> **Corrections to the original review:** (1) P6 was **not** a duplicate-registration
> bug; (2) `core/middleware/app_middleware.dart` is **not** dead — it defines
> `TokenStore`. Both are reflected inline below.

---

## Table of Contents

1. [Current Architecture Analysis](#1-current-architecture-analysis)
2. [Architecture Problems](#2-architecture-problems)
3. [Recommended Improvements](#3-recommended-improvements)
4. [New Folder Structure](#4-new-folder-structure)
5. [Dependency Diagram](#5-dependency-diagram)
6. [Core Layer Explanation](#6-core-layer-explanation)
7. [Feature Layer Explanation](#7-feature-layer-explanation)
8. [Shared Layer Explanation](#8-shared-layer-explanation)
9. [Migration Plan](#9-migration-plan)
10. [README Blueprint](#10-readme-blueprint)
11. [Final Recommendations](#11-final-recommendations)

---

## 1. Current Architecture Analysis

### 1.1 What exists today

The app is **already** Feature-First Clean Architecture. Each feature owns three
layers:

```
features/<feature>/
  data/         datasources (local/remote), models, repositories (impl), mappers, mock
  domain/       entities, repositories (abstract), usecases, services (ports)
  presentation/ bloc, screens, widgets, services (adapters)
  <feature>_injection.dart
```

**Feature modules present (14):**
`app_coach`, `authentication`, `customers`, `home`, `lead`, `localization`,
`my_visits`, `notification`, `order`, `profile`, `revenue`, `settings/theme`,
`shell`, `splash`.

**Core infrastructure (`lib/core/`):**

| Area | Location | Notes |
|------|----------|-------|
| Config / env | `core/config/env.dart` (`envied`) | Compile-time secrets ✅ |
| Database | `core/database/drift/**` | Drift + SQLCipher, DAOs, tables, migrations ✅ |
| DB security | `core/database/secure/**` | Composite-key derivation, key rotation ✅ |
| Storage | `core/local/**`, `core/database/hive/**` | Hive, prefs, session — **split/overlapping** ⚠️ |
| Network | `core/network/**` | Dio-based `sap_client`, connectivity cubit/service ✅ |
| Sync | `core/sync/**` | `sync_engine`, `sync_queue_service`, `conflict_resolver` ✅ |
| Session | `core/session/session_manager.dart` | ✅ |
| Errors | `core/error/**` | `failures.dart`, `exceptions.dart` ✅ |
| UseCase base | `core/usecase/usecase.dart` | ✅ |
| Theme | `core/theme/**` | Colors, typography, extensions ✅ |
| DI | `core/di/injection_container.dart` (85 LOC) | Federated, calls `register*Feature` ✅ |
| Utils | `core/utils/**` | **Overloaded grab-bag** ⚠️ |
| Routing | `lib/routes/**` | At lib root, class named `Static` ⚠️ |

**Technology stack:** Flutter 3.3+, `flutter_bloc`/`bloc_concurrency`, `get_it`,
`dio`, `drift` + `sqlite3` + `sqlcipher_flutter_libs`, `hive_flutter`,
`flutter_secure_storage`, `envied`, `connectivity_plus`, `geolocator`/`geocoding`/
`google_maps_flutter`, `mobile_scanner`, `speech_to_text`, `image_picker`/
`file_picker`, `fl_chart`, `flutter_screenutil`, `intl`. Tests: `bloc_test`,
`mocktail`.

### 1.2 Strengths (keep these)

- **Correct dependency direction** in the layered features — presentation → domain
  → data. Repositories are abstract in `domain/repositories`, implemented in
  `data/repositories`.
- **Federated DI**: each feature exposes `register<Feature>Feature(sl)`; the root
  container stays 85 lines. This scales to hundreds of features.
- **Genuine offline-first**: encrypted Drift DB, per-feature sync repos
  (`*_sync_repository_impl.dart`), a global `sync_engine` + `sync_queue_service`,
  and delta/initial sync usecases (`run_customer_delta_sync`, `run_route_initial_sync`,
  `run_delta_sync`).
- **Security maturity**: SQLCipher with device-bound composite key derivation and
  key rotation (`database_key_rotator.dart`), secrets via `envied`.
- **Domain ports for platform concerns**: e.g. `domain/services/location_tracking_service.dart`
  (port) implemented by `presentation/services/geolocator_tracking_service.dart`
  (adapter). This is textbook hexagonal design.
- **Test scaffolding** for the risky layers (DAO tests, migration test, key
  rotation/derivation tests, a bloc test).

### 1.3 Metrics

- 633 Dart files; DI root 85 LOC; `main.dart` 28 LOC; `app.dart` 132 LOC.
- Largest source files (god-file risk):
  `mock_product_data.dart` (31 KB, mock — acceptable),
  `lead_detail_screen.dart` (28 KB), `customer_detail_screen.dart` (25 KB),
  `route_check_in_screen.dart` (24 KB), `quotation_builder_screen.dart` (22 KB),
  `add_customer_bottom_sheet.dart` (22 KB).

---

## 2. Architecture Problems

Ranked by impact on maintainability. Each is verified against real files.

### P1 — No `shared/` layer; reusable UI is duplicated into `core/utils`
`core/utils/` mixes **widgets** (`aurora_background.dart`, `glass_card.dart`,
`shimmer.dart`, `offline_banner.dart`), **value types** (`result.dart`,
`typedefs.dart`), **design tokens** (`colors.dart`, `images.dart`), and
**one-offs** (`version.dart`, `mock_latency.dart`, `page_transitions.dart`,
`interactive.dart`). `core/utils` is doing the job of four different layers.
**Impact:** developers can't predict where a reusable widget lives, so they
re-create it (see P2).

### P2 — Confirmed duplicate files
- `core/utils/version.dart` **and** `core/utils/verion.dart` are **byte-identical**
  (`VersionFooter`). One is a typo copy — dead code.
- `core/utils/aurora_background.dart` **and**
  `features/authentication/presentation/widgets/login/aurora_background.dart`
  (same for `glass_card.dart`) — the same visual component exists twice.
- Two `NotificationItem` entities:
  `features/notification/domain/entities/notification_item.dart` **and**
  `features/lead/domain/entities/notification_item.dart`.

### P3 — Dead / empty stubs left in the tree
- `core/database/hive/hive_service.dart` is **empty (0 LOC)**; the real
  implementation is `core/local/hive_service.dart`. The empty stub is a trap.
- `core/utils/verion.dart` (see P2).

### P4 — Storage/persistence concerns are scattered across three folders
Hive, preferences, session, local cache, and the Drift database are split across
`core/local/`, `core/database/`, and `core/session/` with overlap
(`core/local/hive_service.dart` vs `core/database/hive/hive_service.dart`;
`core/local/session_store.dart` vs `core/session/session_manager.dart`;
`core/local/local_cache.dart` vs `core/local/app_preferences.dart`).
**Impact:** no single answer to "where does app state persist?"

### P5 — Localization is split three ways
`core/local/localization_services.dart` + `core/local/localized_builder.dart` +
`features/localization/presentation/bloc/language_cubit.dart`. The word "local"
is also overloaded (locale vs local storage). `core/local/` conflates
*localization* and *local persistence*.

### P6 — Inconsistent DI naming & a misnamed/misplaced entrypoint
**Correction (verified 2026-07-14):** there is **no** duplicate dependency
registration. `initCustomerFeatures()` (defined in `home/presentation/home_injection.dart`)
registered only `AddCustomerBloc()`; `registerCustomerFeature()` registers the
customer directory. They bind **different** types, so DI was already deterministic.
The real problems were: (a) a misleading name (`initCustomerFeatures` actually
registered a *home* bloc), (b) the file living under `presentation/` while every
other feature keeps injection at its root, and (c) it used the global `sl` instead
of taking it as a parameter. **Status: FIXED** — renamed to
`registerHomeFeature(GetIt sl)` at `features/home/home_injection.dart`.

### P7 — Inconsistent BLoC folder shape
`my_visits/presentation/bloc/` uses nested `cubit/`, `events/`, `state/`
subfolders; `order` uses `bloc/<subfeature>/`; most features keep `bloc/` flat.
Three conventions for the same concept.

### P8 — Routing lives at `lib/routes/` with a poor name
Routing is outside `core/`, and the route-name holder class is called `Static`
(non-descriptive). Navigation is a cross-cutting concern and belongs in
`core/routing/`.

### P9 — `notification` feature is missing its data/repository layer
It has `domain/usecases/fetch_notifications.dart` and a presentation sheet but **no
repository abstraction and no datasource** — the usecase has nowhere to bind. This
breaks the layering contract every other feature follows.

### P10 — Feature overlap: `revenue` vs `order`
Both own `product`, `cart`, `category`, and discount concepts
(`revenue/domain/entities/{product,cart_item,product_category}.dart` mirror
`order/domain/entities/{product,cart_item,category}.dart`). This is likely a
parallel/legacy implementation of the same bounded context and duplicates models,
mappers, and mock data.

### P11 — God-files in presentation
`lead_detail_screen.dart` (28 KB), `customer_detail_screen.dart` (25 KB),
`route_check_in_screen.dart` (24 KB), `quotation_builder_screen.dart` (22 KB),
`add_customer_bottom_sheet.dart` (22 KB) each mix layout, section widgets, and
event wiring in one file. Hard to review, hard to test, merge-conflict magnets.

### P12 — Naming inconsistencies / typos
`secure_strorage.dart`, `file_strorage.dart` ("strorage"),
`oders_card_widget.dart` ("oders"), `verion.dart`, `middleware/app_middleware.dart`
(the network middleware was removed elsewhere per git status but this copy lingers),
and `home/domain/dashboard_summary.dart` sits directly in `domain/` instead of
`domain/entities/`.

### P13 — Data-shaped files inside `presentation/`
`my_visits/presentation/mock/visit_history_mock_data.dart` and
`presentation/models/visit_record.dart` place mock data and models in the
presentation layer instead of `data/`.

**Not found (good news):** no evidence of presentation calling Dio/HTTP directly,
no obvious circular feature imports, no business logic detected inside widgets at
the repository boundary. The problems are **organizational consistency**, not
broken layering.

---

## 3. Recommended Improvements

| # | Problem | Recommendation | Justification |
|---|---------|----------------|---------------|
| R1 | P1, P8 | Introduce `lib/shared/` (widgets, components, dialogs, bottom_sheets, animations, formatters, validators, extensions) and move routing to `core/routing/`. | Predictable home for reusable UI kills re-creation; routing is cross-cutting. |
| R2 | P2, P3 | Delete `verion.dart` and empty `hive/hive_service.dart`; de-duplicate aurora/glass into `shared/widgets`; unify the two `NotificationItem` entities. **Note:** `core/middleware/app_middleware.dart` is **not** dead — it defines `TokenStore`, consumed by `AuthLocalDataSourceImpl` — do **not** delete it. | Removes traps and duplicate maintenance. |
| R3 | P4 | Consolidate persistence under `core/storage/` (sub-namespaces: `database/` (Drift), `key_value/` (Hive+prefs), `secure/`, `session/`). | One answer to "where does state live." |
| R4 | P5 | Move all i18n to `core/localization/`; rename `core/local/` → merged into `core/storage/`. | Ends the locale-vs-local-storage overload. |
| R5 | P6 | Standardize one DI entrypoint per feature: `register<Feature>Feature(GetIt sl)` at feature root (rename the misnamed `initCustomerFeatures` → `registerHomeFeature`). No duplicate registration existed. | Consistency + accurate naming. |
| R6 | P7 | Adopt one BLoC folder shape for all features (see §7). | Removes three conventions. |
| R7 | P9 | Complete `notification` with `domain/repositories/notification_repository.dart` + `data/` datasource & impl. | Restores layering contract. |
| R8 | P10 | Decide: `revenue` is a view over `order`, or a distinct bounded context. If overlapping, fold `revenue` into `order` (or extract a shared `catalog` module both consume). | Eliminates duplicate models/mocks. |
| R9 | P11 | Extract section widgets from god-screens into `presentation/widgets/<screen>/`. | Reviewable, testable, fewer merge conflicts. |
| R10 | P12, P13 | Fix typos on rename; move `dashboard_summary` to `domain/entities/`; move presentation mocks/models to `data/`. | Consistency + correct layering. |
| R11 | order megafeature | Optionally split `order` into sub-modules (`catalog`, `cart`, `quotation`, `sales_order`) sharing an `order/` domain. | `order` is the largest feature; sub-bounded-contexts ease team ownership. |

**Explicitly NOT recommended** (avoid complexity for its own sake): do **not**
migrate to a package/monorepo layout yet; do **not** replace `get_it` with
codegen DI; do **not** introduce a router package (`go_router`) mid-flight — the
current `IndexedStack` shell + `onGenerateRoute` works. Revisit these only when a
second app or a second team needs them.

---

## 4. New Folder Structure

```
lib/
  app.dart                      # App widget, theme + BlocProviders wiring
  main.dart                     # bootstrap → initDependencies() → runApp
  bootstrap.dart                # (new) runZonedGuarded, error handlers, env load

  core/                         # Cross-cutting infra. NO feature imports.
    config/                     # env.dart (envied), flavors, build config
    constants/                  # app_constant.dart, api paths, keys
    di/                         # injection_container.dart (federated root)
    error/                      # failures.dart, exceptions.dart
    localization/               # (was core/local i18n) services + localized_builder + arb/json
    network/                    # dio_client, sap_client, connectivity, network_info, interceptors/
    routing/                    # (was lib/routes) app_routes.dart (rename `Static`→`AppRoutes`), app_pages.dart, navigator_key
    security/                   # (new home) wraps database/secure + secure_storage
    storage/                    # unified persistence
      database/                 # drift/ (app_database, daos, tables, migrations, connection)
      key_value/                # hive_service, app_preferences, local_cache
      secure/                   # secure_storage, key derivation/rotation/providers
      files/                    # file_storage (fix typo)
      session/                  # session_manager, session_store
    sync/                       # sync_engine, sync_queue_service, conflict_resolver
    theme/                      # app_colors, app_typography, app_theme, theme_extensions
    usecase/                    # usecase.dart base
    utils/                      # PURE helpers only: result, typedefs, mock_latency, page_transitions
    services/                   # cross-feature app services (api_services facade)

  shared/                       # Reusable, feature-agnostic building blocks
    widgets/                    # buttons, cards, inputs, badges, banners (offline_banner)
    components/                 # composed widgets (glass_card, aurora_background, status_pill)
    dialogs/                    # login_required_dialog, confirm dialogs
    bottom_sheets/              # generic sheet scaffolds
    animations/                 # shimmer, skeletons, pointer/highlight
    formatters/                 # currency, date, number formatters
    validators/                 # email/phone/required validators
    extensions/                 # context, string, num, datetime extensions

  features/
    <feature>/
      data/
        datasources/            # local/ and remote/ subfolders
        models/                 # DTOs (JSON <-> ) with *_model.dart
        repositories/           # *_repository_impl.dart
        mappers/                # model <-> entity, drift <-> model
        mock/                   # mock datasources & seed data (dev only)
      domain/
        entities/               # pure business objects (+ value objects)
        repositories/           # abstract contracts
        usecases/               # one class per use case
        services/               # ports (abstract platform boundaries)
      presentation/
        bloc/                   # <name>_bloc.dart | _cubit + _event + _state
        screens/                # full pages
        widgets/                # feature-local widgets (grouped per screen)
        services/               # adapters implementing domain ports
      <feature>_injection.dart  # register<Feature>Feature(GetIt sl)

  # Feature inventory (post-consolidation):
  # authentication, customers, lead, order (+catalog/cart/quotation/sales_order),
  # my_visits, revenue*, home, dashboard(shell), notification, profile,
  # settings(theme), localization, app_coach, splash
  # *revenue folded into order OR kept as a distinct bounded context (decision R8)
```

### Naming conventions (standardized)

| Artifact | Convention | Example |
|----------|-----------|---------|
| Folders / files | `snake_case` | `customer_repository_impl.dart` |
| Classes | `PascalCase` | `CustomerRepositoryImpl` |
| Entities | noun, no suffix | `Customer`, `RouteStop` |
| Models (DTO) | `*Model` / `*_model.dart` | `CustomerModel` |
| Repository (abstract) | `*Repository` | `CustomerRepository` |
| Repository (impl) | `*RepositoryImpl` | `CustomerRepositoryImpl` |
| UseCase | verb-noun class, verb-noun file | `BrowseCustomers` / `browse_customers.dart` |
| Bloc / Cubit | `*Bloc` / `*Cubit` (+ `*Event`, `*State`) | `CustomersBloc`, `ThemeCubit` |
| Datasource | `*LocalDataSource` / `*RemoteDataSource` | `CustomerRemoteDataSource` |
| Mapper | `*Mapper` or `*_mappers.dart` | `customer_drift_mappers.dart` |
| DI entrypoint | `register<Feature>Feature(GetIt)` | `registerOrderFeature` |
| DAO / Table (Drift) | `*Dao` / `*Table` | `CustomerDao`, `CustomersTable` |

---

## 5. Dependency Diagram

### Layer dependency (strict, one direction)

```
        ┌─────────────────────────────────────────────┐
        │              PRESENTATION                     │
        │   screens → widgets → bloc/cubit              │
        │   presentation/services (adapters)            │
        └───────────────────┬───────────────────────────┘
                            │ depends on
        ┌───────────────────▼───────────────────────────┐
        │                 DOMAIN                          │
        │   usecases → repositories (abstract)            │
        │   entities · services (ports)                   │
        └───────────────────┬───────────────────────────┘
                            │ implemented by
        ┌───────────────────▼───────────────────────────┐
        │                  DATA                           │
        │   repositories (impl) → datasources → mappers   │
        └───────────────────┬───────────────────────────┘
                            │ talks to
        ┌───────────────────▼───────────────────────────┐
        │        CORE INFRA  (storage · network · sync)   │
        │   Drift/SQLCipher · Hive · Dio/SAP · SyncEngine │
        └─────────────────────────────────────────────────┘

Allowed cross-cutting deps: every layer may import  core/  and  shared/.
Forbidden: core/ → features/ ; feature A → feature B (direct).
```

### Rules (lint-enforceable)

1. `core/**` and `shared/**` must **never** import `features/**`.
2. Feature A must **never** import Feature B's internals. Cross-feature
   collaboration goes through: (a) a domain contract registered in DI, (b) a
   navigation route, or (c) an event/stream — never a direct class import.
3. `presentation/**` must **never** import `dio`, `drift`, `sqlite3`, or a
   `*RemoteDataSource`/DAO directly — only usecases/blocs.
4. `domain/**` must **never** import Flutter, Dio, or Drift. Pure Dart only.
5. Platform SDKs (geolocator, camera, scanner, speech) are wrapped behind a
   `domain/services` **port**; the concrete adapter lives in `presentation/services`
   or `data/services` and is bound in DI.

### Offline data flow

```
UI event → Bloc → UseCase → Repository(Impl)
   ├─ read:  LocalDataSource (Drift)  ── returns immediately (offline-first)
   └─ write: LocalDataSource (Drift) + enqueue SyncQueueItem
                                   │
                       SyncEngine (on connectivity) drains queue
                                   │
                       RemoteDataSource (SAP via Dio) ── push/pull delta
                                   │
                       ConflictResolver → reconcile → Drift → notify streams
```

---

## 6. Core Layer Explanation

`core/` is **application infrastructure shared by all features** and must remain
feature-agnostic. Decision rule for "does X belong in core?":

- **Core** if it is infrastructure with no business meaning and every feature
  could plausibly use it: database engine, network client, sync engine, secure
  storage, theme, DI wiring, error types, routing.
- **Shared** if it is a reusable *presentation* asset with no business meaning:
  buttons, cards, dialogs, animations, formatters, validators, extensions.
- **Feature** if it encodes a business rule or a domain concept: anything about
  customers, orders, visits, leads, pricing, credit.
- **Future package** if it becomes reusable across *multiple apps* (e.g. the
  SQLCipher composite-key module, or the sync engine) — extract to
  `packages/` only when a second consumer appears (YAGNI until then).

### Core sub-modules and their responsibilities

| Module | Responsibility | Key files (today) |
|--------|----------------|-------------------|
| `config` | Compile-time env & flavors | `env.dart` (envied) |
| `constants` | App-wide constants | `app_constant.dart` |
| `di` | Federated service locator | `injection_container.dart` |
| `error` | `Failure` / `Exception` taxonomy | `failures.dart`, `exceptions.dart` |
| `localization` | i18n runtime + builder + strings | (from `core/local` + `features/localization`) |
| `network` | Dio client, SAP client, connectivity, `NetworkInfo` | `sap_client.dart`, `dio_client.dart`, `connectivity_*` |
| `routing` | Route names + `onGenerateRoute` + navigator key | (from `lib/routes`) |
| `security` | Facade over secure storage & key management | wraps `database/secure/**` |
| `storage` | All persistence (Drift, Hive, prefs, secure, session, files) | `database/drift/**`, `hive_service`, `app_preferences`, `session_manager` |
| `sync` | Queue, engine, conflict resolution | `sync_engine.dart`, `sync_queue_service.dart`, `conflict_resolver.dart` |
| `theme` | Design tokens & ThemeData | `app_theme.dart`, `app_typography.dart`, `app_colors_dark.dart` |
| `usecase` | `UseCase<Type, Params>` base | `usecase.dart` |
| `utils` | **Pure** helpers only after cleanup | `result.dart`, `typedefs.dart`, `page_transitions.dart` |

**Moves out of core:**
`utils/{aurora_background,glass_card,shimmer,offline_banner}.dart` → `shared/`;
`utils/{colors,images}.dart` → merge into `core/theme` (design tokens);
`utils/version.dart` → `shared/components`; delete `utils/verion.dart`;
`auth/login_required_dialog.dart` → `shared/dialogs`;
`services/image_picker.dart` → wrapped as a domain port + adapter in the owning feature.

---

## 7. Feature Layer Explanation

Every feature is a **self-contained vertical slice** with the three-layer shape in
§4. Rules:

- **Isolation:** a feature never imports another feature's classes. If `home`
  needs customer counts, it depends on a `CustomerRepository` **contract**
  (registered in DI) — not on `CustomerRepositoryImpl` or a customer screen.
- **One DI entrypoint:** `register<Feature>Feature(GetIt sl)` at the feature root,
  called from `core/di/injection_container.dart`. (Fixes P6: move `home_injection`
  to the root, collapse the two customer registrations into one.)
- **Standard BLoC shape (fixes P7):**
  - Simple state → `Cubit`: `presentation/bloc/<name>_cubit.dart` + `<name>_state.dart`.
  - Event-driven state → `Bloc`: `presentation/bloc/<name>_bloc.dart` +
    `<name>_event.dart` + `<name>_state.dart`.
  - For features with many blocs (`order`, `my_visits`), group by sub-feature:
    `bloc/<subfeature>/...` — **but** stop using the parallel `cubit/ events/ state/`
    split; keep a bloc and its event/state together.
- **God-screen rule (fixes P11):** a screen file over ~400 LOC must extract its
  sections into `presentation/widgets/<screen_name>/`. The screen composes; the
  widgets render.

### Feature status table

| Feature | Layer completeness | Action |
|---------|--------------------|--------|
| authentication | Full (data/domain/presentation) | De-dup login widgets → shared |
| customers | Full + sync | OK (no DI bug — see P6 correction) |
| order | Full + sync (largest) | Consider sub-module split (R11) |
| my_visits | Full + sync + services | Move presentation mocks/models → data; flatten bloc subfolders |
| lead | Full | Split god-screen `lead_detail_screen` |
| revenue | Full but overlaps order | Decide fold vs keep (R8) |
| profile | Full | OK |
| settings/theme | Full | OK (nice reference feature) |
| home | data+domain+presentation (thin) | Move `dashboard_summary`→entities; DI to root |
| app_coach | Full | OK |
| notification | **domain only** | Add repository + datasource (R7) |
| localization | presentation-only cubit | Merge runtime into `core/localization` |
| shell | presentation-only (container) | OK — this is the app scaffold |
| splash | presentation-only | OK |

`shell` and `splash` are legitimately presentation-only (app scaffolding), not
violations.

---

## 8. Shared Layer Explanation

`shared/` is **new**. It holds feature-agnostic presentation building blocks so no
feature ever re-creates a widget (root cause of P1/P2).

| Sub-folder | Contents (seeded from today's code) |
|------------|-------------------------------------|
| `widgets/` | buttons, inputs, `offline_banner`, `status_pill`, badges |
| `components/` | `glass_card`, `aurora_background`, `version_footer` (composed, branded) |
| `dialogs/` | `login_required_dialog`, confirm/alert dialogs |
| `bottom_sheets/` | generic draggable sheet scaffold used by add-customer/visit sheets |
| `animations/` | `shimmer`, skeleton loaders, `pointer_animation`, `highlight_painter` |
| `formatters/` | currency (KHR/USD), date, quantity formatters |
| `validators/` | email, phone (`phone_form_field`), required, min/max |
| `extensions/` | `BuildContext`, `String`, `num`, `DateTime` helpers |

**Promotion rule:** a widget graduates from `features/**/widgets` to `shared/` only
when a **second** feature needs it (Rule of Three-lite). This prevents a bloated
premature shared kitchen-sink. The confirmed duplicates (aurora, glass, version)
already meet the bar and should move now.

`shared/` may import `core/` (theme, extensions) but **never** `features/`.

---

## 9. Migration Plan

Executed in small, independently shippable, reversible steps. Each step ends green
(`flutter analyze` + `flutter test`). Do **not** big-bang rename.

### Step 0 — Safety net (before touching anything)
- Branch: `refactor/architecture-standardization` off `main`.
- Ensure `flutter analyze` is clean and `flutter test` passes today; record the
  baseline. Add a coverage snapshot.
- Add an import-boundary lint (custom `analysis_options.yaml` rule or a CI grep):
  fail if `core/**` or `shared/**` imports `features/**`.

### Step 1 — Delete dead code (zero risk) — ✅ DONE
- Removed `core/utils/verion.dart`, empty `core/database/hive/hive_service.dart`,
  empty `core/database/secure/secure_strorage.dart` + `files/file_strorage.dart`
  stubs, and the dead Hive-based `core/local/session_store.dart`.
- **Do NOT** delete `core/middleware/app_middleware.dart` — it defines `TokenStore`
  and is live. (Earlier "dead" classification was wrong.)
- **Risk:** none. **Rollback:** git revert the commit.

### Step 2 — Introduce `shared/` and move confirmed duplicates
- Create `shared/{widgets,components,dialogs,animations,formatters,validators,extensions}`.
- Move `aurora_background`, `glass_card`, `version_footer`, `offline_banner`,
  `shimmer`, `status_pill`, `login_required_dialog` into `shared/`. Delete the
  auth-local copies; update imports (IDE "move file" updates references).
- **Risk:** import churn. **Breaking:** none at runtime. **Test:** analyze + smoke
  each auth/splash screen.

### Step 3 — Consolidate persistence into `core/storage/` — ✅ DONE
- Moved `core/database/drift/**` → `core/storage/database/drift/**`;
  `core/database/secure/**` → `core/storage/secure/**`;
  `core/local/{hive_service,app_preferences,local_cache}` → `core/storage/hive/`;
  `core/session/session_manager.dart` → `core/storage/session/`.
- The empty `secure_strorage`/`file_strorage` stubs were deleted rather than
  renamed (they contained no implementation).
- Box names and DB file names were **not** changed — only Dart file locations —
  so existing encrypted databases open unchanged.
- **Verified:** `flutter analyze` clean; **all 73 tests pass** (incl. DAO + migration
  + key-rotation).
- **Rollback:** revert; no data migration performed, so safe.

### Step 4 — Localization to `core/localization/` — ✅ DONE (files)
- Moved `localization_services` + `localized_builder` → `core/localization/`.
  `LanguageCubit` remains registered in DI (still under `features/localization`;
  moving the cubit is optional follow-up).
- **Risk:** locale not applied at boot — **test:** switch EN↔KH, verify Kantumruy
  font + strings.

### Step 5 — Routing to `core/routing/`; rename `Static`→`AppRoutes`
- Move `lib/routes/**` → `core/routing/`. Rename class `Static`→`AppRoutes`
  (IDE rename-symbol updates all call sites).
- **Risk:** deep links / `onGenerateRoute` — **test:** every route constant.

### Step 6 — DI standardization (fixes P6) — ✅ DONE
- Renamed `initCustomerFeatures()` → `registerHomeFeature(GetIt sl)`, moved to
  `features/home/home_injection.dart`, now takes `sl` as a parameter.
- No collapse was needed: it and `registerCustomerFeature()` registered different
  types (no duplicate binding ever existed).
- **Risk:** duplicate-binding exceptions surface here (good — catch at startup).
  **Test:** cold start; every bloc resolves.

### Step 7 — Complete `notification` layering (fixes P9)
- Add `domain/repositories/notification_repository.dart`, a local datasource, and
  `data/repositories/notification_repository_impl.dart`; bind `fetch_notifications`.
- **Risk:** low (additive). **Test:** open notifications sheet.

### Step 8 — Layer hygiene (fixes P10/P12/P13)
- Move `home/domain/dashboard_summary.dart` → `home/domain/entities/`.
- Move `my_visits/presentation/{mock,models}` → `my_visits/data/`.
- Rename `oders_card_widget.dart`→`orders_card_widget.dart`.
- Unify the two `NotificationItem` entities (pick notification's, delete lead's,
  re-point lead imports).
- **Risk:** import churn only.

### Step 9 — Decompose god-screens (incremental, per-screen PRs)
- One PR per screen: extract sections of `lead_detail`, `customer_detail`,
  `route_check_in`, `quotation_builder`, `add_customer_bottom_sheet` into
  `presentation/widgets/<screen>/`.
- **Risk:** visual regressions — **test:** golden/screenshot the screen before &
  after; behavior unchanged.

### Step 10 — Bounded-context decision: `revenue` vs `order` (design spike first)
- Spike: diff `revenue` and `order` domains; decide fold-in vs distinct context
  vs extract shared `catalog`. Implement behind the decision. **Highest risk —
  schedule last, its own epic.**

### Cross-cutting risk register

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Encrypted DB fails to open after storage move | Low | Never rename DB file/box/keys; only move Dart files. Migration test gate. |
| Duplicate DI binding throws at startup | Medium | Step 6 surfaces it deterministically; fix before merge. |
| Visual regression from widget de-dup/god-split | Medium | Golden tests per touched screen; small PRs. |
| Import boundary re-violated later | Medium | CI lint added in Step 0. |
| `revenue`/`order` merge loses a code path | High | Design spike + feature-flag; last. |

### Testing strategy per step
- **Every step:** `flutter analyze` clean + `flutter test` green + cold-start smoke.
- **Storage/DB steps (3):** DAO + migration + key-rotation tests must pass, plus a
  manual "existing install upgrades cleanly" check.
- **UI steps (2, 9):** golden/screenshot comparison.
- **DI step (6):** assert all registered types resolve (add a `GetIt.allReady`/
  resolution smoke test).

### Rollback plan
Each step is one PR on the refactor branch, independently revertible. No data
migrations are performed (only source files move), so any step can be reverted
without touching user devices. Merge to `main` only after the full branch is green
in CI and QA-smoked on a real device with an existing encrypted DB.

---

## 10. README Blueprint

> Paste the section below into `README.md` (the repo's current `README.md` is a
> 654-byte stub). It is written for onboarding a new engineer in one sitting.

### Project Overview
ISI Steel Sales Mobile is the centralized, offline-first field-sales & CRM app for
KIC GROUP and its subsidiaries. Sales reps use it to browse the product catalog,
build quotations and sales orders, manage customers and leads, and run GPS-verified
field visits — **fully offline**, syncing to **SAP** when connectivity returns.

**Purpose & business goals:** increase field productivity, guarantee data capture
in low-connectivity areas, prevent visit fraud (geofence + proof photos), and give
HQ a real-time-when-online pipeline of customers, leads, quotations, and orders.

### Architecture Philosophy
Feature-First **Clean Architecture** + **DDD** + **SOLID**, **offline-first**,
**hexagonal** platform boundaries. Three rules to remember:
1. Dependencies point **inward**: presentation → domain ← data.
2. Features are **isolated**; they collaborate only via DI contracts, routes, or
   streams.
3. Reads are **local-first**; writes are **local + queued**; the sync engine
   reconciles with SAP.

### Technology Stack
Flutter 3.3+/Dart · `flutter_bloc` (+`bloc_concurrency`) · `get_it` DI · `dio`
(SAP client) · `drift` + `sqlite3` + `sqlcipher_flutter_libs` (encrypted DB) ·
`hive_flutter` + `flutter_secure_storage` (key-value/secrets) · `envied` (secrets)
· `connectivity_plus` · `geolocator`/`geocoding`/`google_maps_flutter` ·
`mobile_scanner` · `speech_to_text` · `image_picker`/`file_picker` · `fl_chart` ·
`flutter_screenutil` · `intl`/`flutter_localizations`. Tests: `bloc_test`,
`mocktail`, `drift` in-memory.

### Project Structure
See §4 of this blueprint. Top level: `core/` (infra), `shared/` (reusable UI),
`features/` (vertical slices), `app.dart`/`main.dart`/`bootstrap.dart`.

### Folder Responsibilities / Core / Shared / Feature layers
See §6, §7, §8.

### Architecture & Dependency Diagram / Data Flow
See §5.

### Repository Pattern
Abstract contract in `domain/repositories/*.dart`; implementation in
`data/repositories/*_impl.dart`. The impl orchestrates local + remote datasources
and mappers, returns **entities** (never models) wrapped in `Either<Failure, T>` /
`Result`.

### Offline Strategy
Every read hits Drift first and returns immediately. Sync-capable features expose a
`*_sync_repository` with `run<X>InitialSync` / `run<X>DeltaSync`. Last-synced
timestamps are persisted (`get_*_last_synced_at`). The UI shows sync banners
(`sync_status_banner`, `connectivity_banner`).

### Sync Strategy
Writes create `SyncQueueItem`s (`core/sync/sync_queue_service.dart`). `SyncEngine`
drains the queue on connectivity, pushes batches to SAP via `RemoteDataSource`,
pulls deltas, and `ConflictResolver` reconciles before writing back to Drift.

### Database & Security
Drift over SQLCipher. The DB key is a **device-bound composite key**
(`core/storage/secure/key_derivation.dart` + `app_database_key_provider.dart`) with
**rotation** support (`database_key_rotator.dart`). Secrets come from `envied`
(`core/config/env.dart`) — never hard-coded. Session lives in the encrypted Hive
box + `SessionManager`.

### Routing / Localization / DI
Routing: `core/routing/app_routes.dart` (constants) + `onGenerateRoute` + global
`navigatorKey`; primary navigation is a bottom-nav `IndexedStack` in `shell`.
Localization: EN + Khmer (Kantumruy font), runtime in `core/localization` driven by
`LanguageCubit`. DI: `get_it`; root `initDependencies()` calls each feature's
`register<Feature>Feature(sl)`.

### Coding Standards & Naming
See the naming table in §4. `flutter_lints` enforced via `analysis_options.yaml`.

### State Management
BLoC/Cubit. Cubit for simple state, Bloc for event streams. States are immutable
(`equatable`). No business logic in widgets; widgets read state and dispatch
events/usecases via the bloc.

### Error Handling
Datasources throw typed `Exception`s (`core/error/exceptions.dart`); repositories
catch and return typed `Failure`s (`core/error/failures.dart`). Presentation maps
`Failure` → user-facing message. Never let a raw exception reach the UI.

### Testing Strategy
Unit-test usecases and repositories (mock datasources with `mocktail`); DAO/DB
tests with in-memory Drift; bloc tests with `bloc_test`; widget/golden tests for
shared components and refactored screens. CI gate: `flutter analyze` + `flutter test`.

### CI/CD & Environment Configuration
Environments via `envied` compile-time classes and `--dart-define`/flavors
(`.env`, `.env.example`). Pipeline: analyze → test → build (flavored) → distribute.
(See `docs/cl_cd_deployment.md`.)

### How-to Recipes
- **Add a feature:** scaffold the three-layer folder (§4), add
  `register<Feature>Feature(sl)`, wire a route in `core/routing`, add a shell tab
  if user-facing.
- **Create a repository:** contract in `domain/repositories`, impl in
  `data/repositories`, bind in the feature injection.
- **Create a use case:** one class extending `UseCase<Return, Params>` in
  `domain/usecases`; inject the repository; bind in DI.
- **Create a bloc:** `presentation/bloc/<name>_{bloc,event,state}.dart`; inject
  usecases; register as `factory` in DI.
- **Add an API:** add method to `RemoteDataSource`, route through `sap_client`, map
  DTO→entity in a mapper, expose via repository.
- **Add a DB table:** add a Drift `Table` in `core/storage/database/drift/tables`,
  a DAO, bump schema version, write a migration + migration test.
- **Add localization:** add keys to the ARB/JSON in `core/localization`, run
  codegen, use via the localized builder.
- **Add assets:** drop under `assets/<group>/`, declare in `pubspec.yaml`.

### Project Rules — Do & Don't
**Do:** keep features isolated; return entities from repositories; wrap platform
SDKs behind domain ports; write a test for every usecase and DAO; keep screens thin.
**Don't:** import one feature from another; call Dio/Drift from presentation; put
business logic in widgets; hard-code secrets; rename DB files/box names casually;
create a new "utils" dumping ground.

### Performance & Security Guidelines
Performance: local-first reads, paginate (`paged_result`), lazy DI singletons,
`cached_network_image`, skeleton loaders. Security: SQLCipher + rotating composite
key, secrets via `envied`, secure storage for tokens, geofence + proof-photo fraud
checks, no PII in logs.

### Deployment Process & Future Roadmap
Deployment per `docs/cl_cd_deployment.md`. Roadmap: complete SAP endpoints (retire
mock datasources), finish `notification` layer, resolve `revenue`/`order` bounded
context, push-notification deep links, extract reusable `sync`/`secure-db` packages
if a second app appears.

---

## 11. Final Recommendations

1. **Refine, don't rewrite.** This codebase is already a competent Feature-First
   Clean Architecture implementation with real offline-first and security depth.
   The ROI is in **consistency**: one DI convention, one bloc-folder shape, a real
   `shared/` layer, consolidated `core/storage/`. Follow the 10-step plan in §9.
2. **Add the boundary lint on day one.** A CI check that `core/`/`shared/` never
   import `features/`, and that features never import each other, is what keeps
   this architecture true as the team grows. Convention without enforcement decays.
3. **Kill the confirmed duplicates immediately** (Step 1–2): `verion.dart`, the
   empty `hive/hive_service.dart`, aurora/glass copies, dual `NotificationItem`.
   These are cheap wins that build momentum and remove traps.
4. **DI is already deterministic** (P6, corrected) — the suspected "double customer
   registration" did not exist; the two functions bound different types. The applied
   fix was naming/placement only (`initCustomerFeatures` → `registerHomeFeature`).
5. **Treat `revenue` vs `order` as an explicit product decision**, not a refactor.
   Do the design spike (Step 10) before writing code; it is the only high-risk item.
6. **Guard the encrypted DB.** During the storage consolidation, move Dart files
   only — never DB filenames, box names, or key material. Gate every storage PR on
   the migration test + a real-device upgrade smoke test.
7. **Decompose god-screens opportunistically**, one PR each, behind golden tests —
   don't block the structural refactor on it.
8. **Defer heavy tooling** (monorepo packages, `go_router`, codegen DI) until a
   concrete second consumer or second team exists. Simplicity with scalability beats
   speculative generality.

**Bottom line:** the foundation is enterprise-grade. Ship the standardization plan
incrementally, enforce the boundaries in CI, and this scales cleanly to hundreds of
features and multiple teams.
```
