# Manual QA Workspace

| Folder | Contents |
|---|---|
| `test_cases/` | Step-by-step test cases with IDs (`TC-<FEATURE>-<NNN>`). Automated tests reuse these IDs in their names. |
| `test_scenarios/` | Higher-level user scenarios per feature |
| `regression/` | The regression suite: which cases run each release, and whether each is automated |
| `exploratory/` | Session charters and notes |
| `device_matrix/` | Supported devices and OS versions |
| `bug_reports/` | Bug template (and filed bugs if you keep them in-repo) |
| `release_checklist/` | Go/no-go checklist |

Rule: every automated test that covers a manual case includes the case ID in its test name, so `reports/qa_report.md` can map failures back here.
