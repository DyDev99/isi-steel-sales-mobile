# CLAUDE.md — Project Instructions for Claude

> ISI Steel Sales Mobile — Offline-First Enterprise CRM (Flutter)
> This file is read automatically at the start of every session in this repo. It tells you what this project is, what state it's actually in, and the rules you must follow before writing any code.
>
> **Before writing any code, also open `docs/AI_ENGINEERING_PLAYBOOK.md`.** This file (`CLAUDE.md`) is the pointer; the playbook is the operational manual — conventions, naming, folder ownership, the feature/PR/review checklists, refactoring and performance rules, security and offline checklists, anti-patterns, and a full worked code example of the correct layering. Keep it open while you work, not just at session start.

---

## 1. Read this first: the one rule that overrides everything

**No production code is written for a module until that module's plan and its dependencies are validated and approved.** Implementation proceeds **module-by-module**, in dependency order, never ahead of it. See `docs/ENGINEERING_STANDARD.md` §2 and `docs/MIGRATION_PLAN.md` §14.

Concretely, before you touch code:

- Check `docs/MIGRATION_PLAN.md` for which sprint/phase is currently active and what its acceptance criteria are.
- Check `docs/ARCHITECTURE.md` §4 (dependency graph) — do not implement a feature's data layer against infrastructure that doesn't exist yet.
- If asked to build something that jumps ahead of the plan (e.g., a new feature's Drift DAO before the encrypted database exists), say so explicitly and point to what's blocking it, rather than improvising a workaround.

**Current status (2026-07-15): Planning — no production code beyond the already-started, paused T1.1 encryption work is authorized until the migration plan is approved.** Next actionable work is Sprint 1 / T1.0 (Envied config) → T1.3 (encrypted `AppDatabase`) — see `docs/MIGRATION_PLAN.md` §7.

---

## 2. What this app is

A guest-first, offline-first CRM for a field sales force: catalog browsing, customer/lead management, route and visit execution, stock counts, quotations, and sales orders that eventually sync to SAP. Sales reps routinely work with no connectivity for hours at a time — **every write must succeed locally first**; sync is opportunistic, never blocking. See `docs/ARCHITECTURE.md` §1.

The codebase today (`demo/app01`) is a **UI-complete demo (~80%)** with a **hollow infrastructure core**: persistence is three plaintext `sqflite` databases, there is no encryption, and `core/sync/*` is mostly 0-byte stub files. The UI/BLoC/Clean-Architecture layering above that core is genuinely good — the gap is infrastructure, not design. Do not mistake an empty stub file for "not needed"; check `docs/ARCHITECTURE.md` §6 and `docs/MIGRATION_PLAN.md` §3 for the tracked list of what's actually missing.

---

## 3. Tech stack

- **Flutter** — target platforms: Android, iOS.
- **State management**: `flutter_bloc` (BLoC/Cubit). See `docs/ENGINEERING_STANDARD.md` §4.
- **Persistence**: migrating to **Drift** (single encrypted database) from per-feature `sqflite`. Encryption via a composite device-bound key, not a static one — see `docs/DATABASE_GUIDE.md` §2. New database code should target `sqlite3mc` (`SQLite3MultipleCiphers`) via Drift's `user_defines` hook, per current Drift guidance, not the legacy `sqlcipher_flutter_libs` package — confirm this hasn't changed before assuming it (see the note in `docs/DATABASE_GUIDE.md` §2.3).
- **Non-sensitive local prefs**: Hive.
- **Secrets**: `flutter_secure_storage` (iOS Keychain / Android Keystore) — tokens, cached user, and the device encryption key only. Never anything else.
- **DI**: `get_it` (currently ad hoc per feature; formalize per `docs/MIGRATION_PLAN.md` §3).
- **Config obfuscation**: `Envied` (not yet integrated — Sprint 1, T1.0).
- **CI/CD**: GitHub Actions + Fastlane, branches `main`/`develop`/`feature/*`/`release/*`/`hotfix/*`. See `docs/MIGRATION_PLAN.md` §11.

---

## 4. Architecture rules (enforce these on every change)

- **Clean Architecture, inward dependencies only**: `presentation (BLoC) → domain (entities, usecases, repository interfaces) → data (repository impls, Drift DAOs, remote datasources)`. Domain code must never import Flutter, Drift, or `dio` types. See `docs/ARCHITECTURE.md` §2, ADR-003.
- **Repository pattern**: all data access goes through a domain-defined repository interface; repository implementations return domain entities, never raw Drift rows or DTOs. See ADR-003.
- **DAO pattern**: all local reads/writes go through generated Drift DAOs in `core/database/drift/daos/`. No feature holds a private database handle. See ADR-004, `docs/DATABASE_GUIDE.md` §4.
- **One usecase per business action.** No usecase branches on a "mode" parameter to do several unrelated things.
- **Transactional writes**: any write to a syncable table must enqueue its sync-queue row in the *same* Drift transaction as the mutation. This is a hard correctness rule, not a style preference — see ADR-006, `docs/SYNC_ENGINE.md` §2.
- **No feature imports another feature's `data/` layer.** Cross-feature flows go through domain interfaces or a shared orchestration layer.
- **Naming**: use `conflict_manager.dart` (not `conflict_resolver.dart`) and `dynamic_key_store.dart` (not `secure_strorage.dart`) — these are named, deliberate corrections of drift already found in the codebase. See `docs/ENGINEERING_STANDARD.md` §9.

Full detail: `docs/ARCHITECTURE.md`, `docs/DATABASE_GUIDE.md`, `docs/SYNC_ENGINE.md`, `docs/OFFLINE_FIRST.md`.

---

## 5. Security rules (non-negotiable)

- Never store tokens, passwords, or PII in `SharedPreferences`, Hive, or an unencrypted database. Secrets go only in `flutter_secure_storage`; business data goes only in the encrypted Drift database. See `docs/SECURITY.md` §3.
- Never log passwords, tokens, API keys, customer info, phone numbers, emails, or revenue data. Allowed: endpoint, response code, error code, and stack traces in debug builds only. See `docs/SECURITY.md` §10.
- Never hardcode secrets, API keys, or endpoints in source. Use Envied-obfuscated config (once integrated) and CI secrets — never commit `.env.*` files.
- Never implement custom cryptography. Use the composite key-derivation scheme already specified in `docs/DATABASE_GUIDE.md` §2 and well-established platform/library primitives only.
- Any debug-only shortcut (mock SAP client, geofence bypass, permissive fraud policy) must be tagged `// TODO(release-gate):` and must never ship in a release build — see `docs/SECURITY.md` §11 release checklist.

Full detail: `docs/SECURITY.md`.

---

## 6. Testing expectations

Do not consider a change finished without the test tiers that apply to it. Coverage gates (CI-enforced): domain ≥ 90%, data ≥ 80%, cryptography and sync-queue code 100% of branches. See `docs/ENGINEERING_STANDARD.md` §10 for the full matrix (unit, repository, DAO, integration, offline/chaos, conflict, security, widget, golden).

Common commands:

```bash
flutter analyze                 # must be clean before any PR
dart format --set-exit-if-changed .
flutter test                    # unit + widget
flutter test integration_test/  # integration
dart run build_runner build --delete-conflicting-outputs   # after any Drift table/DAO change
```

(Verify exact scripts against `pubspec.yaml` / `melos.yaml` / CI config if they differ from the above — this file describes intent, the repo's actual scripts are the source of truth for exact invocations.)

---

## 7. Document map — read the relevant one before working in that area

| Area | Document |
|---|---|
| **Day-to-day operational manual — checklists, conventions, worked code example** | **`docs/AI_ENGINEERING_PLAYBOOK.md`** |
| Cross-cutting engineering rules | `docs/ENGINEERING_STANDARD.md` |
| System overview, layers, folder structure, dependency graph | `docs/ARCHITECTURE.md` |
| Offline behavior, guest-first auth, resumable workflow | `docs/OFFLINE_FIRST.md` |
| Drift schema, DAOs, encryption | `docs/DATABASE_GUIDE.md` |
| Sync queue, conflict resolution, DLQ | `docs/SYNC_ENGINE.md` |
| Security standards, OWASP mapping, release checklist | `docs/SECURITY.md` |
| Phased rollout, sprints, task backlog, risk register | `docs/MIGRATION_PLAN.md` |
| Why key decisions were made (one per major decision) | `docs/adr/ADR-001` through `ADR-008` |

Architecture Decision Records (`docs/adr/`):

- **ADR-001** — single encrypted Drift database (vs. three plaintext `sqflite` DBs)
- **ADR-002** — offline-first: local database as source of truth
- **ADR-003** — repository pattern (domain interfaces / data implementations)
- **ADR-004** — generated Drift DAOs (vs. hand-written local datasources)
- **ADR-005** — connectivity service: real reachability, not interface-up
- **ADR-006** — unified sync engine, server-authoritative conflict resolution
- **ADR-007** — generalized, resumable `WorkflowSession`

When code and these documents disagree, the documents describe the *target* — flag the discrepancy rather than silently treating the code as correct, per `docs/ENGINEERING_STANDARD.md` §11.

---

## 8. When you're unsure

- If a task would build a feature ahead of its infrastructure dependency (§1, `docs/ARCHITECTURE.md` §4), stop and say so — don't build a temporary workaround that becomes permanent.
- If a task touches encryption, key management, or the sync queue, read `docs/DATABASE_GUIDE.md` §2 and `docs/SYNC_ENGINE.md` in full first — these are the highest-consequence, hardest-to-safely-retrofit parts of the system.
- If you find a stub file (`core/sync/*`, `core/database/files/*`, `core/network/sap_client.dart`), treat it as **tracked and expected to be empty right now**, not evidence the feature is unneeded — check `docs/MIGRATION_PLAN.md` for its planned sprint before assuming scope.