# Quotations

**Purpose:** a priced offer to one customer, authored on the handset, approved in the
portal, and totalled by one server-side calculator.
**Scope:** the quotation aggregate, the calculator, the mobile authoring surface and
the admin approval surface. **No SAP document is created**, there are no promotions,
no orders and no PDF — see [Not built yet](#not-built-yet).
**Status:** Active (phase Q1 + approval) · **Last updated:** 2026-09-11

**Implementation:** `src/ISI.Domain/Modules/Quotations/` ·
`src/ISI.Application/Features/Quotations/` · `src/ISI.Api/Controllers/Quotations/` ·
`src/ISI.Persistence/Configurations/QuotationConfigurations.cs`

---

## Documents

| Document | Contains | State |
|---|---|---|
| [overview.md](overview.md) | What the feature is and the guarantees it keeps | ✅ |
| [business-rules.md](business-rules.md) | The rules the domain refuses to break, and where each lives | ✅ |
| [data-model.md](data-model.md) | Tables, columns, indexes and why each exists | ✅ |
| [testing.md](testing.md) | What is covered, and what could not be covered here | ⚠️ |
| [api/mobile.md](api/mobile.md) | The Flutter authoring surface | ✅ |
| [api/admin.md](api/admin.md) | The portal approval queue | ✅ |
| [quotation-orders-plan.md](quotation-orders-plan.md) | The full programme this is phase one of | 📋 Proposal |
| [../prom-discount/promotions-discounts-plan.md](../prom-discount/promotions-discounts-plan.md) | Promotions, agreements and rebates | 📋 Proposal |

---

## In one paragraph

A representative opens a quotation against a customer they own, adds materials — each
priced by the server through the existing `IPricingService`, never by the client — sets
a manual discount as a *percentage intent*, and submits. Every amount on every screen
comes from one `IQuotationCalculator`, so the preview, the stored document, the admin
queue and the list row cannot disagree. Submission re-reads prices from SAP and refuses
a document whose prices moved. An approver in the portal approves, returns or rejects
it, and cannot act on a quotation they raised themselves.

---

## The one thing to know before changing this

**`Status` is derived and assigned nowhere.** The aggregate holds four independent
dimensions — platform approval, SAP quotation, SAP sales order, customer answer —
plus an explicit closure for cancellation and expiry, and recomputes `Status` after
every transition in one `RecomputeStatus()`. "Admin approved, SAP refused" is not
"admin rejected", and one column cannot say both. If you find yourself wanting to set
`Status`, add a transition method instead.

Two more, both learned from Pricing on live data:

- **A price is four fields** — `amount` + `currency` + `pricingUnit` + `conditionUnit`.
  A line amount is `quantity × amount ÷ pricingUnit`. 3,867 of 3,869 live records are
  `US3`, not `USD`, and SAP prices "per 100 KG" routinely.
- **"No price" and "prices unavailable" are different answers.** A material SAP holds
  no price for is `422 Quotation.MaterialNotPriced`; a SAP outage is
  `502 Quotation.PriceUnavailable`. They are never both rendered as an empty line or a
  zero.

---

## Not built yet

Deliberate omissions, each blocked on something outside the code:

| Missing | Blocked on |
|---|---|
| SAP quotation creation, readback, reconciliation | The `CreateQuot` request contract is unverified, and there is no non-production SAP connection to write test documents into |
| Sales orders and the customer accept/decline path | No sales-order endpoint exists in the middleware |
| Promotions, depot agreements, rebates, campaigns | A separate feature; see the promotions plan. A quotation line already carries a `Agreement` discount kind for it to write into |
| Price requests (a manual price on an unpriced line) | An open business decision about who may set a price |
| Pickup discount | Nobody has confirmed the rate, its scope, or whether SAP holds it |
| Tax | SAP determines it from tax classification. `totals.tax` is always `null` and is present so no client invents a field for it |
| PDF / customer-facing document | Should be generated from SAP values, which do not exist yet |

The aggregate's status enum, the SAP status dimensions and the discount kinds are all
declared for these, so adding them widens behaviour rather than reshaping the model.
