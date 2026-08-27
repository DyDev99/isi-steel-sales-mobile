# Skills — How to build in this repository

> **Purpose:** reusable engineering knowledge. Rules, conventions, and technique
> that hold regardless of which feature you are working on.
> **Not here:** what the app is architected as (that is [../blueprint/](../blueprint/)),
> how one feature works ([../feature/](../feature/)), or why a decision was made
> ([../adr/](../adr/)).

---

## Read in this order

| # | Document | What it gives you |
|---|---|---|
| 1 | [engineering-standard.md](engineering-standard.md) | **The master rules.** Layering, naming, folder ownership, test tiers, coverage gates. Every other document implements this one. |
| 2 | [ai-engineering-playbook.md](ai-engineering-playbook.md) | The checklist-driven companion you keep open while writing code — feature/PR/review checklists, a full worked layering example, anti-patterns. |
| 3 | [feature-ui-standard.md](feature-ui-standard.md) | **Merge gate for anything a user can see or touch.** Security, no-crash stability, performance, responsive/adaptive, motion, visual language, calm UX, localization, accessibility, longevity. Its §14 checklist goes in the PR. |

---

## Reference by topic

| Topic | Document |
|---|---|
| Consuming the ISI API — envelope, interceptors, error mapping, retry | [api-integration.md](api-integration.md) |
| Security rules, OWASP MASVS mapping, logging redaction, release gates | [security.md](security.md) |
| Responsive and adaptive layout across phone / tablet / web | [responsive-and-adaptive-ui.md](responsive-and-adaptive-ui.md) |
| English + Khmer localization — adding strings, fonts, bilingual master data | [localization.md](localization.md) |
| Querying the codebase knowledge graph before you change shared code | [graphify.md](graphify.md) |
| Writing a new feature documentation package | [feature-documentation-template.md](feature-documentation-template.md) |

---

## Where the app-specific counterparts live

These topics are deliberately **not** duplicated here — the architecture is the
single source of truth for each:

| If you need… | Go to |
|---|---|
| State management (BLoC/Cubit) rules | [engineering-standard.md](engineering-standard.md) §4 |
| Local storage / Drift / DAO / encryption | [../blueprint/local-storage-architecture.md](../blueprint/local-storage-architecture.md) |
| Offline-first behaviour | [../blueprint/offline-architecture.md](../blueprint/offline-architecture.md) |
| Sync queue, retry, conflict resolution | [../blueprint/sync-architecture.md](../blueprint/sync-architecture.md) |
| Authentication and the protected-API gate | [../blueprint/authentication-architecture.md](../blueprint/authentication-architecture.md) |
| Navigation and routing | [../blueprint/navigation-architecture.md](../blueprint/navigation-architecture.md) |
| Device capabilities and permissions | [../blueprint/device-integration.md](../blueprint/device-integration.md) |
| Dependency injection wiring | [../blueprint/system-architecture.md](../blueprint/system-architecture.md) |
| Build, signing, CI/CD | [../release/](../release/) |

---

## Gaps

No document yet covers, and one would be worth writing:

- **Testing technique** — the *policy* (which tiers, what coverage) is in
  `engineering-standard.md` §10, but there is no guide to the fakes, fixtures,
  and `bloc_test`/`mocktail`/Drift-in-memory patterns the 107 existing test
  files already use consistently.
- **Error handling and validation** — the `Result` / typed-`Failure` convention
  is demonstrated in `ai-engineering-playbook.md`'s worked example but never
  stated as a rule of its own.
- **Debugging** — no guide to the DevTools, `graphify affected`, and
  redacted-logging workflow used here.
