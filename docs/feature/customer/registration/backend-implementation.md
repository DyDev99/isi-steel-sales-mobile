# Customer Mobile Registration — Implementation

---

## Files added

### Domain — `src/ISI.Domain/Modules/Customers/`

| File | Contents |
|---|---|
| `CustomerReference.cs` | The reference row + `CustomerReferenceKind` (10 members) |
| `CustomerDraft.cs` | The draft aggregate, `CustomerDraftStatus`, `CustomerDraftFields` (46) |

### Application — `src/ISI.Application/Features/Customers/`

| File | Contents |
|---|---|
| `Reference/SyncCustomerReferencesFromSapCommand.cs` | The sync + its scheduled wrapper |
| `Reference/GetCustomerReferencesQuery.cs` | DB-first read, search, bulk exclusion |
| `Registration/CustomerDraftCommands.cs` | Start, update, submit, get, list, discard |
| `Registration/CustomerDraftFieldMapping.cs` | Wire ↔ domain, generated so they cannot drift |

`Abstractions/Infrastructure/SapCustomerHelperDto.cs` — the ten verified catalogue shapes.

### Contracts / Persistence / Infrastructure

`CustomerReferenceContracts.cs`, `CustomerDraftContracts.cs`,
`CustomerReferenceConfiguration.cs` (both tables), `SapCustomerDefaultsOptions.cs`,
`CustomerDraftDefaults.cs`, migration `20260826082643_AddCustomerReferencesAndDrafts`.

### Tests

`tests/.../Features/CustomerRegistration/CustomerDraftTests.cs` — 15 tests.

---

## Files modified

| File | Change |
|---|---|
| `MobileCustomersController.cs` | 7 registration actions |
| `CustomerSapController.cs` | `POST sap/sync-references` |
| `ISapCustomerService.cs` / `SapCustomerService.cs` | `GetCustomerReferencesAsync` |
| `CustomerErrors.cs` | 7 error members |
| `CustomerDtos.cs` / `CustomerMobileMapping.cs` | **`sapStatus` on the mobile summary and detail** |
| `docs/feature/customer/api-design-notes.md` | Registration endpoints, new section, `sapStatus` change |
| `IApplicationDbContext.cs` / `ApplicationDbContext.cs` | Two new sets |
| `BackgroundJobs/DependencyInjection.cs` | Daily `sap-customer-reference-sync` at 03:00 UTC |
| `Infrastructure/DependencyInjection.cs` | Defaults options + adapter |
| `LocalizationService.cs` | 6 message keys, English + Khmer |

No new project, no new package, no `Dockerfile` change.

---

## Database

```
customer_references
  id, kind, code, name, synchronised_at, + audit/soft-delete/version
  ix_customer_references_key  UNIQUE (kind, code)

customer_drafts
  id, owner_user_id, status, submitted_customer_id, submitted_at,
  46 SAP business-partner columns, + audit/soft-delete/version
  ix_customer_drafts_owner_status        (owner_user_id, status)
  ix_customer_drafts_submitted_customer  (submitted_customer_id) WHERE NOT NULL
```

`customers` was not touched. Seeded on first sync: **5,918 reference rows**.

---

## Configuration

```
SAP__CustomerDefaults__PartnerCategory=2      # organisation
SAP__CustomerDefaults__Country=KH
SAP__CustomerDefaults__Language=E
SAP__CustomerDefaults__Currency=USD
SAP__CustomerDefaults__TaxCountry=KH
SAP__CustomerDefaults__AccountGroup=          # set per environment
SAP__CustomerDefaults__BpRole=
SAP__CustomerDefaults__SalesOrg=
# …and the rest of the sales area, all optional
```

Every value optional — a blank one leaves that field empty on the form. Nothing is
validated on start, so an environment that has not configured these still works.

---

## Verification

### Build and tests

```
dotnet build ISI.Platform.slnx  → 0 warnings, 0 errors (warnings are errors here)
dotnet test  ISI.Platform.slnx  → 192 passed, 0 failed   (15 new)
```

One of the new tests caught a real bug before it shipped: the patch used
`?? current`, which cannot express "set this back to nothing", so clearing a field
stored `""` instead of null — and SAP would have received it. Fixed with an explicit
three-way patch helper.

### Live, against the real SAP connection

| Check | Result |
|---|---|
| Reference sync | **5,918 rows across all 10 catalogues in 3.8 s**, 0 failed |
| Form-open payload | 9 catalogues, 109 rows, **4.5 KB in 98 ms** |
| Sales-employee search | `search=leng` → 48 matches, 2.3 KB, 39 ms |
| Draft open | 8 of 46 fields prefilled, 137 ms |
| Three sequential patches | 105 / 14 / 8 ms; defaults preserved, `bl30` → `BL30`, Khmer intact |
| Submit | `BP-202608-00003`, `sapStatus: Submitted`, 217 ms |
| Mobile list | Shows `status=Draft sapStatus=Submitted` |
| Mobile detail | Carries `sapStatus` too, so tapping through does not lose it |
| Re-submit | 409 `Customer.DraftAlreadySubmitted` |
| Update after submit | 409 `Customer.DraftNotEditable` |
| Submit empty draft | 400 with all four missing fields at once |
| Another rep's draft | 404 |
| OpenAPI | All 7 in `v1.json` and `mobile.json`; admin sync in `admin.json` |

---

## Known limitations

1. **`DayLimit` from `GetPaymentTerm` is read but not stored.** The platform already
   models credit terms in days on the customer; mapping it onto `CreditTermDays` is the
   obvious next step and was out of scope here.
2. **No dependency chain between dropdowns.** The API exposes none — each endpoint
   filters only by its own id. See [`docs/feature/customer/registration/sap-helpers.md`](sap-helpers.md).
3. **The middleware is intermittently slow.** Under sync load three catalogues timed
   out at 280–400 s. Handled (partial success, additive import) but worth watching.
4. **Drafts are never expired.** An abandoned form stays in `customer_drafts`
   indefinitely. A cleanup job for drafts untouched for, say, 90 days is the natural
   follow-up.
5. **The commercial status stays `Draft` after submission.** That is deliberate —
   `Draft`/`PendingApproval` is the credit-approval workflow and is a different question
   from SAP registration. `sapStatus` is what moves, and the mobile list now shows it.
No deployment permission step is needed. Unlike `materials.read`, which was added in
this release, `customers.create` and `customers.read` are pre-existing permissions and
are already granted — verified on the dev database:

| Permission | Roles holding it |
|---|---|
| `customers.create` | Administrator, Sales Manager, Sales Representative, Supervisor |
| `customers.read` | + Executive, Finance, Warehouse |
| `customers.sync` | Administrator, Finance, Sales Manager |

So a Sales Representative can use the whole registration flow the moment it deploys.
