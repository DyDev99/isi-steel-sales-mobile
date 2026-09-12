# Authentication — API Documentation

> Generated 2026-07-23 from `lib/core/constants/app_constant.dart`, `lib/core/network/app_network.dart`, `lib/core/middleware/app_middleware.dart`, and `lib/features/authentication/data/`. The backend is not yet live for reset flows; request/response shapes below are exactly what the client sends/parses.

---

## 1. Base configuration

| Item | Value | Source |
|---|---|---|
| Base URL | `Env.apiBaseUrl` (Envied, compile-time `.env` — **never hardcoded**) | `AppNetwork._baseOptions` |
| API prefix | `/v1` | `AppConstants.apiPrefix` |
| Connect timeout | 15 s | `AppConstants.connectTimeout` |
| Receive timeout | 20 s | `AppConstants.receiveTimeout` |
| Default headers | `Accept: application/json` | `AppNetwork` |
| Clients | **bare** (no interceptor — login, refresh, replay) and **authed** (`AuthInterceptor`) | `AppNetwork.createBareClient/createAuthedClient` |

## 2. Endpoints

### 2.1 `POST /v1/auth/login`

- **Auth**: none (public; called on the authed client but no token exists yet).
- **Request body**: `{ "email": "<identifier>", "password": "<password>" }`
  - ⚠ `email` may contain an email **or** phone number (`IdentifierField`); see Blueprint G-6.
- **Response (parsed tolerantly by `AuthResponseModel.fromMap`)** — any of:
  ```json
  { "user": { "id": "…", "email": "…", "full_name": "…", "roles": ["salesRep"], "company": null, "avatar_url": null },
    "access_token": "…", "refresh_token": "…" }
  ```
  or the same wrapped in `{ "data": { … } }`. `full_name`|`name` and `roles`|`user_roles` are both accepted. Missing tokens default to `""`.
- ⚠ **MOCK (G-1)**: `tester@gmail.com` / `tester@12345` short-circuits to a local mock response without any HTTP call.

### 2.2 `POST /v1/auth/refresh`

- **Caller**: `AuthInterceptor._performRefresh` only (bare client — never intercepted).
- **Request body**: `{ "refresh_token": "<refresh>" }`
- **Response**: `{ "access_token": "…", "refresh_token": "…"? }` — a missing new refresh token keeps the old one. A missing `access_token` = refresh failure.

### 2.3 `POST /v1/auth/logout`

- **Auth**: `Authorization: Bearer <access>` (authed client).
- **Body**: none. Response ignored.
- **Client policy**: best-effort — only attempted when online; any error is swallowed; local session is cleared regardless.

### 2.4 `GET /v1/auth/me`

- **Auth**: Bearer. Parses `{ "user": {…} }` or a bare user object.
- **Status**: implemented in `AuthRemoteDataSourceImpl.getCurrentUser` but **not called anywhere** — the repository's `getCurrentUser` is purely local. Reserved for a future "revalidate profile when online" path.

### 2.5 Not yet implemented (UI exists, endpoints absent)

Forgot-password request, OTP verify, and password reset have no endpoints/constants yet; `app_page.dart` stubs them with delays and mock acceptance (OTP `111111`). See Blueprint G-2.

## 3. Headers

| Header | When | Set by |
|---|---|---|
| `Authorization: Bearer <access_token>` | Every authed-client request with a non-empty stored token | `AuthInterceptor.onRequest` |
| `Accept: application/json` | Always | `AppNetwork` |

## 4. Authentication & refresh protocol

1. 401 on an authed request (not previously retried) triggers refresh.
2. Concurrent 401s **coalesce into one** refresh call (`_refreshCompleter` single-flight; `QueuedInterceptor` serializes handlers).
3. Success → tokens saved via `TokenStore.saveTokens` → original request replayed **once** (marked `extra['__auth_retried__']`) on the bare client.
4. Refresh failure (no/empty refresh token, HTTP error, missing `access_token`) → `TokenStore.clear()` → original 401 propagates to the caller. ⚠ The UI/session layer is not notified (G-5).
5. A 401 on the replayed request propagates — no retry loops.

## 5. Error codes (client mapping — `AuthRemoteDataSourceImpl._map`)

| Condition | Typed exception | Failure shown |
|---|---|---|
| connection error / connect / send / receive timeout | `NetworkException` | `NetworkFailure` |
| HTTP 401, 403 | `AuthenticationException` | server `message` or "Invalid email or password." |
| any other Dio error / status | `ServerException` | server `message` or "Something went wrong. Please try again." |

Server error bodies of shape `{ "message": "…" }` are surfaced verbatim to the user.

## 6. Timeout & retry policy

- Timeouts per §1; a timeout is a `NetworkException`, never retried automatically.
- **Only** the 401→refresh→replay path retries, exactly once. No exponential backoff exists at this layer (sync-engine backoff is a separate, unbuilt subsystem).

## 7. Offline behavior

- `login` fails fast client-side (`NetworkInfo.isConnected == false` → `NetworkFailure`) — no request, no timeout wait. ⚠ Interface-up check only (ADR-005 / G-4): captive-portal Wi-Fi will pass the check and then hit timeouts.
- `logout` skips the network entirely when offline.
- No other auth network activity occurs offline.

## 8. Caching

- **Session cache**: tokens + serialized user in secure storage (written on login success, updated on refresh, deleted on logout/failed refresh). This is the cache that enables offline boot.
- **No HTTP-level caching** (no ETag/If-None-Match, no dio cache interceptor) for auth endpoints.
