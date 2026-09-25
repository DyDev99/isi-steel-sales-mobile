# Exploratory Charter: GPS Geofence, Accuracy & Anti-Spoofing

**Target:** `features/my_visits` and `features/geo_location`  
**Time Box:** 45 minutes  
**Tester Persona:** Sales Supervisor verifying integrity of check-in audits

## Charter Goals
Ensure that site visit check-ins accurately reflect physical presence and cannot be bypassed or compromised:
1. **Geofence Boundary Probing:**
   - Test check-in at 50m, 95m, 105m, 250m, and 1000m from customer coordinates.
   - Verify that ≤100m allows direct check-in.
   - Verify that >100m triggers the off-site verification workflow requiring supervisor justification.
2. **GPS Accuracy Degradation:**
   - Test under covered tin roofs / steel warehouses where satellite lock is weak (accuracy radius > 80m).
   - Verify the app waits for sufficient accuracy or shows a clear indicator rather than recording misleading coordinates.
3. **Mock Location App Detection:**
   - Install "Fake GPS Location" app on Android developer mode.
   - Set mock location directly on customer warehouse while physically elsewhere.
   - Verify app detects `isMocked` flag and rejects fraudulent check-in.
4. **Airplane Mode vs GPS:**
   - Verify GPS chip can still acquire coordinates when mobile data is off (standalone GNSS).

## Output
Record results and screenshot evidence for any boundary bypass.
