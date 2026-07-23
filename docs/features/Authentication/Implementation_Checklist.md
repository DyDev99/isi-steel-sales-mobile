# Authentication — Implementation Checklist

> Status audit generated 2026-07-23 against the actual codebase. ✅ done · 🟡 partial/mock · 🔴 missing.

---

## Architecture

- [x] ✅ Clean triad `presentation → domain → data`; domain is pure Dart (no Flutter/Dio/storage imports verified)
- [x] ✅ One use case per action (`Login`, `Logout`, `GetCurrentUser`) — no mode parameters
- [x] ✅ Typed `Failure`s only cross into presentation (`Result.when`)
- [x] ✅ No cross-feature `data/` imports into or out of the feature
- [ ] 🟡 Reset-flow screens bypass the bloc (documented, deliberate) — migrate to AuthBloc events when backend lands

## Repository

- [x] ✅ Interface in `domain/repositories/`, impl in `data/repositories/`
- [x] ✅ Offline-first `getCurrentUser` (local-only, both-present rule)
- [x] ✅ Fail-fast offline login; best-effort logout
- [x] ✅ All four exception→failure mappings implemented
- [ ] 🔴 No repository methods for forgot-password / verify-OTP / reset-password (G-2)

## Bloc

- [x] ✅ `AuthBloc` maps events→usecases; zero business logic
- [x] ✅ `droppable()` on login; SessionManager mirrored on every change
- [x] ✅ Naming conventions (events `…Requested`/`…Event`, states `…State`)
- [ ] 🟡 `UnauthenticatedState` defined but never emitted (reserved for session-expiry, G-5)
- [ ] 🟡 DI registers bloc as factory but it's provided once at root — align when next touched

## UI

- [x] ✅ 5 screens complete (Login, Forgot Password, Verify, Create New Password, Success)
- [x] ✅ Shared widget kit (IdentifierField, VibeField, OtpField, StatusPill, GradientButton)
- [x] ✅ Screen-local navigation on login success (no global listener)
- [x] ✅ Scroll-safe, maxWidth-420, keyboard-aware layouts
- [ ] 🟡 `onRequestAccess` hook on LoginScreen unwired (registration out of scope)

## Theme

- [x] ✅ All colors via `ColorScheme` / `context.appColors`; light + dark verified in code
- [x] ✅ Aurora/glass shared visual language; cached ThemeData (no restart on toggle)
- [ ] 🔴 No golden tests (light/dark) — required by standard §10

## Localization

- [x] ✅ All copy via `auth.*` keys; en + km parity; parameterized strings used correctly
- [x] ✅ Khmer font swap via `fontFamilyForLocale`
- [ ] 🔴 No localization tests (key-resolution / golden en+km)

## Offline

- [x] ✅ Zero-network boot restore; null-safe reads end to end
- [x] ✅ Offline logout; no blocking offline dialogs
- [x] ✅ Posture declared in `docs/OFFLINE_FIRST.md` §4 ("Built")
- [ ] 🟡 Connectivity check is interface-up, not reachability (core gap G-4 / ADR-005)

## Sync

- [x] ✅ N/A by design — no syncable writes, no queue rows (documented in [Architecture.md](Architecture.md) §6)
- [x] ✅ Token refresh: single-flight, replay-once, bare-client isolation

## Security

- [x] ✅ Tokens + cached user only in `flutter_secure_storage`; keys centralized in `AppConstants`
- [x] ✅ No PII/tokens in logs from this feature; typed errors only to UI
- [x] ✅ No hardcoded gateway host (Envied `Env.apiBaseUrl`)
- [ ] 🔴 **Release blocker**: mock login untagged (G-1) — add `// TODO(release-gate):` + debug-only gating + CI grep
- [ ] 🔴 Mock OTP/reset callbacks untagged (G-2)
- [ ] 🔴 Session-expiry propagation after failed refresh (G-5)
- [ ] 🟡 Password policy (≥6 chars) unconfirmed against backend policy

## Testing

- [ ] 🔴 Domain unit tests (target ≥ 90%) — **none exist**
- [ ] 🔴 Data unit tests (target ≥ 80%) — none
- [ ] 🔴 Bloc tests (incl. droppable) — none
- [ ] 🔴 Interceptor tests (100% branches — security control) — none
- [ ] 🔴 Widget/golden/integration tiers — none
- Full matrix: [QA_Test_Plan.md](QA_Test_Plan.md) §8

## Documentation

- [x] ✅ Flow narrative: `docs/authentication_flow.md` (pre-existing, §4 kh→km correction noted)
- [x] ✅ This 15-document package (`docs/features/Authentication/`)
- [x] ✅ Referenced as the offline-first reference implementation in `docs/OFFLINE_FIRST.md` §2
- [ ] 🟡 ADR for guest-first auth decision itself (currently only embedded in OFFLINE_FIRST/flow docs) — optional backfill
