<div align="center">

<img src="assets/logos/isi_app_logo.png" alt="ISI Steel 360" width="96" />

# ISI Steel Sales Mobile

**Offline-first enterprise CRM for the field sales force of KIC GROUP and its subsidiaries.**

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20BLoC-6E56CF)](docs/ARCHITECTURE.md)
[![Storage](https://img.shields.io/badge/Storage-Drift%20%2B%20SQLCipher-1FA37A)](docs/DATABASE_GUIDE.md)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%C2%B7%20iOS-444)](#platform-support)
[![License](https://img.shields.io/badge/License-Proprietary-C7362F)](#license)

</div>

---

## Overview

Sales reps work where connectivity does not: warehouses, factory yards, rural routes. This app is built around that single constraint — **every read is served from a local encrypted database, and every write succeeds locally first**, syncing to SAP opportunistically when the network returns.

The result is a guest-first CRM that never blocks a user on a round-trip: browse the product catalog, manage customers and leads, plan and execute visit routes, capture proof photos and GPS check-ins, and build quotations and sales orders — online, offline, or anywhere in between.

| | |
|---|---|
| **Domain** | Steel distribution · field sales · SAP-backed order-to-cash |
| **Scale** | 13 feature modules · 27 screens · ~770 Dart files · 47 test suites |
| **Backend** | SAP Core API gateway (via `core/network/sap_client.dart`) |
| **Languages** | English · ភាសាខ្មែរ (Khmer), with locale-aware master data |

---

## Feature Modules

| Module | What it does |
|---|---|
| **`authentication`** | Guest-first login, OTP verification, password recovery, hardware-backed token storage |
| **`shell`** | App shell, bottom navigation, KPI surface, global connectivity and sync indicators |
| **`home`** | Dashboard, quick actions, at-a-glance sales performance |
| **`customers`** | Customer master data, detail views, territory-aware filtering (ADR-009) |
| **`lead`** | Lead pipeline, opportunity stages, lead detail workflows |
| **`order`** | Product catalog + faceted filter, barcode / voice / image search, cart, quotation builder & PDF preview, sales orders, shop orders, territory |
| **`my_visits`** | Route planning, stop check-in/out, GPS telemetry sampling, proof photos, visit dashboards |
| **`notification`** | In-app notification centre and badges |
| **`profile` / `settings`** | User profile, theme (light/dark), language, app preferences |
| **`localization`** | Runtime language switching with persisted selection and reload flow |
| **`splash` / `app_coach`** | Boot sequencing, onboarding, contextual coaching |

---

## Architecture

Clean Architecture, three layers per feature, dependencies pointing **inward only**.

```
┌──────────────────────────────────────────────────────────────┐
│  Presentation  — screens · widgets · BLoC/Cubit              │
│                  no persistence calls, ever                  │
├──────────────────────────────────────────────────────────────┤
│  Domain        — entities · repository interfaces            │
│                  one usecase per business action (pure Dart) │
├──────────────────────────────────────────────────────────────┤
│  Data          — repository impls · Drift DAOs · SAP client  │
│                  mappers between rows/DTOs and entities      │
├──────────────────────────────────────────────────────────────┤
│  Core          database · network · sync · security          │
│                session · di · theme · logging · responsive   │
└──────────────────────────────────────────────────────────────┘
```

Each feature registers itself through a single `<feature>_injection.dart` exposing `register<Feature>Feature(GetIt sl)`, all wired from [injection_container.dart](lib/core/di/injection_container.dart). Boot lives in exactly one place — [app_bootstrap_service.dart](lib/core/bootstrap/app_bootstrap_service.dart) — which performs no network I/O and no navigation, so the app starts identically offline.

### The four persistence layers

Every piece of data is assigned to exactly one store, by sensitivity and shape. This is a hard boundary, not a preference.

| Layer | Store | Holds | Encrypted |
|---|---|---|---|
| **1 · Business data** | Drift (single SQLite DB) | customers, products, routes, visits, orders, quotations, sync queue | ✅ SQLCipher |
| **2 · Preferences** | Hive | onboarding flags, UI filters, cached lookups | — (never PII/tokens) |
| **3 · Secrets** | `flutter_secure_storage` | access/refresh tokens, cached user, device key | ✅ Keychain / Keystore |
| **4 · Media** | App-sandboxed filesystem | photos, signed documents, attachments (path-only in Drift) | 🚧 Phase 5 |

The database key is never static. It is derived at runtime as `SHA256(Env.dbSalt + DeviceKey)`, where `DeviceKey` is a 256-bit CSPRNG value sealed in the platform keystore — neither the binary nor the device alone is sufficient to decrypt. Opening the DB is **fail-closed**: a wrong key or missing cipher aborts rather than silently falling back to plaintext. Full detail in [DATABASE_GUIDE.md](docs/DATABASE_GUIDE.md).

### Offline-first & sync

> Connectivity is the exception the UI plans for, not an error state.

Local mutation and its sync-queue entry are written **inside the same transaction**, so a crash can never produce a row that will never sync. The UI updates optimistically from local data; the server round-trip happens later, off the critical path, with retry, backoff, priority and conflict handling defined in [SYNC_ENGINE.md](docs/SYNC_ENGINE.md) and [OFFLINE_FIRST.md](docs/OFFLINE_FIRST.md).

---

## Tech Stack

| Concern | Choice |
|---|---|
| **Framework** | Flutter 3.44 · Dart 3.3+ |
| **State** | `flutter_bloc` · `bloc_concurrency` · `equatable` |
| **DI** | `get_it`, one injection module per feature |
| **Database** | `drift` + `sqlite3` + `sqlcipher_flutter_libs` (16 tables, 9 DAOs, stepwise migrator) |
| **Key/secret storage** | `flutter_secure_storage` · `envied` (compile-time obfuscated config) |
| **Preferences** | `hive_flutter` |
| **Networking** | `dio` · `connectivity_plus` · custom reachability probe (ADR-005) |
| **Location & maps** | `geolocator` · `geocoding` · `google_maps_flutter` |
| **Capture** | `mobile_scanner` · `image_picker` · `speech_to_text` · `file_picker` |
| **Documents** | `pdf` · `printing` · `open_filex` |
| **UI** | Material 3 · `flutter_screenutil` · `fl_chart` · `lottie` · `cached_network_image` · Inter + Kantumruy |
| **Testing** | `flutter_test` · `bloc_test` · `mocktail` |
| **Codegen** | `build_runner` · `drift_dev` · `json_serializable` · `envied_generator` |

---

## Getting Started

### Prerequisites

- Flutter **3.44+** (stable) with Dart **3.3+**
- Xcode 15+ (iOS) · Android Studio with SDK 21+ (Android)
- CocoaPods (iOS)

### 1 · Install dependencies

```bash
flutter pub get
```

### 2 · Configure the environment

Configuration is compile-time and obfuscated via [Envied](lib/core/config/env.dart) — no endpoint or salt ships as a literal string. Create a `.env` at the repo root (git-ignored, **never commit it**):

```dotenv
API_BASE_URL=https://api.example.com
SAP_API_URL=https://sap-gateway.example.com
DB_SALT=<random-high-entropy-string>
GOOGLE_MAPS_API_KEY=<maps-key>
```

Switching environments is a file swap (`.env.development` → `.env`), not a source change.

### 3 · Generate code

```bash
dart run build_runner build --delete-conflicting-outputs   # Drift, Envied, JSON
dart run tool/generate_ios_env.dart                        # iOS: .env → Env.xcconfig
```

> `generate_ios_env.dart` is required before any iOS build — it is how the Maps key reaches `Info.plist` without living in git history.

### 4 · Run

```bash
flutter run                        # attached device
flutter run --release              # release-mode profiling
```

---

## Common Commands

| Task | Command |
|---|---|
| Static analysis | `flutter analyze` |
| Format check | `dart format --set-exit-if-changed .` |
| Run all tests | `flutter test` |
| Single test | `flutter test test/features/order/cart_drift_local_data_source_test.dart` |
| Watch codegen | `dart run build_runner watch --delete-conflicting-outputs` |
| App icons | `dart run flutter_launcher_icons` |
| Mock data | `dart run tool/generate_mock_products.dart` · `dart run tool/generate_mock_routes.dart` |
| Android release | `flutter build appbundle --release` |
| iOS release | `dart run tool/generate_ios_env.dart && flutter build ipa --release` |

---

## Project Structure

```
lib/
├── core/                       # shared infrastructure — features depend on this, never on each other
│   ├── bootstrap/              # single boot sequence (no I/O, no navigation)
│   ├── config/                 # Envied compile-time config
│   ├── database/
│   │   ├── drift/              # app_database · tables/ · daos/ · migrations/
│   │   ├── hive/               # non-sensitive preference boxes
│   │   └── secure/             # DynamicKeyStore · KeyDerivation
│   ├── network/                # dio client · connectivity · SAP gateway
│   ├── sync/                   # queue · engine · conflict manager
│   ├── session/  auth/  di/    # session manager · guards · get_it wiring
│   ├── responsive/  theme/     # breakpoints · adaptive sizing · Material 3 themes
│   └── platform/  services/    # platform-split implementations (native/web)
├── features/<domain>/
│   ├── data/                   # repository impls · datasources · models
│   ├── domain/                 # entities · repository interfaces · usecases
│   ├── presentation/           # screens · widgets · bloc
│   └── <domain>_injection.dart
├── shared/                     # cross-feature widgets (glass card, bottom sheet, …)
├── routes/                     # route table + page builders
├── app.dart                    # MaterialApp, locales, theme, global providers
└── main.dart
assets/  docs/  test/  tool/  web/
```

---

## Localization

Two locales ship: `en` and `km`, defined in [app.dart](lib/app.dart) as `kSupportedLocales` and backed by `assets/lang/*.json`. Khmer renders in **Kantumruy**, Latin in **Inter**, selected per locale. Master data is stored bilingually so a language switch does not degrade catalog content — guarded by tests such as [product_delta_preserves_khmer_test.dart](test/features/order/product_delta_preserves_khmer_test.dart). See [docs/localization/LOCALIZATION.md](docs/localization/LOCALIZATION.md).

---

## Testing

```bash
flutter test                       # 47 suites: core infra, DAOs, blocs, localization, sync
flutter test --coverage
```

Coverage focuses on the layers where correctness is expensive to lose: Drift datasources, sync/conflict paths, locale resolution, session reset, log redaction, and filter/catalog blocs.

---

## Platform Support

| Platform | Status |
|---|---|
| **Android** | ✅ Supported (min SDK 21) |
| **iOS** | ✅ Supported |
| **Web** | 🚧 Planning — blocked on encrypted persistence and responsive layer; see [flutter-web-support.md](docs/flutter-web-support.md) and ADR-010 |

---

## Documentation

The `docs/` set is the source of truth for how this codebase is built. Start here:

| Document | Read it for |
|---|---|
| [ENGINEERING_STANDARD.md](docs/ENGINEERING_STANDARD.md) | The master rules every other doc implements |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers, dependency graph, folder structure, known gaps |
| [DATABASE_GUIDE.md](docs/DATABASE_GUIDE.md) | Drift schema, DAOs, encryption and key rotation |
| [OFFLINE_FIRST.md](docs/OFFLINE_FIRST.md) | Boot flow, guest-first identity, per-domain offline posture |
| [SYNC_ENGINE.md](docs/SYNC_ENGINE.md) | Queue lifecycle, retry/backoff, conflict resolution |
| [SECURITY.md](docs/SECURITY.md) | OWASP MASVS mapping, storage rules, release gates |
| [MIGRATION_PLAN.md](docs/MIGRATION_PLAN.md) | Sprint-by-sprint plan to close infrastructure gaps |
| [cl_cd_deployment.md](docs/cl_cd_deployment.md) | CI/CD pipeline, signing, beta and store distribution |
| [adr/](docs/adr) | 10 accepted decisions — single DB, offline-first, DAO pattern, SQLCipher path, web persistence |
| [features/](docs/features) | Per-feature blueprints, business rules, QA/UAT plans |

A queryable knowledge graph of the codebase lives in `graphify-out/` — see [GRAPHIFY.md](docs/GRAPHIFY.md).

---

## Project Status

The presentation and domain layers are mature; `core/` is being filled in deliberately, module-by-module, in dependency order.

| Area | State |
|---|---|
| Feature UI & domain layers | ✅ Built across 13 modules |
| Encrypted Drift database (16 tables, DAOs, migrator, rekey) | ✅ Built and verified |
| Envied config + device-bound key derivation | ✅ Built |
| Legacy plaintext `sqflite` → encrypted import & purge | 🚧 In progress (P0) |
| Sync engine, conflict manager, SAP client | 🚧 Stubbed — target defined in `SYNC_ENGINE.md` |
| RBAC, workflow layer, structured logging | 📋 Planned |

**The one rule that overrides everything:** no production code is written for a module until its plan and dependencies are validated — see `ENGINEERING_STANDARD.md` §2.

---

## Contributing

1. Branch from `main`; keep changes scoped to one module.
2. Respect the layer boundary — presentation never touches Drift, `dio`, or secure storage directly.
3. New persistence goes through a shared DAO in `core/database/drift/daos/`, never a feature-private database.
4. Add tests alongside behaviour; run `flutter analyze` and `flutter test` before opening a PR.
5. Architectural changes need an ADR in [docs/adr/](docs/adr), not just a commit message.

**Never commit** `.env`, `Env.xcconfig`, keystores, or any generated `*.g.dart` secret material.

---

## License

Proprietary — © KIC GROUP. Internal use only. All rights reserved.
