# My Visits — Backend API Specification

> **Status:** proposal for the backend team.
> **Audience:** engineers implementing the route/visit endpoints in the ISI API.
> **Source of truth:** this document is *derived from the shipped Flutter client*
> — the interfaces in `lib/features/my_visits/data/remote/` and the DTOs in
> `lib/features/my_visits/data/models/`. Where the client already parses a
> field, that field's name and type are a hard requirement, not a suggestion.
> Anything marked **OPEN** is a decision the backend team still needs to make.

---

## 1. What this feature is

A field sales rep is given a **route** for the day: an ordered list of **stops**,
each at a customer or depot. At each stop the rep checks in (location-verified),
performs work — a stock count, a quotation, notes, photos, a cash collection —
and checks out. The app then syncs everything.

The single most important property: **the rep works with no connectivity for
hours at a time.** Every action is written to the device first and succeeds
locally. Sync is opportunistic and must never be required for the rep to keep
working. Every decision below follows from that.

---

## 2. Conventions

These match the endpoints the app already consumes (auth, catalog); the visit
endpoints must not diverge.

| | |
|---|---|
| Base URL | `https://www.pnc-spts-stg-api.me` (staging) |
| Prefix | `/api/v1` |
| Auth | `Authorization: Bearer <access_token>` |
| Content type | `application/json; charset=utf-8` |
| Correlation | Echo `X-Correlation-Id`; expose it via `Access-Control-Expose-Headers` |
| Timestamps | ISO-8601 **with offset**, e.g. `2026-08-20T09:15:00+07:00` |
| Enums | Sent and received as the exact strings in §4 — never integers |

### 2.1 Success envelope

Wrapped, as elsewhere in the API (`ApiEnvelope.fromBody`):

```json
{ "data": { }, "message": null, "metadata": { } }
```

### 2.2 Errors

RFC 7807 `application/problem+json`, matching the auth endpoints:

```json
{
  "type": "https://docs.isigroup.com.kh/errors/Visit.StopNotFound",
  "title": "Not found.",
  "status": 404,
  "detail": "Stop 'stop-91' is not on a route assigned to this rep.",
  "instance": "/api/v1/mobile/visits/push",
  "errorCode": "Visit.StopNotFound",
  "correlationId": "0HNNSTRGHBJR4:00000001"
}
```

---

## 3. The offline-first contract

Three rules the backend must honour. They are not negotiable client-side —
the app is already built this way.

**3.1 — The client generates all row ids.** Every captured row (check-in,
note, photo, order line…) is created offline with a client-side unique id. The
backend must accept that id as the primary key, not mint its own. There is no
moment at which the client can wait for a server id.

**3.2 — Every write is idempotent on that id.** A rep in a tunnel will retry.
The same batch may arrive twice. Re-posting a row the server already holds must
return success, not a duplicate-key error and not a second row.

**3.3 — Push is partially acceptable.** One bad row must not reject a day's
work. The push endpoint returns *which ids it took and which it refused*; the
client keeps refused rows pending and retries them. A 4xx for the whole batch
because one photo was malformed would strand every other capture on the device.

---

## 4. Vocabularies

Exact strings. The client parses unknown values to a documented fallback rather
than failing, but sending anything outside these sets is a bug.

| Enum | Values | Fallback on unknown |
|---|---|---|
| `RouteStatus` | `planned`, `published`, `inProgress`, `completed` | `published` |
| `VisitStatus` | `pending`, `enRoute`, `arrived`, `checkedIn`, `checkedOut`, `missed` | `pending` |
| `TerritoryType` | `urban`, `suburban`, `industrial`, … | first value |
| `StockLevel` | `low`, `medium`, `high` | `low` |
| `CollectionMethod` | `cash`, `check`, `bankTransfer` | — |
| `VisitNoteType` | `general`, `competitorActivity`, `survey` | — |
| `FraudFlagType` | `mockLocation`, `impossibleSpeed`, `poorAccuracy`, `vpnDetected` | — |

---

## 5. Pull — getting the rep their routes

Scope is always **the signed-in rep**: `repId` + `territory`. The server must
derive `repId` from the bearer token and must never return another rep's routes
even if the client asks.

### 5.1 `GET /api/v1/mobile/visits/routes`

Initial (full) sync. Paginated, because a first install pulls history.

| Query | Type | Notes |
|---|---|---|
| `territory` | string | From the rep's assignment |
| `page` | int | 1-based |
| `pageSize` | int | Client default 200; cap server-side |

```json
{
  "data": {
    "customers": [ /* CustomerStopInfo, §7.1 */ ],
    "routes":    [ /* RoutePlan with nested stops, §7.2 */ ],
    "hasMore": false
  }
}
```

`customers` is a flat, de-duplicated list; each stop joins to it by
`customerId`. A customer appearing on three stops is sent **once**.

The client reads only `customers`, `routes` and `hasMore` from this body. The
existing mock payload also carries `generatedAt` and `territories` at the top
level, which the client ignores today — `generatedAt` is a reasonable place to
put the server's authoritative sync watermark if you want the client to adopt
one later.

### 5.2 `GET /api/v1/mobile/visits/routes/delta`

| Query | Type | Notes |
|---|---|---|
| `territory` | string | |
| `since` | ISO-8601 | Client's last successful sync watermark |

Same body shape. Note the client deliberately treats this as a **full re-pull of
the rep's current scoped set**, not an incremental diff — a rep has a handful of
routes per day, so the simplicity is worth more than the bytes saved. The
`since` parameter exists so the server *may* short-circuit with an empty page
when nothing changed.

Returning the complete current set every time is acceptable and expected.

---

## 6. Push — sending captured work back

### 6.1 `POST /api/v1/mobile/visits/push`

**One request carries every pending row of every kind.** The client batches
because a rep coming back into signal should drain the whole device in one
round trip, not eight.

```json
{
  "checkIns":     [ /* §7.3 */ ],
  "checkOuts":    [ /* §7.4 */ ],
  "orderLines":   [ /* §7.5 */ ],
  "stockUpdates": [ /* §7.6 */ ],
  "returns":      [ /* §7.7 */ ],
  "collections":  [ /* §7.8 */ ],
  "notes":        [ /* §7.9 */ ],
  "photos":       [ /* §7.10 */ ]
}
```

Any list may be empty; the client does not send the request at all when every
list is empty.

**Response — 200, always, when the request itself was well-formed:**

```json
{
  "data": {
    "acceptedIds": ["ci-8f2…", "note-11c…"],
    "rejectedIds": ["photo-77a…"],
    "syncedAt": "2026-08-20T09:41:02+07:00"
  }
}
```

- `acceptedIds` — durably stored. The client marks these synced and will not
  send them again.
- `rejectedIds` — **kept pending on the device and retried later.** Use this for
  transient failures. Do *not* use it for permanently invalid rows: the client
  will retry them forever. See **OPEN-2**.
- Ids the client sent that appear in neither list are treated as rejected.

Reject the whole request (4xx) only when the *envelope* is unusable — malformed
JSON, bad auth. Never because of an individual row.

---

## 7. Payload reference

Field names are exactly what the client reads. `?` marks nullable.

### 7.1 CustomerStopInfo

| Field | Type | Notes |
|---|---|---|
| `id` | string | Referenced by stops |
| `name` | string | |
| `nameKh` | string? | `""` when absent — the documented "no Khmer name" value |
| `code` | string | Customer code |
| `contact` | string | Contact person |
| `phone` | string | |
| `address` | string | |
| `territory` | string | |
| `territoryType` | enum | §4 |
| `latitude` | number | Used for geofence verification |
| `longitude` | number | |
| `geofenceRadiusOverride` | number? | Metres; falls back to the app default |

### 7.2 RoutePlan

| Field | Type |
|---|---|
| `id`, `name`, `repId`, `repName`, `territory` | string |
| `visitDate`, `plannedStart`, `plannedEnd` | ISO-8601 |
| `status` | `RouteStatus` |
| `stops` | array of RouteStop |

**RouteStop**

| Field | Type | Notes |
|---|---|---|
| `id`, `routeId` | string | |
| `customerId` | string | Joins to §7.1 |
| `sequence` | int | Visit order |
| `plannedArrival`, `plannedDeparture` | ISO-8601 | |
| `status` | `VisitStatus` | **Send the real execution state.** Hardcoding `pending` makes the dashboard read 0% complete regardless of data — this was a real client bug. |
| `actualArrival`, `actualDeparture` | ISO-8601? | Null until it happens |

### 7.3 CheckIn

| Field | Type | Notes |
|---|---|---|
| `id`, `stopId` | string | |
| `timestamp` | ISO-8601 | |
| `latitude`, `longitude` | number | Where the rep actually was |
| `accuracy` | number | GPS accuracy, metres |
| `distanceFromCustomer` | number | Metres from the customer pin — the geofence evidence |
| `isMocked` | bool | Device reported a mock location provider |

### 7.4 CheckOut

`id`, `stopId`, `timestamp`, `latitude`, `longitude`, `durationMinutes` (int),
`visitSummary` (string?).

### 7.5 OrderLine
`id`, `stopId`, `productId`, `productName`, `quantity` (number), `unit`, `unitPrice` (number).

### 7.6 StockUpdate
`id`, `stopId`, `depotId`, `productId`, `productName`, `stockLevel` (`StockLevel`), `notes` (string?).

### 7.7 Return
`id`, `stopId`, `productId`, `productName`, `quantity` (number), `reason`.

### 7.8 Collection
`id`, `stopId`, `amount` (number), `method` (`CollectionMethod`), `reference` (string?), `notes` (string?).

### 7.9 Note
`id`, `stopId`, `type` (`VisitNoteType`), `text`, `createdAt`.

### 7.10 Photo
`id`, `stopId`, `url`, `caption` (string?), `takenAt`, `isSignature` (bool).

See **OPEN-1** — `url` is currently a *device-local* path.

---

## 8. Validation the backend owns

The client cannot enforce these; it is offline when the data is made.

1. **Stop ownership** — every `stopId` must belong to a route assigned to the
   authenticated rep. Reject cross-rep writes.
2. **Geofence** — `distanceFromCustomer` and `isMocked` are *evidence submitted
   by the device*, not a verdict. The server decides whether a visit counts.
   Treat `isMocked: true` as a fraud signal, not a hard reject: the row still
   needs storing so it can be investigated.
3. **Ordering** — a check-out may arrive before its check-in if the batch was
   assembled oddly. Accept both and reconcile by `timestamp`, rather than
   rejecting on arrival order.
4. **Clock skew** — device clocks are wrong. Store the client timestamp *and*
   a server receipt time; never overwrite the client's.

---

## 9. Non-functional

- **Batch size** — a rep offline for a full day can accumulate hundreds of rows
  plus photos. Define and document a cap; the client currently sends everything
  pending in one request (**OPEN-3**).
- **Latency** — the push runs in the background; a slow response is fine, a
  timeout that loses the accepted/rejected split is not.
- **Retries** — the client retries the whole batch. Idempotency (§3.2) is what
  makes that safe.
- **CORS** — the Flutter *web* build calls these endpoints from a browser. Any
  deployed origin must be on the API's allowlist, or every request fails before
  it leaves the browser and surfaces to the client as a network error rather
  than a policy rejection.

---

## 10. Open questions

**OPEN-1 — Photo upload.** `VisitPhoto.url` is a path on the device. Binary
cannot travel in the JSON batch. Two workable shapes: a separate
`POST /mobile/visits/photos` multipart endpoint that returns a server URL the
batch then references, or pre-signed upload URLs issued with the route. This
needs deciding before photo capture can sync at all. **Blocking for photos.**

**OPEN-2 — Permanent rejection.** `rejectedIds` currently means "retry later".
There is no way to say "this row is invalid, stop sending it", so a permanently
bad row retries forever. Recommend adding a third bucket
(`discardedIds`, with reasons) — needs a matching client change.

**OPEN-3 — Batch limits.** Maximum rows and bytes per push, and the expected
client behaviour when exceeded (chunking is not implemented client-side today).

**OPEN-4 — Not yet in the push contract.** Two things the app captures locally
but never sends: **fraud flags** (`FraudFlagType`, §4) and **location samples**
(the GPS breadcrumb trail: lat/lng/accuracy/speed/heading/altitude/timestamp/
isMocked per route). Both are compliance-relevant. Decide whether they belong in
this batch, on their own endpoint, or stay device-only.

**OPEN-5 — Route write-back.** The client updates stop and route status locally
(`updateStopStatus`, `updateRouteStatus`). Whether those transitions are derived
server-side from check-in/check-out, or pushed explicitly, is undecided. Deriving
them server-side is simpler and avoids two sources of truth.

**OPEN-6 — Territory. Resolved client-side.** `RouteSyncScope` now reads the
rep's `territoryCode` from the auth profile (`GET /auth/me`), which does carry
it — e.g. `PP-NORTH`. The former hardcoded `"Phnom Penh"` matched only the
retired fixture data. Backend note: territory codes must match what the route
endpoint filters on; when the profile carries none, the client omits the query
key entirely and expects the server to scope from the bearer token.

---

## 11. Suggested build order

1. `GET /routes` (§5.1) — unblocks the whole feature; the app can already
   consume it.
2. `POST /push` (§6) for the non-binary captures — check-ins, check-outs, notes,
   stock updates.
3. Resolve **OPEN-1**, then photos.
4. Delta sync (§5.2) — a performance optimisation, not a prerequisite.
5. **OPEN-4** compliance data.

The client now calls these endpoints for real: `ApiRouteRemoteDataSource` and
`ApiVisitSyncRemoteDataSource` are the only implementations of the two
interfaces above. The bundled fixture sources they replaced have been removed,
so there is no longer a mock path that can make a missing or misbehaving
endpoint look healthy — the app shows what the API returns, or shows the
failure. Tests script the HTTP transport instead of substituting a fake feed.
