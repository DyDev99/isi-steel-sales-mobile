# Customer Feature: Scenarios

| Scenario | Description | Priority | Coverage |
|---|---|---|---|
| SC-CUST-01 | Sales rep creates a new customer during a site visit | P1 | E2E-CUST-001 |
| SC-CUST-02 | Rep creates a customer with no signal, then signal returns (offline → online sync) | P1 | Manual + future `offline_sync_test.dart` |
| SC-CUST-03 | Rep searches and updates an existing customer's credit limit | P1 | To automate |
| SC-CUST-04 | Rep without permission tries to change credit limit | P2 | Manual |
| SC-CUST-05 | Rep's session expires while filling a long form | P2 | Unit (message) + Manual |
| SC-CUST-06 | Location permission denied when tagging customer address | P2 | Manual |
