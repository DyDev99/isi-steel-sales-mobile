# Depot & Inventory: Test Cases

**Feature:** Depot Stock Inquiries, Inventory Visibility & Stock Requests  
**Package:** `isi_steel_sales_mobile/features/depots`  
**Priority:** P2 (Supply Chain / Logistics)  
**Preconditions:** Logged in user with access to depot modules.

| ID | Title | Steps | Test Data / Payload | Expected Result | Type | Automated Level |
|---|---|---|---|---|---|---|
| TC-DEPOT-001 | List Regional Depots | 1. Open Depots tab/menu<br>2. View depot list | Depots in Phnom Penh, Siem Reap, Battambang, etc. | Depots listed with Name, Location, Contact, and operating hours. Map view available. | Functional | Widget + E2E |
| TC-DEPOT-002 | Search Product Stock by Depot | 1. Select specific depot (e.g. "ISI Depot Sen Sok")<br>2. Search SKU (e.g. "Steel Coil 1.2mm") | Depot: Sen Sok<br>SKU: `COIL-1.2` | Displays on-hand quantity, reserved quantity, and available-to-promise (ATP) quantity. | Functional | Unit + Widget |
| TC-DEPOT-003 | Low Stock Alert Indicator | 1. Search item where available stock < safety buffer (e.g. < 5 MT) | Stock: 3 MT (threshold: 5 MT) | Orange badge / warning indicator: "Low Stock (3 MT remaining)". | UI / Business Rule | Widget |
| TC-DEPOT-004 | Out of Stock Item Selection | 1. Try to order or request stock for item with 0 available quantity | Stock: 0 MT | Red badge: "Out of Stock". System prompts user to select alternative depot or place backorder. | Business Rule | Unit + Widget |
| TC-DEPOT-005 | Create Depot Stock Transfer Request | 1. In Depot Detail, tap "Request Stock"<br>2. Select destination depot and requested items<br>3. Submit request | Source: Sen Sok<br>Target: Chbar Ampov<br>Item: 20 bundles Pipe | Transfer request generated with status `Pending Dispatch`. Form validated. | Functional | Widget |
| TC-DEPOT-006 | Filter Stock by Steel Category | 1. On depot inventory page, tap category filter chips (Tubes, Sheets, Deformed Bars) | Category: "Roofing Sheets" | Inventory list instantly filters to show only selected category. Fast rendering. | UI / UX | Widget |
