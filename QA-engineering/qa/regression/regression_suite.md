# Regression Suite

Run the automated part on every pull request (CI) and the full suite before every release.

| Area | Case / Test | Priority | Automated | Command |
|---|---|---|---|---|
| Login | E2E-LOGIN-001 | P1 | ✅ E2E | `qa_agent.sh integration <device>` |
| Customer create | TC-CUST-001, 002, 011, 040 | P1 | ✅ Unit + Widget | `qa_agent.sh regression` |
| Customer create | E2E-CUST-001 | P1 | ✅ E2E | `qa_agent.sh integration <device>` |
| Customer validation | TC-CUST-010 to 021 | P1 | ✅ Unit | `qa_agent.sh unit` |
| Double submit | TC-CUST-030 | P1 | ✅ Unit | `qa_agent.sh unit` |
| Duplicate customer | TC-CUST-050 | P2 | ❌ Manual | — |
| Offline sync | SC-CUST-02 | P1 | ❌ Manual (automate next) | — |
| Quotation flow | TBD | P1 | ❌ | — |
| Visual quality / animations | all new screens | P2 | ❌ Manual | — |

## Smoke subset (run on every build, under 2 minutes)
Tests tagged `smoke`: `./scripts/qa_agent.sh smoke`
