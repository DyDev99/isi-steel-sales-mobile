# Authentication Flow

Guest-first authentication for the ISI Steel Sales app. Users can explore the
whole app without an account and are asked to sign in only when they reach a
feature that genuinely needs one. Built on the existing Clean Architecture
(`data → domain → presentation`) — no rewrites, no new dependencies.

---

## 1. Boot & navigation flow

```
Splash Screen
     │  (reads onboarding_complete)
     ├───────────── not complete ─────────────┐
     │                                         ▼
     │                                  Language Selection
     │                                  (= onboarding step)
     │                                         │  "Let's go" →
     │                                         │  set onboarding_complete = true
     │                                         │  enter Guest (if not signed in)
     │                                         ▼
     └───────────── complete ─────────────►  MainShell
                                              │
        AuthBloc.AuthCheckRequested (on boot) resolves in the background:
            cached session ─► Authenticated   (SessionManager.setUser)
            no session      ─► Guest           (SessionManager.clear)
```

Both **signed-in** and **guest** users land on `MainShell`. Nobody is forced
through the login screen at startup, and **AppCoach never auto-launches**.

### Where routing decisions live

Navigation is deliberately **not** driven by a global auth listener (that caused
guests to be yanked around and produced duplicate redirects). Each surface owns
its own transition:

| Trigger | Owner | Destination |
|---|---|---|
| Cold boot | `SplashScreen` | `main` or `chooseLanguage` (by `onboarding_complete`) |
| Onboarding done | `LanguageSelectionScreen._continue` | `main` (enters Guest) |
| Login success | `LoginScreen` `BlocListener` | `main` (stack cleared) |
| Logout | `ProfileScreen._confirmLogout` | pops to `main` as Guest |
| App restart / language change | `app.dart` `_resolveInitialRoute` | auth + onboarding aware |

`_resolveInitialRoute` (in `app.dart`) is re-run whenever `MaterialApp` is rebuilt
(e.g. on language change). It keeps signed-in **and** guest users on the shell —
so switching language mid-session never replays the splash — while showing the
splash exactly once on the first cold boot via the `_splashShown` latch.

---

## 2. Auth state management

`AuthBloc` (`features/authentication/presentation/bloc/`) is the single
orchestrator. It maps events to use cases and mirrors every change into the
app-wide **`SessionManager`** (a DI singleton) so guards, role checks, and sync
scopes share one synchronous source of truth.

### States (`auth_state.dart`)

| State | Meaning |
|---|---|
| `AuthInitialState` | Idle, before the boot check runs |
| `AuthLoadingState` | A request is in flight |
| `AuthenticatedState(user)` | A valid session exists |
| `AuthGuestState` | **Browsing without an account — the default resting state** |
| `UnauthenticatedState` | Transient "must re-authenticate" signal (kept for completeness) |
| `AuthFailureState(message)` | A login attempt failed |

### Events (`auth_event.dart`)

| Event | Effect |
|---|---|
| `AuthCheckRequested` | Session restore on boot → Authenticated or Guest |
| `AuthGuestRequested` | Enter guest browsing explicitly (idempotent) |
| `LoginSubmittedEvent` | Attempt login (droppable — ignores double taps) |
| `LogoutRequested` | Clear session → return to Guest |

### Responsibilities handled

- **User token** — read/written in secure storage by `AuthLocalDataSource`.
- **Login status** — `SessionManager.isAuthenticated`, driven by `AuthBloc`.
- **Logout** — drops token + session, returns to guest browsing.
- **Session restore** — `AuthCheckRequested` → `GetCurrentUser` (offline-first:
  a cached user + token boots straight in).
- **Persistent storage** — see §5.

---

## 3. Protected features (the reusable guard)

`core/auth/auth_guard.dart` is the **one** place feature gating lives. Never
copy an `isAuthenticated` check into a screen — call the guard.

```dart
// Explicit form
if (await AuthGuard.requireAuthentication(context)) {
  openCheckout();
}

// Ergonomic extension
await context.requireAuth(onAuthenticated: openCheckout);
```

Behaviour:

```
requireAuthentication(context):
    IF SessionManager.isAuthenticated:
        run onAuthenticated (if given) → return true
    ELSE:
        show LoginRequiredDialog → return false
```

Apply it to any gated action — **create order, cart, checkout, profile, history,
notifications, saved items**, etc. It is already wired into **Profile** access in
`MainShell._openProfile` as the reference implementation.

---

## 4. Login Required dialog

`core/auth/login_required_dialog.dart` — a premium, Material 3 prompt.

- 🔐 lock badge, title **"Login Required"**, synced-data description.
- Primary **"Login Now"** → closes the prompt, routes to the login screen.
- Secondary **"Later"** → dismisses; the user keeps browsing as a guest.
- Fade + scale-in animation (`showGeneralDialog`), width-capped and scroll-safe
  for all screen sizes, fully **light/dark** aware via `ColorScheme` +
  `AppThemeColors`.
- Returns a `LoginPromptResult` (`login` / `dismissed`) for callers that care.

All copy is localized (`auth.login_required_title`, `auth.login_required_desc`,
`auth.login_now`, `auth.later`) in both `en.json` and `kh.json`.

---

## 5. Storage

| Value | Store | Notes |
|---|---|---|
| `onboarding_complete` | Hive (`AppPreferences`) | Non-sensitive, defaults to `false` safely |
| `access_token` / `refresh_token` | `flutter_secure_storage` | Encrypted; read by repo + network interceptor |
| Cached user | `flutter_secure_storage` | JSON; enables offline-first boot |

Reads are null-safe: a missing token yields Guest (never a crash), and
`AppPreferences.isOnboardingComplete` falls back to `false`.

---

## 6. Why this scales

- **Single source of truth** — `SessionManager`, fed by `AuthBloc`, is read
  synchronously everywhere (guards, roles, sync scopes).
- **No duplicated gating** — one `AuthGuard`; new protected features are a
  one-line call.
- **Decoupled navigation** — each surface owns its transition, so adding flows
  won't create redirect races.
- **Clean Architecture preserved** — changes stayed within existing
  `data/domain/presentation` layers; no new packages.
- **Guest-first UX** — friction only appears exactly when an account is required,
  matching modern consumer apps.

### Adding a new protected feature

1. In the tap handler, call `await context.requireAuth(onAuthenticated: ...)`
   (or gate with the returned `bool`).
2. That's it — the dialog, routing, and session check are handled centrally.

---

## 7. Test scenarios

| # | Scenario | Expected |
|---|---|---|
| 1 | Fresh install → complete onboarding | Lands on `MainShell`; **AppCoach does not appear** |
| 2 | Guest opens a protected feature (Profile) | `LoginRequiredDialog` appears |
| 3 | Dialog → "Login Now" | Navigates to the login screen |
| 4 | Dialog → "Later" | Dialog closes; user stays put as guest |
| 5 | Signed-in user opens protected feature | Opens immediately, no prompt |
| 6 | Restart app | State restored: cached session → Authenticated, else Guest; onboarded users skip straight to the shell |
