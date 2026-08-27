# Customer

> **Purpose:** the rep's view of who they sell to — browsing and filtering
> customers, opening a customer record, and registering a brand-new Business
> Partner into SAP from the phone.
> **Code:** `lib/features/customers/`
> **Verified:** 2026-08-27, branch `web` @ `142de9b`.

---

## What this feature is

Two jobs that share one data layer:

1. **Read** — the rep's customer list, filtered locally, and the detail record
   behind each one. Works fully offline from the encrypted local mirror.
2. **Create** — a guided, resumable multi-step form that produces an SAP
   Business Partner (`ZFLCU1`: Create Organization → Extend Customer → FI
   Customer). Drafts survive being interrupted.

Used by: **Sales Representatives**. Guests can browse; creating requires a
session (`AuthGuard`).

---

## Documents

| Document | What it covers |
|---|---|
| [api.md](api.md) | **Authoritative endpoint reference** for the whole `/api/v1/mobile/customers` surface — envelope, localisation, filtering, paging, offline sync, contacts, money, error codes. |
| [api-design-notes.md](api-design-notes.md) | Why the mobile controller is separate from the admin one, the migration plan, the breaking-change report, and v2 recommendations. Endpoint shapes come from [api.md](api.md). |
| [ui-ux.md](ui-ux.md) | The step-and-section design for the create form, mapped to the SAP field list. |
| [registration/](registration/) | The SAP BP registration sub-package: [overview](registration/README.md), [api](registration/api.md), [backend implementation](registration/backend-implementation.md), [SAP helper catalogues](registration/sap-helpers.md). |
| [reference/](reference/) | Source specifications — the SAP BP field spreadsheet and the SAP API technical document. |

---

## Screens

| Screen | File |
|---|---|
| Customer list | `presentation/screens/customers_screen.dart` |
| Customer detail | `presentation/screens/customer_detail_screen.dart` |
| Create customer | `presentation/screens/customer_create_screen.dart` + `widgets/add_customer_bottom_sheet.dart` |

Reached via `MainShell` tab 1. `CustomerDetailScreen` is also a resume target
for an interrupted workflow — see
[../../blueprint/navigation-architecture.md](../../blueprint/navigation-architecture.md#resumable-workflows-my_visits).

---

## State

| Bloc / Cubit | Responsibility |
|---|---|
| `CustomersBloc` | List loading, search, pagination |
| `CustomerFilterCubit` | Flat, locally-applicable filter criteria — see [../../adr/ADR-0009-customer-master-data-filter.md](../../adr/ADR-0009-customer-master-data-filter.md) |
| `CustomerDetailCubit` | One customer record |
| `AddCustomerBloc` | The multi-step BP creation form, its per-step validation and draft persistence |
| `CustomerSyncCubit` | Watermarked incremental pull. The reference adopter of the `ProtectedFeature` mixin. |

---

## Data

| Domain repository | Implementation reads/writes |
|---|---|
| `CustomerRepository` | Local Drift mirror via `CustomerDao`, remote via `ApiCustomerRemoteDataSource` |
| `CustomerSyncRepository` | Watermark-based delta pull, `customer_sync_page.dart` |
| `BusinessPartnerRepository` | Draft lifecycle and SAP submission |
| `MasterDataRepository` | Cached SAP lookup catalogues — a lookup, **never** a cascade (ADR-0009) |

Local tables live in `core/database/drift/tables/customers_table.dart` and
`customer_related_tables.dart`, accessed through `customer_dao.dart`.
**They carry no foreign keys** — the backend owns referential integrity, per
[../../adr/ADR-0011-local-mirror-no-foreign-keys.md](../../adr/ADR-0011-local-mirror-no-foreign-keys.md).

Master data is stored **bilingually** so switching language never degrades
customer content.

---

## Offline behaviour

| Action | Offline |
|---|---|
| Browse and filter the list | ✅ Fully — reads the local mirror |
| Open a customer detail | ✅ Fully |
| Save a BP draft | ✅ Locally, and it survives a process kill |
| Load SAP dropdown catalogues | ✅ From cache if previously fetched; otherwise the step reports unavailable |
| Submit a BP to SAP | ❌ Requires connectivity — this is a live SAP round trip |
| Incremental sync | Resumes on reconnect from the stored watermark |

Filtering is deliberately flat and locally applicable: a ten-level cascading
filter was requested and rejected because each level needed a network call, so
the filter would have stopped working exactly where reps use it (ADR-0009).

---

## Tests

`test/features/customers/` — 7 files: API mapper, draft resume, Drift local
data source, filter cubit, form address, sync watermark, master-data repository.
Schema and DAO coverage is in `test/core/database/drift/customer_dao_test.dart`,
`customer_sap_schema_migration_test.dart`, and
`sap_customer_id_nullable_test.dart`.

---

## Known gaps

- **No requirement documents.** Business rules are embedded in `api.md` and the
  form validators rather than stated as testable acceptance criteria — see
  [../../requirement/README.md](../../requirement/README.md).
- **Two overlapping API documents.** [api.md](api.md) and
  [api-design-notes.md](api-design-notes.md) both describe the endpoint set.
  `api.md` is authoritative; the design notes retain the rationale, migration
  plan, and breaking-change history that would otherwise be lost. Fold them
  fully once v2 lands.
- **`.docx` / `.xlsx` sources** in [reference/](reference/) are not diffable and
  cannot be reviewed in a PR. Their content is transcribed into
  [ui-ux.md](ui-ux.md) and [registration/sap-helpers.md](registration/sap-helpers.md);
  treat those as the working reference.

---

## Related

- [../../blueprint/local-storage-architecture.md](../../blueprint/local-storage-architecture.md) — the schema these tables live in
- [../../blueprint/offline-architecture.md](../../blueprint/offline-architecture.md) — the offline posture above
- [../../adr/ADR-0009-customer-master-data-filter.md](../../adr/ADR-0009-customer-master-data-filter.md) — why filtering is flat
- [../../adr/ADR-0011-local-mirror-no-foreign-keys.md](../../adr/ADR-0011-local-mirror-no-foreign-keys.md) — why mirror tables have no FKs
- [../../skills/api-integration.md](../../skills/api-integration.md) — the client-side conventions `api.md` is consumed through
