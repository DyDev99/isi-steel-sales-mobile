# ISI Steel Mobile: Full Regression Suite

Run the automated suite on every pull request (CI) and the complete regression suite before every staging/production release.

| Area / Module | Test Case / Scenario | Priority | Automated Level | Command / Trigger |
|---|---|---|---|---|
| **Authentication** | TC-AUTH-001 (Valid Login) | P1 | ✅ E2E Robot | `qa_agent.sh integration <device>` |
| **Authentication** | TC-AUTH-002 to 004 (Validation & Errors) | P1 | ✅ Unit + Widget | `qa_agent.sh unit` |
| **Authentication** | TC-AUTH-008 to 012 (OTP & Password Reset) | P1 | ✅ Unit + Widget | `qa_agent.sh unit` |
| **Authentication** | TC-AUTH-013 to 015 (Token Refresh & Logout) | P1 | ✅ Unit | `qa_agent.sh unit` |
| **Sales Orders** | TC-ORD-001, 002 (Catalog Browsing & Search) | P1 | ✅ Widget + E2E | `qa_agent.sh widget` |
| **Sales Orders** | TC-ORD-003, 006 (Steel Specs & Pricing Calc) | P1 | ✅ Unit | `qa_agent.sh unit` |
| **Sales Orders** | TC-ORD-009 (Credit Limit Validation) | P1 | ✅ Unit + Widget | `qa_agent.sh unit` |
| **Sales Orders** | TC-ORD-010 (Save Local Draft via Drift/SQLite) | P1 | ✅ Unit + Widget | `qa_agent.sh unit` |
| **Sales Orders** | TC-ORD-011, 012 (Submit Order & Double-Tap) | P1 | ✅ E2E Robot + Unit | `qa_agent.sh integration <device>` |
| **My Visits** | TC-VISIT-001 (Scheduled Visits Itinerary) | P1 | ✅ Widget + E2E | `qa_agent.sh widget` |
| **My Visits** | TC-VISIT-002, 003 (GPS Check-In & Geofence) | P1 | ✅ Unit + Widget | `qa_agent.sh unit` |
| **My Visits** | TC-VISIT-006 (Photo Proof Capture) | P2 | ❌ Manual (Hardware) | Manual device test |
| **My Visits** | TC-VISIT-008 (Check-Out & Outcome Summary) | P1 | ✅ E2E Robot | `qa_agent.sh integration <device>` |
| **Quotations** | TC-QUOT-001 to 003 (Draft Quote & Discount) | P1 | ✅ Unit + Widget | `qa_agent.sh unit` |
| **Quotations** | TC-QUOT-006 (PDF Generation & Layout) | P1 | ✅ Widget + Manual | `qa_agent.sh widget` |
| **Quotations** | TC-QUOT-008 (Convert Quotation to Order) | P1 | ✅ E2E Robot | `qa_agent.sh integration <device>` |
| **Depots** | TC-DEPOT-001 to 004 (Depot Stock & Availability) | P2 | ✅ Unit + Widget | `qa_agent.sh unit` |
| **Offline Sync** | TC-SYNC-001 to 003 (Catalog Offline & Auto Sync) | P1 | ✅ Unit + Widget | `qa_agent.sh unit` |
| **Notifications** | TC-NOTIF-001 to 003 (Push Channels & Deep Linking) | P2 | ✅ Widget + Unit | `qa_agent.sh widget` |
| **Localization** | Khmer / English font rendering across all screens | P1 | ✅ Widget + Manual | `qa_agent.sh widget` |

---

## Smoke Test Suite (Run on every commit, < 3 minutes)

The Smoke suite verifies the critical revenue pipeline:
```bash
./scripts/qa_agent.sh smoke
```

1. **SMK-01:** App boots cleanly to Splash -> loads initial config.
2. **SMK-02:** User can log in with valid credentials.
3. **SMK-03:** Home dashboard loads with KPI cards and bottom navigation.
4. **SMK-04:** Product catalog loads items without error.
5. **SMK-05:** Item can be added to Cart and Subtotal calculated.
6. **SMK-06:** Customer itinerary loads in My Visits.
