# Enterprise Architecture Review & Implementation Roadmap

> ISI Steel Sales Mobile — Offline-First Enterprise CRM (Flutter)
> Status: **Planning — no production code authorized yet**
> Reviewed branch: `demo/app01` · Reviewers role: Solution/Flutter/DB/Security/DevOps architecture
> Last updated: 2026-07-14

---

## 0. Locked Decisions

These were agreed before planning and gate all downstream work:

1. **Persistence direction:** Migrate to **Drift + SQLCipher** — a single encrypted database with generated DAOs and a unified migrator. Existing per-feature `sqflite` DBs will be ported.
2. **Deliverable:** This document lives in `docs/ARCHITECTURE_REVIEW.md` (not committed until explicitly requested).
3. **Sprint 1 starting point:** **Encryption + key management first** — SQLCipher, secure key storage, rotation, and migration of existing plaintext data, before any new feature work.

---

## 1. Executive Summary — Target vs. Actual

The architecture document is a **target**. The code on `demo/app01` is a **UI-complete demo (~80%)** whose infrastructure diverges from that target. Verified in code:

| Target | Actual in repo | Severity |
|---|---|---|
| Drift (SQLite) + DAOs | Raw `sqflite` + hand-written SQL; `core/database/drift/{tables,daos,migrations}` empty; no `drift` dep | High |
| SQLCipher AES-256 | **No encryption**; no sqlcipher dep; plaintext DBs | **Critical** |
| One encrypted DB | Multiple plaintext DBs: `catalog.db`, `customers.db`, `routes.db` | High |
| Background Sync Engine | `core/sync/*` are 0-byte stubs; sync is foreground per-feature `SyncCubit`; no background worker | High |
| SAP Integration | `core/network/sap_client.dart` empty; all SAP mocked | Expected (demo) |
| Sync Queue + DLQ + conflict | Real `sync_queue` table (order feature) with backoff fields; no DLQ, no conflict resolver, no background drain | Partial |
| flutter_secure_storage | Present (v9); used by auth | OK |
| Hive | Present; non-sensitive prefs | OK |
| Cert pinning / biometric / root detection | None (listed as "future") | Planned |

**Headline finding:** the design is sound as a target, but roughly 60% of the enterprise infrastructure layer is stubbed. The plan below closes that gap, security-first.

---

## 2. Layer-by-Layer Review

### Layer 1 — Persistence (→ Drift + SQLCipher)
- **Schema:** competent hand-written SQL, FTS4 catalog search; but split across 3 isolated DBs → no cross-feature joins or transactions.
- **Indexing:** present but ad-hoc; needs an index audit vs. real query plans.
- **Migrations:** each DB self-versions (`onUpgrade`); **no unified framework, no migration tests** — top maintenance risk.
- **DAO strategy:** hand-written `*LocalDataSource` classes; runtime-only mapping safety → Drift codegen fixes this.
- **Transactions:** per-DB only; logically-atomic operations can span DBs with no atomicity.
- **Encryption:** ❌ none — PII/revenue in plaintext SQLite. Violates `security_app.md`. **Highest priority.**
- **Scalability:** row counts fine; operational complexity of many DBs is the concern.
- **Caching:** local DB as source of truth with live streams — sound.

### Layer 2 — Hive
- Correctly scoped to non-sensitive prefs (`onboarding_complete`, filters). No TTL/versioning/lifecycle formality (fine at scale). Enforce by review: never store tokens/PII in Hive.

### Layer 3 — Secure Storage
- Tokens + cached user in `flutter_secure_storage` — good, enables offline-first boot.
- Refresh flow designed (401→refresh→retry); **verify interceptor still exists** (git shows `app_middleware.dart` deleted) and does single-flight refresh.
- ❌ No encryption-key rotation (needed with SQLCipher). ❌ No biometric (`local_auth`).

### Layer 4 — File Storage
- `core/database/files/file_strorage.dart` is a **stub**. Media captured but no organized store, lifecycle, cleanup, encryption, size caps, or backup. Needs a real attachment manager.

---

## 3. Workflow Engine Review

`ActiveWorkflow` (single-row resume pointer with `currentScreen` + JSON `navigationArguments`, DB as source of truth) is well designed for its scope.

Gaps for enterprise WorkflowSession:
- **Missing fields:** `sessionId`, `userId`, `deviceId`, `startedAt`, `expiresAt`, `version`, `state`.
- **Resume validation:** confirm referenced route/stop still exists and belongs to this user.
- **Recovery edge cases:** stale/deleted route, route now `completed`, schema drift on `navigationArguments` after upgrade.
- **Abandoned workflows:** no expiry → add TTL / end-of-day auto-close + prompt.
- **Multi-user:** scope by `userId`; clear on logout.
- **Navigation restoration:** guard against renamed/removed routes → fallback to dashboard.
- **Open question:** deprecate legacy `ActiveRouteScreen` vs. guided 4-step flow (see `my_visite.md` §10).

---

## 4. Sync Engine Review

Seed exists (order→SAP `sync_queue` with `attempt_count`/`next_retry_at`/`last_error`, FIFO, backoff query). Target per capability:

| Capability | Current | Target |
|---|---|---|
| Queue lifecycle | order-only | Unified entity-typed queue: queued→inFlight→succeeded/failed→dead |
| Retry | field present | Capped retries → DLQ |
| Priority | FIFO only | `priority` (check-in > order > telemetry) |
| Batch | one-by-one push | Batched by entity + idempotency keys |
| Backoff | field only | `base·2^attempt + jitter`, capped |
| Conflict | ❌ empty | Per-entity: LWW catalog, server-wins pricing/credit, client-merge captures, manual order edits |
| Duplicate detect | replace-by-id | Client UUID + server idempotency key |
| Monitoring | `countsByStatus()` | Sync Center screen |
| Offline indicators | connectivity cubit | Global banner + per-item state |
| Connectivity | plugin present, service empty | Real reachability (not just interface up) |
| Background workers | ❌ | `workmanager` / BGTaskScheduler drain |
| Cleanup | delete-on-success | TTL purge + DLQ retention |
| Dead-letter queue | ❌ | `dead` status + review UI + manual retry |
| Recovery | ❌ | On boot reset inFlight→queued, replay by priority |

---

## 5. Database Table Catalog (target unified encrypted DB)

- **Master:** users✅, customers✅, products✅, categories✅, territories, warehouses, brands
- **Transactional:** carts✅, cart_items✅, quotations✅, quotation_lines✅, sales_orders✅, routes✅, route_stops✅, visits/check_in/out✅, stock_counts✅, returns✅, collections✅, leads, revenue
- **Reference:** off_visit_reasons, fraud_policies, product_grades/sizes, config_lookups
- **Security:** device_registrations, auth_sessions, key_metadata
- **Workflow:** workflow_state✅ (+ new fields), workflow_history
- **Sync:** sync_queue✅ (unify), sync_dead_letter, sync_cursors
- **Audit:** audit_log
- **Configuration:** app_config, feature_flags, remote_thresholds
- **Logging:** event_log, error_log
- **Notification:** notifications, notification_state
- **Attachment:** attachments (id, owner_type, owner_id, path, sha256, bytes, encrypted, upload_state, created_at)

**Standard syncable-table columns (currently missing):** `id (UUID)`, `updated_at`, `deleted`, `sync_state`, `server_revision`, `dirty`.

Per-table detail (Purpose/PK/FK/Indexes/Offline/Sync) produced module-by-module at implementation time.

---

## 6. Security Review

| Control | State | Action |
|---|---|---|
| SQLCipher | ❌ | **Critical** — Sprint 1 |
| Secure storage | ✅ | Add DB-key + rotation |
| JWT / refresh | ✅ designed | Verify single-flight refresh interceptor |
| SAP auth | ❌ mocked | Service-account + token exchange |
| API keys | env-based ✅ | Keep out of VCS |
| Device registration | ❌ | Add for revocation |
| Cert pinning | ❌ | Dio SPKI pin (Phase 8) |
| Encryption keys / rotation | ❌ | With SQLCipher + key_metadata |
| Biometric | ❌ | local_auth on resume |
| Data leakage / local storage / file encryption | ⚠️ plaintext | Fixed by encryption layers |

The policy in `security_app.md` is strong; the gap is that code hasn't implemented its own policy yet.

---

## 7. Clean Architecture Review

- Layer discipline is **good** (data→domain→presentation, one usecase/action, repo pattern, per-feature DI). No violations found.
- **Missing/weak:** application/orchestration layer for cross-feature flows; **hollow Core infrastructure** (sync/security/files stubs); unified remote/SAP gateway; formalized mappers (Drift will help).

---

## 8. Feature Dependency Map

```
Core Infra (DB+Encryption+SecureStorage+Network+Sync+Session)
  └─ Authentication (✅) → Session/AuthGuard
       └─ Localization + Shell + Splash + AppCoach (✅)
            └─ Org/User/Territory/Warehouse (partial)
                 ├─ Customer (✅)
                 ├─ Catalog/Product (✅)
                 ├─ Lead (partial) → Visit/Route (✅)
                 └─ Order/Quotation/SalesOrder (✅ mocked)
                      └─ Sync Engine (⚠️) → SAP (❌) → Revenue/Reporting → Dashboard → Notification
```
**Rule:** no module to production before its Core Infra dependency exists.

---

## 9. Implementation Roadmap (Phases)

- **P0 Stabilize & Decide** — ADRs, resolve legacy-vs-guided flow, migration approach. Low.
- **P1 Secure Data Foundation** — Drift+SQLCipher, migrator, key mgmt/rotation, secure-storage wrapper, file encryption. **High.** DoD: all data encrypted at rest, migration proven on upgrade.
- **P2 Core Entities** — port features to unified DAOs. High. DoD: parity, no plaintext DB left.
- **P3 Workflow Hardening** — session fields, expiry, multi-user, resume validation. Medium.
- **P4 Sync Engine** — unified queue, backoff, priority, conflict, DLQ, background, connectivity. **High.**
- **P5 Media/Attachments** — encrypted store, lifecycle, upload+purge, caps. Medium.
- **P6 Dashboard/Reporting/Revenue** — on real synced data. Medium.
- **P7 SAP Integration** — replace mocks + auth. **High** (external).
- **P8 Security Hardening** — cert pinning, biometric, root/jailbreak, obfuscation. Medium.
- **P9 Optimization + Testing + CI/CD**. Medium.
- **P10 Production Release** — store, monitoring, crash reporting. Medium.

---

## 10. Sprint Plan

| Sprint | Theme | Contents |
|---|---|---|
| 0 | Architecture / CI-CD / Setup | ADRs, Drift decision (locked), GitHub Actions |
| 1 | **Security / DB / Encryption** | P1 (SQLCipher-first) |
| 2 | Core Entities | P2 |
| 3 | Workflow | P3 |
| 4 | Sync Engine | P4 |
| 5 | Media | P5 |
| 6 | Dashboard | P6 |
| 7 | SAP Integration | P7 |
| 8 | Optimization | Perf + P8 |
| 9 | Testing | Coverage/integration/security |
| 10 | Production Release | Store/monitoring |

---

## 11. Sprint 1 Task Backlog (Encryption-first)

- **T1.1 Drift + SQLCipher single DB** — P0, 8 pts. AC: DB opens encrypted; wrong key fails; key in secure storage.
- **T1.2 Unified migrator + schema-version registry** — P0, 5 pts. AC: migrations run once, idempotent, tested on upgrade.
- **T1.3 Migrate plaintext DBs → encrypted DB** — P0, 8 pts. AC: one-time import of catalog/customers/routes; old files purged; no data loss.
- **T1.4 Encrypted file/attachment store** — P0, 5 pts. AC: photos encrypted at rest; orphan cleanup.
- **T1.5 Key rotation flow** — P1, 5 pts. AC: re-key without data loss; `key_metadata` versioned.
- **T1.6 Secure-storage wrapper (`core/database/secure`)** — P1, 3 pts. AC: single API for tokens + DB key; no direct plugin calls in features.

Subsequent phases' backlogs are produced when reached, to avoid stale planning.

---

## 12. Risk Register

| Risk | Type | Sev | Likelihood | Mitigation |
|---|---|---|---|---|
| Plaintext DB holds PII/revenue | Security | Critical | High | SQLCipher Sprint 1 (blocking) |
| Fragmented multi-DB, no atomic txns | Technical | High | High | Single Drift DB |
| Uncoordinated migrations corrupt devices | Migration | High | Medium | Unified migrator + tests before schema change |
| Sync conflict → loss/dup | Sync | High | Medium | Per-entity policy + idempotency + DLQ |
| SAP contract unknown | Business | High | High | Contract-first with SAP team; swappable mock adapter |
| No background sync → lost captures if killed | Offline | High | Medium | workmanager + crash-recovery replay |
| Empty core stubs seen as "done" | Maintenance | Medium | High | This review + explicit infra backlog |
| Dev shims shipped (`kDebugForceInsideGeofence`, permissive FraudPolicy) | Security/Business | High | Medium | Release-gate checklist + CI grep |
| Unbounded encrypted media growth | Performance | Medium | Medium | Size caps + upload-then-purge |
| No cert pinning/biometric/root detection | Security | Medium | Medium | Phase 8 |

---

## 13. Quality Checklist

- **Architecture:** single encrypted DB; Core infra implemented; no layer violations; legacy visit flow resolved.
- **Security:** SQLCipher on; keys in secure storage + rotation; cert pinning; biometric; no VCS secrets; debug flags stripped; media encrypted.
- **Database:** UUID + `updated_at`/`deleted`/`sync_state` on syncable tables; indexes audited; migrations tested; soft-deletes.
- **Performance:** paged, index-backed queries; bounded media; cold-start budget.
- **Offline:** every write durable+queued; crash-recovery replay; per-entity conflict policy; offline banner.
- **Testing:** unit/repo/migration/widget/integration/offline-chaos/security tests.
- **Accessibility:** localized (en/kh); semantics labels; contrast (light/dark); scalable text.
- **Logging:** no PII/tokens; structured offline error log; audit_log for sensitive actions.
- **Monitoring:** crash reporting; sync-queue dashboard; DLQ alerts.
- **Deployment:** CI gates; obfuscation; signing; store checklist.

---

## 14. Coding Rule (in force)

No production code until a module's plan and dependencies are validated. Implement **module-by-module**, preserving Clean Architecture + SOLID. Next action after approval: **Sprint 1 / T1.1 — Drift + SQLCipher single DB**.
