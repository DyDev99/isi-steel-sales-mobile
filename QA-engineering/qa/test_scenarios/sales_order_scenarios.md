# Sales Order & Cart: User Scenarios

| Scenario | Description | Priority | Automated Coverage | Manual Validation |
|---|---|---|---|---|
| SC-ORD-01 | Standard On-Site Steel Order | Rep configures custom length steel sheets with wholesale customer, applies approved discount, and submits confirmed order. | P1 | E2E Robot (`order_flow_test.dart`) + Unit | Verify physical ERP invoice matching |
| SC-ORD-02 | Low Signal / Intermittent Field Order | Rep enters a customer order in rural warehouse with fluctuating EDGE network; order queues in local Outbox and syncs without duplicating when 4G returns. | P1 | Unit (`offline_sync_test.dart`) | Test during real field trip |
| SC-ORD-03 | Credit Limit Exceeded Escalation | Customer's credit balance is near limit; placing large steel order triggers automatic manager review workflow instead of silent failure. | P1 | Unit + Widget | Verify credit manager dashboard sync |
| SC-ORD-04 | Rapid Double-Tap Cart Submission | Rep on slow connection double or triple taps "Submit" button; UI guards ensure only a single transaction reaches SAP. | P1 | Widget + Unit | Verify in database transaction logs |
| SC-ORD-05 | Custom Spec Conversion & Weight Calculation | Rep enters dimensions (width, height, thickness in mm, length in meters) and system accurately converts to weight (MT) and price per kg. | P2 | Unit | Formula verification against ISI technical handbook |
