# Quotations & RFQ: Test Cases

**Feature:** Quotations, Discount Approvals & PDF Generation  
**Package:** `isi_steel_sales_mobile/features/quotations`, `features/order/.../quotation`  
**Priority:** P1 (Sales Negotiation Flow)  
**Preconditions:** Sales rep logged in, customer selected.

| ID | Title | Steps | Test Data / Payload | Expected Result | Type | Automated Level |
|---|---|---|---|---|---|---|
| TC-QUOT-001 | Create New Quotation | 1. Navigate to Quotations<br>2. Tap "New Quotation"<br>3. Select customer & validity period (e.g., 7 days)<br>4. Add 2 steel line items | Customer: "Khmer Steel Depot"<br>Validity: 7 days | Quotation draft created with unique reference number (e.g. `QT-2026-00109`). Line totals calculated. | Functional | Widget + E2E |
| TC-QUOT-002 | Apply Standard Discount (Within Rep Limit) | 1. Enter custom line discount ≤ 3%<br>2. Save quotation | Discount: `2.5%` | Discount accepted without managerial escalation. Total recalculates with discount deducted. | Business Rule | Unit + Widget |
| TC-QUOT-003 | Apply High Discount (Requires Supervisor Approval) | 1. Enter discount > 5% (e.g., 8%)<br>2. Submit quotation | Discount: `8.0%` | Warning: "Discounts exceeding 5% require Sales Supervisor approval." Status transitions to `Pending Approval`. | Business Rule | Unit + Widget |
| TC-QUOT-004 | Supervisor Approves Quotation | 1. Supervisor logs in<br>2. Receives push notification<br>3. Reviews quote and taps "Approve" | Quote `QT-2026-00109` | Status updates to `Approved`. Rep receives push notification. Rep can now convert to order. | Workflow | Unit + Widget |
| TC-QUOT-005 | Supervisor Rejects Quotation with Reason | 1. Supervisor reviews quote<br>2. Taps "Reject"<br>3. Enters rejection reason | Reason: "Margin below minimum policy threshold." | Status updates to `Rejected`. Rejection notes visible to sales rep. Rep can duplicate and revise. | Workflow | Unit + Widget |
| TC-QUOT-006 | Generate & Preview Quotation PDF | 1. Open approved quotation<br>2. Tap "Export PDF" or "Preview PDF" | Approved quote | PDF document generated via `pdf` package. Includes ISI Steel official logo, customer info, itemized table, total in USD/KHR, payment terms, and signature block. | Reporting / UI | Widget + Manual |
| TC-QUOT-007 | Share Quotation PDF via Telegram / WhatsApp | 1. On PDF preview screen, tap Share icon<br>2. Select external app (Telegram/WhatsApp) | PDF file generated | Native OS share sheet opens with `application/pdf` mime type and generated file attached. | Integration | Manual |
| TC-QUOT-008 | Convert Quotation to Active Sales Order | 1. Open Approved quotation<br>2. Tap "Convert to Sales Order"<br>3. Confirm dialog | Approved Quote | Quotation converts into active Sales Order. Items, custom specs, agreed discounts transferred into Order Cart. Quote status changes to `Converted`. | Workflow | Unit + Widget + E2E |
| TC-QUOT-009 | Quotation Validity Expiry | 1. Open quotation where current date > expiry date | Expiry date: Yesterday | Status marked as `Expired`. "Convert to Order" button is disabled. Banner advises creating a new quote with current steel prices. | Business Rule | Unit |
