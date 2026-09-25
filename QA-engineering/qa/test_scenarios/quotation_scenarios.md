# Quotation & Approval: User Scenarios

| Scenario | Description | Priority | Automated Coverage | Manual Validation |
|---|---|---|---|---|
| SC-QUOT-01 | On-Site Quotation with Standard Pricing | Rep drafts quote on tablet with customer, previews branded PDF with ISI logo and terms, and shares via Telegram instantly. | P1 | Widget + E2E | Verify PDF layout on Android & iOS |
| SC-QUOT-02 | High-Volume Custom Discount Escalation | Customer requests 7% volume discount; app triggers supervisor approval workflow. Supervisor approves on mobile; rep receives push notification. | P1 | Unit + Widget | Multi-device approval verification |
| SC-QUOT-03 | Quotation Conversion to Active Order | After customer agrees to terms, rep taps "Convert to Order", retaining all agreed prices and lines without duplicate data entry. | P1 | E2E (`quotation_flow_test.dart`) | Verify ERP order conversion flag |
| SC-QUOT-04 | Expired Quotation Price Protection | Customer attempts to convert quote after 14-day validity period; system blocks conversion due to steel price index fluctuations. | P2 | Unit | Test with mock system clock |
