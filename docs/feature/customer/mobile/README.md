# Customers — Mobile API

Documentation for the customer endpoints consumed by the Flutter field sales app.

**Start with [mobile.md](mobile.md)** — the whole surface in one page, including the
response envelope, localisation, money and error codes. The pages below go deeper on
one operation each.

| Document | Covers |
|---|---|
| [mobile.md](mobile.md) | The whole surface: envelope, localisation, permissions, error codes, Dart model |
| [get-customer.md](get-customer.md) | `GET /mobile/customers` — the paged list and the full offline-sync contract |
| [get-customer-by-id.md](get-customer-by-id.md) | `GET /mobile/customers/{id}` — the 52-field record and its field groups |
| [create-customer.md](create-customer.md) | The three creation paths, the 46-field draft wizard, evidence photos, and delivery to SAP |
| [../registration.md](../registration.md) | **The dropdown catalogues** (`GET references`) plus the draft wizard, request by request |
| [edit-customer.md](edit-customer.md) | `PUT /mobile/customers/{id}` — replace semantics and the contacts rules |
| [search-customer.md](search-customer.md) | The `search` parameter, including Khmer text handling |
| [filter-customer.md](filter-customer.md) | Every filter, sort key and paging rule on the **list** endpoint |

## Reading order for a new integrator

1. **[mobile.md](mobile.md)** — envelope, localisation, error format. Nothing else
   makes sense first.
2. **[get-customer.md](get-customer.md)** — build the sync before any screen. The
   watermark rules are the ones that bite.
3. **[get-customer-by-id.md](get-customer-by-id.md)** — the detail screen.
4. **[search-customer.md](search-customer.md)** and
   **[filter-customer.md](filter-customer.md)** — the list screen's controls.
5. **[create-customer.md](create-customer.md)** — registration. Read the path
   comparison before choosing one. The **dropdown data the form binds to**
   is in [../registration.md](../registration.md) — `GET references`, called once when
   the form opens.
6. **[edit-customer.md](edit-customer.md)** — read the PUT-replaces warning before
   writing the edit screen.

Authentication is separate: see
[../../../authentication/api/mobile.md](../../../authentication/api/mobile.md).

## The three flows in one picture

```mermaid
flowchart TB
    subgraph SAP["SAP ERP"]
        S1["/api/Customer/GetCustByPaging"]
        S2["/api/Customer/CreateCust"]
        S3["/api/CustHelper/*"]
    end

    subgraph BE["ISI Platform"]
        J1["sap-customer-sync<br/>nightly 02:00 UTC"]
        J2["reference sync"]
        DB[(PostgreSQL)]
        API["/api/v1/mobile/customers"]
        PUSH["/api/v1/customers/sap/*<br/>customers.sync only"]
    end

    subgraph APP["Flutter app"]
        L["List + search"]
        D["Detail"]
        R["Registration wizard"]
        SQ[(SQLite)]
    end

    S1 -->|read| J1 --> DB
    S3 -->|read| J2 --> DB
    DB --> API
    API -->|delta sync| SQ --> L
    API --> D
    R -->|draft, submit| API
    DB --> PUSH -->|write| S2
    S2 -.->|customer number, next sync| DB

    style PUSH fill:#5a3a3a,stroke:#a06060,color:#fff
```

Read paths are nightly and unattended. The write path to SAP is deliberately **not**
reachable from the field app — it needs `customers.sync`, which representatives do not
hold. A rep's job ends when the record is safely on the server.

## Conventions in these documents

- Every example is verified against a running instance, not written from the contract.
- Counts quoted from data (`6,010 customers`, `5,956 Khmer names`) come from the
  current SAP extract and will drift.
- `status` is a stable code to branch on; `statusDisplay` is a localised label to
  render. Never the reverse.
- All timestamps are UTC ISO-8601.
