# CLAUDE Automation Operating System

This project uses Claude as an autonomous engineering agent.

Claude must behave as an engineer responsible for the complete lifecycle of a task, not merely as a code generator.

The default lifecycle is:

```text
REQUEST
  ↓
UNDERSTAND
  ↓
DISCOVER
  ↓
GRAPH ANALYSIS
  ↓
PLAN
  ↓
DEPENDENCY CHECK
  ↓
IMPLEMENT
  ↓
FORMAT
  ↓
ANALYZE
  ↓
TEST
  ↓
BUILD / VERIFY
  ↓
DIFF REVIEW
  ↓
FINAL REPORT
```

The task is not considered complete until the applicable verification stages have been performed.

---

## 0.1 Non-Negotiable Agent Principles

### Principle 1 — Understand Before Editing

Never modify production code immediately after receiving a task.

First determine:

* What the user actually wants.
* Which feature/module owns the behavior.
* Which files are involved.
* Which architecture layer owns the change.
* Which dependencies the change has.
* Which existing implementation should be reused.
* What tests already exist.
* What project documentation governs the change.

---

### Principle 2 — Repository Is the Source of Truth

Do not invent project structure, APIs, classes, services, or patterns.

Search the repository first.

If documentation and implementation disagree:

1. Identify the discrepancy.
2. Determine whether the documentation describes the target architecture.
3. Do not silently rewrite architecture based on assumptions.
4. Report the discrepancy when it affects the task.

---

### Principle 3 — Graphify Before Significant Changes

Graphify is the project's codebase intelligence layer.

Before changing an existing production module, Claude should use Graphify whenever the change could affect dependencies, callers, data flow, or shared infrastructure.

Use Graphify to answer questions such as:

```text
What depends on this?
What does this depend on?
Who calls this?
What is the blast radius?
Is this a shared/god node?
What path connects these components?
What modules are affected?
```

Prefer:

```bash
graphify query
graphify path
graphify explain
graphify affected
graphify god-nodes
```

before making high-impact changes.

After significant architectural changes, refresh the graph:

```bash
graphify update
```

---

## 0.2 Task Classification

Every incoming task should be classified before implementation.

### Type A — Small Change

Examples:

* Typo
* Small UI adjustment
* Simple validation
* Local bug fix
* Documentation change

Workflow:

```text
Inspect → Implement → Test → Review
```

---

### Type B — Feature Change

Examples:

* New screen
* New use case
* New repository
* New API integration
* New database feature

Workflow:

```text
Inspect
→ Graphify
→ Architecture validation
→ Dependency validation
→ Plan
→ Implement
→ Test
→ Review
```

---

### Type C — Infrastructure Change

Examples:

* Database
* Encryption
* Authentication
* Sync engine
* Networking
* Dependency injection
* Offline persistence

Workflow:

```text
Inspect
→ Read governing documentation
→ Graphify dependency analysis
→ Migration-plan validation
→ Risk analysis
→ Plan
→ Implement
→ Full relevant test suite
→ Build verification
→ Review
```

---

### Type D — High-Risk Change

Examples:

* Cryptography
* Authentication
* Authorization
* Customer/PII data
* Sync conflict resolution
* Database migration
* Production configuration
* Security controls

These require explicit verification of:

```text
Architecture
Security
Data integrity
Failure behavior
Offline behavior
Migration safety
Tests
```

Do not optimize for speed at the expense of correctness.

---

# 0.3 Autonomous Execution Policy

Claude should solve routine engineering decisions autonomously.

Do not ask the user:

> Should I inspect the repository?

Inspect it.

Do not ask:

> Should I run tests?

Run them.

Do not ask:

> Should I format the code?

Format it.

Do not ask:

> Should I investigate this dependency?

Investigate it.

Ask the user only when a decision genuinely requires human/business authority or when proceeding could cause destructive or irreversible consequences.

---

# 0.4 Plan Before Implementation

For any non-trivial task, create a short implementation plan.

Example:

```text
Plan

1. Inspect existing notification architecture.
2. Locate Firebase initialization and notification service.
3. Use Graphify to identify affected callers.
4. Verify architecture and migration constraints.
5. Implement token handling in the existing service.
6. Add token-refresh handling.
7. Add/adjust tests.
8. Run formatter and analyzer.
9. Run relevant tests.
10. Review git diff.
```

The plan must be based on repository evidence, not assumptions.

---

# 0.5 Dependency-First Rule

Never implement a component against infrastructure that does not exist.

Before implementation ask:

```text
Does this module depend on another module?

Does that dependency already exist?

Is it implemented?

Is it approved by the migration plan?

Is the architecture ready for this change?
```

If the required dependency does not exist:

1. Stop implementation of the dependent module.
2. Identify the missing dependency.
3. Check the migration plan.
4. Explain the dependency chain.
5. Implement the prerequisite only if it is within the authorized scope.

Never create a temporary architectural workaround merely to make a task appear complete.

---

# 0.6 Change-Scope Control

Claude must continuously distinguish:

```text
Required Change
```

from:

```text
Nice-to-Have Change
```

Only implement the required change unless the additional change is necessary for correctness, security, testing, or architecture.

Do not use a feature task as an excuse to perform unrelated refactoring.

---

# 0.7 Blast Radius Rule

Before modifying shared infrastructure, determine the blast radius.

For example:

```text
Shared repository
Shared database
Shared service
Shared BLoC
Shared utility
Network client
Authentication
Sync engine
```

Use Graphify to identify affected modules.

If the blast radius is unexpectedly large, reassess the implementation before proceeding.

---

# 0.8 Test Selection Rule

Tests must match the change.

Use this priority:

```text
Changed domain logic
    → unit tests

Changed repository
    → repository tests

Changed DAO/database
    → DAO/database tests + build_runner

Changed synchronization
    → sync + conflict + offline tests

Changed security
    → security + negative-path tests

Changed UI
    → widget/golden tests where applicable

Cross-layer change
    → integration tests where applicable
```

Never claim a task is verified merely because the application compiles.

---

# 0.9 Failure Recovery

When a command fails:

```text
READ FAILURE
↓
IDENTIFY ROOT CAUSE
↓
CHECK RELATED CODE
↓
MAKE TARGETED FIX
↓
RERUN FAILED CHECK
↓
RERUN BROADER VALIDATION
```

Do not repeatedly execute commands without understanding the failure.

Do not hide failures.

---

# 0.10 Verification Ladder

Use the smallest useful verification first, then broaden when appropriate.

```text
Level 1
Formatting
    ↓
Level 2
Static analysis
    ↓
Level 3
Targeted tests
    ↓
Level 4
Feature/module tests
    ↓
Level 5
Integration tests
    ↓
Level 6
Build verification
```

For high-risk infrastructure changes, use the broadest applicable verification.

---

# 0.11 Final Diff Inspection

Before completion, always inspect:

```bash
git status
git diff
```

Check for:

* Unexpected files
* Debug code
* Temporary code
* Secrets
* Unrelated changes
* Accidental deletions
* Generated files that should not be committed
* Incorrect imports
* Unnecessary dependencies

The final diff must tell a coherent story.

---

# 0.12 No False Completion

Claude must never say:

```text
Done
```

when important verification has not been performed.

Instead:

```text
Implemented, but verification is incomplete because ...
```

Be precise.

Never claim:

```text
Tests passed
```

unless the tests actually ran successfully.

Never claim:

```text
Build successful
```

unless the build actually completed successfully.

---

# 0.13 Security Stop Conditions

Immediately stop and reassess when a task involves:

* Private keys
* Passwords
* Access tokens
* Encryption keys
* Customer PII
* Authentication
* Authorization
* Production credentials
* Database encryption
* Sync integrity

Do not improvise cryptography or security architecture.

Follow the project's security documentation and ADRs.

---

# 0.14 User Communication

During execution, avoid unnecessary narration.

At completion, provide:

## Completed

What changed.

## Files Changed

Relevant files.

## Verification

Commands actually executed and their results.

## Notes

Assumptions, limitations, migration requirements, or follow-up work.

Example:

```text
## Completed

- Added FCM token registration.
- Added token refresh handling.
- Integrated with the existing notification service.

## Files Changed

- lib/core/notifications/notification_service.dart
- test/core/notifications/notification_service_test.dart

## Verification

- dart format --set-exit-if-changed . ✅
- flutter analyze ✅
- flutter test test/core/notifications/... ✅

## Notes

No new dependency was required.
```

---

# 0.15 Definition of Done

A task is DONE only when all applicable conditions are true:

```text
[ ] Requirement understood
[ ] Correct module identified
[ ] Governing documentation read
[ ] Graphify analysis completed when applicable
[ ] Dependency order validated
[ ] Implementation completed
[ ] Existing architecture preserved
[ ] Security requirements satisfied
[ ] Formatting passed
[ ] Static analysis passed
[ ] Relevant tests passed
[ ] Build verified when applicable
[ ] Git diff reviewed
[ ] No unrelated changes introduced
[ ] Final result accurately reported
```

---

# 0.16 Golden Rule

When uncertain:

```text
DO NOT GUESS.

INSPECT.
GRAPH.
READ.
PLAN.
IMPLEMENT.
TEST.
VERIFY.
REPORT.
```

The agent should optimize for **correctness, maintainability, safety, and architectural consistency**, not merely for producing code quickly.



# CLAUDE.md — Project Instructions for Claude

> ISI Steel Sales Mobile — Offline-First Enterprise CRM (Flutter)
> This file is read automatically at the start of every session in this repo. It tells you what this project is, what state it's actually in, and the rules you must follow before writing any code.
>
> **Building or changing a feature, screen, or any UI? `docs/skills/feature-ui-standard.md`
> is the gate — read it first and put its §14 checklist in the PR.** It covers
> security, no-crash stability, performance, responsive/adaptive, animation,
> the traditional-premium visual language, calm UX, localization,
> accessibility, and long-term scale/maintenance/upgrade readiness.
>
> **Before writing any code, also open `docs/skills/ai-engineering-playbook.md`.** This file (`.claude/CLAUDE.md`) is the pointer; the playbook is the operational manual — conventions, naming, folder ownership, the feature/PR/review checklists, refactoring and performance rules, security and offline checklists, anti-patterns, and a full worked code example of the correct layering. Keep it open while you work, not just at session start.

---

## 1. Read this first: the one rule that overrides everything

**No production code is written for a module until that module's plan and its dependencies are validated and approved.** Implementation proceeds **module-by-module**, in dependency order, never ahead of it. See `docs/skills/engineering-standard.md` §2 and `docs/blueprint/migration-plan.md` §14.

Concretely, before you touch code:

- Check `docs/blueprint/migration-plan.md` for which sprint/phase is currently active and what its acceptance criteria are.
- Check `docs/blueprint/system-architecture.md` §4 (dependency graph) — do not implement a feature's data layer against infrastructure that doesn't exist yet.
- If asked to build something that jumps ahead of the plan (e.g., a new feature's Drift DAO before the encrypted database exists), say so explicitly and point to what's blocking it, rather than improvising a workaround.

**Current status (2026-07-15): Planning — no production code beyond the already-started, paused T1.1 encryption work is authorized until the migration plan is approved.** Next actionable work is Sprint 1 / T1.0 (Envied config) → T1.3 (encrypted `AppDatabase`) — see `docs/blueprint/migration-plan.md` §7.

---

## 2. What this app is

A guest-first, offline-first CRM for a field sales force: catalog browsing, customer/lead management, route and visit execution, stock counts, quotations, and sales orders that eventually sync to SAP. Sales reps routinely work with no connectivity for hours at a time — **every write must succeed locally first**; sync is opportunistic, never blocking. See `docs/blueprint/system-architecture.md` §1.

The codebase today (`demo/app01`) is a **UI-complete demo (~80%)** with a **hollow infrastructure core**: persistence is three plaintext `sqflite` databases, there is no encryption, and `core/sync/*` is mostly 0-byte stub files. The UI/BLoC/Clean-Architecture layering above that core is genuinely good — the gap is infrastructure, not design. Do not mistake an empty stub file for "not needed"; check `docs/blueprint/system-architecture.md` §6 and `docs/blueprint/migration-plan.md` §3 for the tracked list of what's actually missing.

---

## 3. Tech stack

- **Flutter** — target platforms: Android, iOS.
- **State management**: `flutter_bloc` (BLoC/Cubit). See `docs/skills/engineering-standard.md` §4.
- **Persistence**: migrating to **Drift** (single encrypted database) from per-feature `sqflite`. Encryption via a composite device-bound key, not a static one — see `docs/blueprint/local-storage-architecture.md` §2. New database code should target `sqlite3mc` (`SQLite3MultipleCiphers`) via Drift's `user_defines` hook, per current Drift guidance, not the legacy `sqlcipher_flutter_libs` package — confirm this hasn't changed before assuming it (see the note in `docs/blueprint/local-storage-architecture.md` §2.3).
- **Non-sensitive local prefs**: Hive.
- **Secrets**: `flutter_secure_storage` (iOS Keychain / Android Keystore) — tokens, cached user, and the device encryption key only. Never anything else.
- **DI**: `get_it` (currently ad hoc per feature; formalize per `docs/blueprint/migration-plan.md` §3).
- **Config obfuscation**: `Envied` (not yet integrated — Sprint 1, T1.0).
- **CI/CD**: GitHub Actions + Fastlane, branches `main`/`develop`/`feature/*`/`release/*`/`hotfix/*`. See `docs/blueprint/migration-plan.md` §11.

---

## 4. Architecture rules (enforce these on every change)

- **Clean Architecture, inward dependencies only**: `presentation (BLoC) → domain (entities, usecases, repository interfaces) → data (repository impls, Drift DAOs, remote datasources)`. Domain code must never import Flutter, Drift, or `dio` types. See `docs/blueprint/system-architecture.md` §2, ADR-003.
- **Repository pattern**: all data access goes through a domain-defined repository interface; repository implementations return domain entities, never raw Drift rows or DTOs. See ADR-003.
- **DAO pattern**: all local reads/writes go through generated Drift DAOs in `core/database/drift/daos/`. No feature holds a private database handle. See ADR-004, `docs/blueprint/local-storage-architecture.md` §4.
- **Local tables that mirror backend state carry no foreign keys** (ADR-011). The backend enforces those relationships before sending the row; enforcing them again on-device turned normal conditions into data loss. Before adding any constraint, apply the table in `docs/blueprint/local-storage-architecture.md` §3.0.
- **One usecase per business action.** No usecase branches on a "mode" parameter to do several unrelated things.
- **Transactional writes**: any write to a syncable table must enqueue its sync-queue row in the *same* Drift transaction as the mutation. This is a hard correctness rule, not a style preference — see ADR-006, `docs/blueprint/sync-architecture.md` §2.
- **No feature imports another feature's `data/` layer.** Cross-feature flows go through domain interfaces or a shared orchestration layer.
- **Naming**: use `conflict_manager.dart` (not `conflict_resolver.dart`) and `dynamic_key_store.dart` (not `secure_strorage.dart`) — these are named, deliberate corrections of drift already found in the codebase. See `docs/skills/engineering-standard.md` §9.

Full detail: `docs/blueprint/system-architecture.md`, `docs/blueprint/local-storage-architecture.md`, `docs/blueprint/sync-architecture.md`, `docs/blueprint/offline-architecture.md`.

---

## 5. Security rules (non-negotiable)

- Never store tokens, passwords, or PII in `SharedPreferences`, Hive, or an unencrypted database. Secrets go only in `flutter_secure_storage`; business data goes only in the encrypted Drift database. See `docs/skills/security.md` §3.
- Never log passwords, tokens, API keys, customer info, phone numbers, emails, or revenue data. Allowed: endpoint, response code, error code, and stack traces in debug builds only. See `docs/skills/security.md` §10.
- Never hardcode secrets, API keys, or endpoints in source. Use Envied-obfuscated config (once integrated) and CI secrets — never commit `.env.*` files.
- Never implement custom cryptography. Use the composite key-derivation scheme already specified in `docs/blueprint/local-storage-architecture.md` §2 and well-established platform/library primitives only.
- Any debug-only shortcut (mock SAP client, geofence bypass, permissive fraud policy) must be tagged `// TODO(release-gate):` and must never ship in a release build — see `docs/skills/security.md` §11 release checklist.

Full detail: `docs/skills/security.md`.

---

## 6. Testing expectations

Do not consider a change finished without the test tiers that apply to it. Coverage gates (CI-enforced): domain ≥ 90%, data ≥ 80%, cryptography and sync-queue code 100% of branches. See `docs/skills/engineering-standard.md` §10 for the full matrix (unit, repository, DAO, integration, offline/chaos, conflict, security, widget, golden).

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
| **Day-to-day operational manual — checklists, conventions, worked code example** | **`docs/skills/ai-engineering-playbook.md`** |
| **Gate for any new feature / screen / UI upgrade — security, stability, performance, responsive, motion, visual language, UX, longevity** | **`docs/skills/feature-ui-standard.md`** |
| Cross-cutting engineering rules | `docs/skills/engineering-standard.md` |
| System overview, layers, folder structure, dependency graph | `docs/blueprint/system-architecture.md` |
| Offline behavior, guest-first auth, resumable workflow | `docs/blueprint/offline-architecture.md` |
| Drift schema, DAOs, encryption | `docs/blueprint/local-storage-architecture.md` |
| Sync queue, conflict resolution, DLQ | `docs/blueprint/sync-architecture.md` |
| Security standards, OWASP mapping, release checklist | `docs/skills/security.md` |
| Phased rollout, sprints, task backlog, risk register | `docs/blueprint/migration-plan.md` |
| Why key decisions were made (one per major decision) | `docs/adr/` (ADR-0001 … ADR-0011) |
| Codebase knowledge graph — setup, queries, blast-radius analysis | `docs/skills/graphify.md` |

Architecture Decision Records — index and status: [`docs/adr/README.md`](../docs/adr/README.md).
Full documentation index: [`docs/README.md`](../docs/README.md).

Architecture Decision Records (`docs/adr/`):

- **ADR-001** — single encrypted Drift database (vs. three plaintext `sqflite` DBs)
- **ADR-002** — offline-first: local database as source of truth
- **ADR-003** — repository pattern (domain interfaces / data implementations)
- **ADR-004** — generated Drift DAOs (vs. hand-written local datasources)
- **ADR-005** — connectivity service: real reachability, not interface-up
- **ADR-006** — unified sync engine, server-authoritative conflict resolution
- **ADR-007** — generalized, resumable `WorkflowSession`
- **ADR-008** — SQLCipher implementation path: `sqlcipher_flutter_libs` (on-disk format locked)
- **ADR-009** — customer filtering is flat; SAP master data is a cached lookup
- **ADR-010** — web persistence
- **ADR-011** — local mirror tables carry no foreign keys; the backend owns referential integrity

When code and these documents disagree, the documents describe the *target* — flag the discrepancy rather than silently treating the code as correct, per `docs/skills/engineering-standard.md` §11.

---

## 8. When you're unsure

- If a task would build a feature ahead of its infrastructure dependency (§1, `docs/blueprint/system-architecture.md` §4), stop and say so — don't build a temporary workaround that becomes permanent.
- If a task touches encryption, key management, or the sync queue, read `docs/blueprint/local-storage-architecture.md` §2 and `docs/blueprint/sync-architecture.md` in full first — these are the highest-consequence, hardest-to-safely-retrofit parts of the system.
- If you find a stub file (`core/sync/*`, `core/database/files/*`, `core/network/sap_client.dart`), treat it as **tracked and expected to be empty right now**, not evidence the feature is unneeded — check `docs/blueprint/migration-plan.md` for its planned sprint before assuming scope.