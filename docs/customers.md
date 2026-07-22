# Customers Feature — Blueprint

> ISI Steel Sales Mobile · Offline-first customer directory backed by the SAP
> customer master. Companion to `docs/AI_ENGINEERING_PLAYBOOK.md` and
> `SapAPI_Technical_Document_v1_BP.docx` (§5, Customer/BP API).
> Last updated: 2026-07-22 (SAP integration + real-data UI pass).

## 1. Data flow

```
SAP GetPaging/Read ──► CustomerSapRemoteDataSourceImpl (SapApiService)
                              │  DTO: SapBusinessPartner (case-tolerant keys)
                              ▼
                       SapCustomerSyncSource  ──►  CustomerSyncRepositoryImpl
                              │                        │ upsert, watermark
                              ▼                        ▼
                       CustomerModel  ──────────►  Drift `customers` (encrypted)
                                                       │
                              UI ◄── Bloc ◄── UseCase ◄┘  (reads local ONLY)
```

- **Auth:** the bearer token is attached by `AuthInterceptor` from `TokenManager`.
  Nothing in this feature reads secure storage, sees a JWT, or imports `dio`.
- **Offline:** every screen reads Drift; the network is touched only by
  sync/refresh. `runDeltaSync` is a full re-page — the façade has **no
  changed-since endpoint** — and deletions are deliberately not inferred
  (a truncated pull is indistinguishable from a shorter list).
- **Identity:** `id` = `sapCustomerId` = SAP customer number. Client never
  generates customer ids; a customer exists only because SAP says so.

## 2. Field truth table — the **live** GetPaging contract

> Source of truth: a captured `GetPaging/Live110` response (2026-07-22),
> 6,266 rows / 126 pages. The wire is **PascalCase** (`Rows`, `NameEn`,
> `SALESBLOCK`) — the technical document's camelCase is wrong on the live
> server, and the first integration attempt parsed **zero customers** because
> the envelope reader trusted the document. The DTO reads both spellings; the
> regression test pins the live one.

| Entity field | Live SAP source | Notes |
|---|---|---|
| id / sapCustomerId | `Customer` | mandatory; keyless rows dropped |
| customerCode | `SearchTerm2` → `Customer` | `IC00011731` — the code staff recognise |
| shopName | `NameEn` → `NameKh` → `CoName` | customer number as last resort |
| enName / khName | `NameEn` / **`NameKh`** | *not* the document's `name3` |
| phone | `MobilePhone` → `Telephone` | blank on most walk-in rows |
| address | `Street, City, Country` joined | mostly blank on walk-ins |
| province | `City` → `SearchTerm1` | `SearchTerm1` = uppercase branch name |
| **territory** | **`SalesOrgName`** | "Phnom Penh (ISI)" — this app's territory concept; lights up the territory picker |
| **latitude / longitude** | **`Latitude`/`Longitude`** | **real fields**, string-encoded; `""` → null, never 0.0 |
| **status** | **`OrderBlock`/`SALESBLOCK`/`BLOCKFLAG`** | any non-empty → `creditHold`; all empty → `active` (an explicit ERP statement, not a default) |
| creditLimit | `CreditLimit` | numeric on the wire |
| currency | **no field** | constant `USD` — documented ledger currency |
| salesOrg / division / distributionChannel | codes | kept as codes: they key filters/indexes |
| customerGroup, priceGroup, paymentTerms | `*Name` → code | display names stored ("45 days due net", not `T045`) |
| assignedRepId/Name | `SalesEmployee(Name)` | |
| createdAt | `CreationDate` (`yyyyMMdd`) | `00000000` → null |
| **ownerName, district, email, whatsapp** | **not in payload** | `CoName` is a channel tag, not an owner |
| **lifetimeValue, lastOrder/VisitDate, productsPurchased, openOpportunityCount** | **not in payload** | `—` / "No orders yet" — never `$0` |
| creditBalance, taxNumber, totalOrders | not in GetPaging | stay defaulted |

**Duplicate rows:** SAP emits one row **per sales area** — the same `Customer`
appears up to 8× per capture. `TotalCount` counts rows, not customers; the
keyed upsert makes the last sales-area row win. A customer×sales-area child
table is the eventual fix (§4).

**Rule:** null means "SAP has not told us". Never substitute defaults the ERP
didn't state — `latitude ?? 0` maps to the Gulf of Guinea.

## 3. Schema (v9)

`customers` (encrypted Drift, ADR-001): mock-era columns relaxed to nullable
(v9 predecessor), plus SAP commercial columns `sales_org`, `division`,
`distribution_channel`, `customer_group`, `price_group`, `payment_terms`,
`en_name`, `kh_name`, `credit_balance`, `currency`, `tax_number`,
`total_orders`, `created_at`, `sync_state`; indexes on sales_org/division.
Migration fixtures in `test/core/database/drift/*_schema_migration_test.dart`
rebuild older versions by dropping exactly these columns — **adding a customers
column means updating both fixtures' drop lists** (the "duplicate column"
failure mode).

## 4. Known gaps / debt

- `MockMasterDataRemoteDataSource` (CustHelper dropdowns) is still the live
  registration — real `/api/CustHelper/*` datasource not yet built.
- Create/Update BP endpoints exist server-side but the push path is blocked on
  `core/sync/*` (Phase 4, ADR-006).
- Read-response field names are only narratively documented; the DTO reads
  candidate keys case-tolerantly and exposes `parsedFieldCount` for smoke tests.
- One drift-row per customer, but SAP sends one row per **sales area** —
  last-wins today; a customer×sales-area child table is the proper model.
- Coordinates arrive only for depots/key accounts; walk-in and most retail rows
  have none, so geofenced visits still lack coordinates for much of the
  directory (0,0 fail-closed fallback in `my_visits` stands).
- `SapEndpoints`/`SapCustomerSyncSource` page with `pageSize=50`; the live
  directory is 126 pages, so a full pull is 126 sequential calls (~6.3k rows).
