# Offline Resilience & Sync: User Scenarios

| Scenario | Description | Priority | Automated Coverage | Manual Validation |
|---|---|---|---|---|
| SC-SYNC-01 | Full Day Provincial Field Trip Offline | Rep works in rural province with no network for 6 hours; browses catalog, prepares 3 orders and 4 visit check-ins locally; all sync upon returning to 4G coverage. | P1 | Unit + Integration | Device Airplane mode endurance test |
| SC-SYNC-02 | Network Interruption Mid-Payment/Submit | Cellular drop during HTTP POST submission of order; app handles timeout gracefully without creating orphaned orders or hanging UI. | P1 | Unit + Widget | Proxy packet drop simulation |
| SC-SYNC-03 | Concurrent Price Change Conflict Resolution | ERP updates price of steel coil while rep is offline drafting an order; upon sync, app warns rep of discrepancy before final confirmation. | P1 | Unit | Test with mock ERP responses |
| SC-SYNC-04 | Sudden App Force Quit Mid-Entry | OS terminates app due to low memory while rep is filling long order form; app restores state from local draft without data loss. | P2 | Widget + Unit | Process kill in background test |
