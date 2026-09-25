# ISI Steel Sales Mobile: Pre-Release Verification Checklist

**App Version:** `1.0.0`  **Build Number:** `______`  **Target:** [ ] Staging / [ ] Production  
**QA Lead:** `_______________`  **Release Date:** `_______________`

---

## 1. Automated Quality Gates
- [ ] `./scripts/qa_agent.sh doctor` returns clean environment check.
- [ ] `./scripts/qa_agent.sh analyze` passes with 0 lint errors and clean formatting.
- [ ] Unit & Widget tests pass: `./scripts/qa_agent.sh regression` exit code `0`.
- [ ] Code line coverage meets target (minimum `60%` threshold).
- [ ] Integration robot tests pass on Android emulator or physical device.
- [ ] No flaky tests or unapproved skips introduced in the release candidate.

---

## 2. Core Functional Journeys (Manual Smoke & Sanity)
- [ ] **Authentication:** Login with sales rep credentials succeeds on cold boot.
- [ ] **Catalog & Custom Specs:** Steel products display correct prices, gauges, and dimensions.
- [ ] **Cart & Calculation:** Subtotal, volume discount tier, and 10% VAT calculate accurately.
- [ ] **Sales Order Creation:** Order successfully submitted and verified in ERP/SAP backend.
- [ ] **Quotations & PDF:** Quotation created, manager discount approval tested, PDF renders with ISI logo and shares cleanly.
- [ ] **My Visits & Geolocation:** Check-in inside geofence succeeds; check-in outside 100m prompts for off-site justification; checkout records accurate duration.
- [ ] **Depot Inventory:** Stock check returns live depot quantities.

---

## 3. Resilience, Offline & Data Integrity
- [ ] **Offline Endurance:** Create an order and check-in with Airplane Mode on; reconnect and verify clean background sync without duplicate records.
- [ ] **Database Migration:** Upgrade test from previous version retains all user session tokens, local drafts, and offline logs without SQLite schema error.
- [ ] **Process Kill Recovery:** App kill during active form entry restores draft state on restart.

---

## 4. UI, Localization & Accessibility
- [ ] **Khmer Language:** Switch app to Khmer (`km`); verify all headers, buttons, error messages, and currency formatting render without clipping or `...` truncation.
- [ ] **Display Scaling:** Verify screens at 120% and 150% font sizes (no `RenderFlex overflow` yellow/black striped bars).
- [ ] **Dark Mode:** Light and Dark themes both readable with high contrast compliance.

---

## 5. Security & Release Readiness
- [ ] All P1/Critical blockers resolved or accepted in writing by Product Owner.
- [ ] API endpoints pointing to Production base URL (`.env.production` verified).
- [ ] Debug banners (`debugShowCheckedModeBanner: false`) and verbose logging disabled.
- [ ] ProGuard / R8 minification verified for Android APK/AAB.
- [ ] iOS Code Signing and provisioning profiles validated for App Store / TestFlight distribution.

---

**Release Verdict:** [ ] **GO** / [ ] **NO-GO**  
**Authorized By:** __________________________________ **Date:** __________________
