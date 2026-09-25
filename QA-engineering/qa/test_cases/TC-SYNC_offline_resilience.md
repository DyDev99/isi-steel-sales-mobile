# Offline Sync & Resilience: Test Cases

**Feature:** Offline First Architecture, Local Cache (Drift/SQLite/Hive) & Background Sync  
**Package:** `isi_steel_sales_mobile/core/database`, `features/order`, `features/my_visits`  
**Priority:** P1 (Field Resilience)  
**Preconditions:** Logged in user with pre-cached master data.

| ID | Title | Steps | Test Data / Payload | Expected Result | Type | Automated Level |
|---|---|---|---|---|---|---|
| TC-SYNC-001 | Offline Product Catalog Browsing | 1. Log in while online to sync catalog<br>2. Enable Airplane Mode<br>3. Browse categories, items, and search | Offline mode, cached SQLite/Drift database | Catalog, specs, images (cached in `cached_network_image`), and pricing load instantly from local storage with no blank screens. | Offline | Unit + Widget |
| TC-SYNC-002 | Offline Order Creation & Local Outbox | 1. In Airplane Mode, add items to cart and submit order | Offline mode | Order stored in local `Outbox` table with status `QUEUED_OFFLINE`. UI displays offline banner: "Order queued for upload". | Offline | Unit + Widget |
| TC-SYNC-003 | Auto-Sync on Network Restoration | 1. Have 2 queued orders and 1 visit check-in in Outbox<br>2. Disable Airplane Mode (reconnect WiFi/4G) | Connectivity state changes to `connected` | `connectivity_plus` listener triggers background sync worker. Outbox items dispatched in FIFO order. Success toasts displayed. | Sync | Unit + Widget |
| TC-SYNC-004 | Conflict Resolution - Price Increase While Offline | 1. Rep creates offline order with product price $50<br>2. Admin changes price on ERP to $55<br>3. Rep reconnects and sync triggers | Price conflict: $50 vs $55 | App alerts user of price change before charging. User prompted to "Accept new total ($55)" or "Review Order". | Concurrency | Unit |
| TC-SYNC-005 | Transient Network Drop Mid-Submission | 1. Tap Submit Order<br>2. Cut network connection during request transit | Interrupted socket | Request fails gracefully; interceptor catches timeout/socket exception and marks order as pending retry instead of duplicating order. | Resilience | Unit |
| TC-SYNC-006 | App Kill During Background Sync | 1. Queue 5 items for sync<br>2. Trigger sync and immediately swipe kill app<br>3. Re-open app | Mid-sync kill | Unsynced records remain in `Pending` state with no data corruption. Sync resumes on next app startup. | Resilience | Unit |
| TC-SYNC-007 | SQLite / Drift Migration Safety | 1. Install app with DB v1<br>2. Upgrade to DB v2 schema<br>3. Open app | Schema migration | Migration script runs seamlessly without dropping user tables or clearing saved offline drafts. | DB Migration | Unit |
