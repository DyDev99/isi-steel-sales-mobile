# Quotations — Admin API

**Base:** `/api/v1/quotations` · **Envelope:** `ApiResponse<T>` ·
**Errors:** RFC 9457 problem documents with a stable `errorCode`
**OpenAPI:** tagged `Admin.Quotations` and `HeadSales.Quotations`, in the `admin`,
`head-sales` and `v1` documents
**Status:** Active · **Last updated:** 2026-09-11

---

## Endpoints

| Method | Route | Permission | Purpose |
|---|---|---|---|
| `GET` | `/` | `quotations.read` | List, paged. The approval queue is `?status=PendingApproval` |
| `GET` | `/{id}` | `quotations.read` | One document in full |
| `GET` | `/{id}/history` | `quotations.read` | The approval trail |
| `POST` | `/{id}/approve` | `quotations.approve` | Accept |
| `POST` | `/{id}/return` | `quotations.approve` | Send back for rework, with a reason |
| `POST` | `/{id}/reject` | `quotations.approve` | Refuse outright, with a reason |

The three decisions are **verbs, not a status assignment**. A single "set status"
endpoint would let a caller move a quotation anywhere the enum allows, which is exactly
what the state machine exists to prevent.

---

## `GET /` — the queue

| Parameter | Notes |
|---|---|
| `status` | A concrete status or a tab group. `PendingApproval` is the queue |
| `customerId` | Restrict to one customer |
| `ownerUserId` | Restrict to one representative |
| `page` · `pageSize` | One-based; default 20, clamped to 100 |

**Without `quotations.readall` this returns only the caller's own documents**, and
`ownerUserId` cannot widen that. A filter that could widen a scope is an authorisation
hole with a query string.

Each row carries `requiredApprovalLevel`, computed from the document's largest manual
discount at submit and stored — so the queue can be filtered to "needs my level" and
the audit can say *why* it was routed there, even after the authority ladder changes.

---

## Deciding

```http
POST /api/v1/quotations/{id}/approve
POST /api/v1/quotations/{id}/return   { "reason": "Discount above policy for this depot" }
POST /api/v1/quotations/{id}/reject   { "reason": "Not commercially viable" }
```

All three return the recalculated document.

| Failure | Meaning |
|---|---|
| `409 Quotation.InvalidTransition` | The document is not `PendingApproval`. A second approve lands here |
| `403 Quotation.ApproverIsAuthor` | The decider raised this quotation |
| `422 Quotation.ReasonRequired` | A return or rejection with no reason |
| `404 Quotation.NotFound` | No such document, **or** outside the caller's scope |

**Nobody decides on their own quotation.** The rule lives on the aggregate, so it holds
however the command was dispatched — portal, background job or test. Without it, one
person holding both `quotations.create` and `quotations.approve` would be the entire
workflow.

**Return versus reject.** A return reopens the document as a new revision for the
representative to fix and resubmit; the reason is shown to them. A rejection is
terminal — the representative raises a new quotation. Recording both as "rejected"
would leave nobody able to explain why a refused document is being worked on again.

---

## What approval does **not** do

**It does not create a SAP quotation.** That path is a background job with an outbox,
lookup-before-create and an honest "unknown" outcome for a request that timed out after
the payload left the wire — and it does not exist yet, because the `CreateQuot` request
contract is unverified and there is no non-production SAP connection to write test
documents into.

An approved quotation rests at `Approved`, with `sapQuotationStatus: "NotSent"` and
`sapQuotationNumber: null`. That is exactly what it is, and the API says so rather than
implying a document exists in the ERP.

---

## The trail

`GET /{id}/history` returns the append-only `approval_records` entries for the
document — action, stage, the status either side, who acted, the reason and when.
Scoped through the same load as every other read, so the trail of a document the caller
may not see is not reachable by asking for its history instead of for the document.

The header also carries a summary of the last decision (`decidedBy`, `decidedAt`,
`decisionReason`), which is what the detail screen shows without a second call.
