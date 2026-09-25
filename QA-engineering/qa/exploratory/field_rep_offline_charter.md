# Exploratory Charter: Provincial Field Rep & Offline Endurance

**Target:** Sales Order creation, My Visits Check-In, Catalog Browsing  
**Time Box:** 60 minutes  
**Tester Persona:** Field Sales Rep traveling along National Road 5 (intermittent 2G/3G/No Signal)

## Charter Goals
Explore how the mobile app behaves when operating under real Cambodian field conditions:
1. **Prolonged Offline Work:** Browse catalog, create multiple draft orders for different customers with customized steel dimensions while Airplane Mode is engaged.
2. **Reconnection Storm:** Re-enable network and observe background worker syncing 5+ queued records. Verify:
   - Does the app freeze or drop frames (ANR)?
   - Are orders submitted with original timestamps?
   - Does any order get duplicated?
3. **App Suspension & Low Memory:** Background the app while on cart screen, launch heavy camera or maps app to trigger OS memory reclamation, then restore ISI Steel Sales App. Verify state restoration without data loss.

## Edge Cases to Probe
- Creating a draft order, then switching app language from Khmer to English before submitting.
- Turning off data right as "Confirm Order" button is tapped (mid-flight socket drop).
- Battery saver mode killing background sync services on Android.
- Attempting to check in to a visit with airplane mode on, then completing the visit 30 minutes later before syncing.

## Output
Log all discovered defects in `qa/bug_reports/` using the standard bug template.
