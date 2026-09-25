# My Visits & Geolocation: User Scenarios

| Scenario | Description | Priority | Automated Coverage | Manual Validation |
|---|---|---|---|---|
| SC-VISIT-01 | Scheduled Daily Site Visit & Geofence Check-In | Sales rep opens itinerary, navigates to depot/hardware retailer, verifies GPS within 100m geofence, and successfully checks in. | P1 | E2E Robot (`visit_flow_test.dart`) | Verify map pin accuracy |
| SC-VISIT-02 | Off-Site Check-In with Mandatory Justification | Rep meets customer outside their registered shop (e.g. at coffee shop or construction site 500m away); app allows check-in after requiring explanation note. | P1 | Widget + Unit | Audit log check in supervisor portal |
| SC-VISIT-03 | Storefront Photo Proof & Inventory Survey | Rep captures high-resolution storefront photo, fills stock audit of competitor steel inventory, and submits completed stop. | P2 | Widget | Verify image compression (<500KB) |
| SC-VISIT-04 | GPS Disabled or Mocked Location Attempt | Rep attempts check-in with GPS disabled or spoofing app active; app rejects check-in and guides user to enable true device GPS. | P1 | Unit | Test with mock location developer tool |
| SC-VISIT-05 | Offline Stop Check-In & Sync | Rep visits remote construction site with zero cellular reception; check-in and survey saved locally, automatically syncing on return to depot. | P1 | Unit + Widget | Airplane mode manual test |
