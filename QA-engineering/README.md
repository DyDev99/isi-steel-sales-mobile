# QA-engineering: Automated QA Kit for the SteelForce Flutter App

This kit gives a QA engineer, or an AI coding agent, one entry point for testing the app: `scripts/qa_agent.sh`. It runs static analysis, unit, widget and integration tests. It then writes a Markdown and JSON report that the agent reads to decide what to do next.

## What's inside

| Path | Purpose |
|---|---|
| `AGENTS.md` | Operating manual for the AI QA agent (rules, workflow, exit codes, report format) |
| `CLAUDE.md` | Pointer to `AGENTS.md` for Claude Code |
| `scripts/qa_agent.sh` | Single command runner: `doctor`, `analyze`, `unit`, `widget`, `integration`, `smoke`, `regression`, `all` |
| `scripts/report.py` | Converts `flutter test --machine` output into `reports/qa_report.md` + `reports/qa_summary.json` |
| `scripts/install.sh` | Copies the kit into your Flutter project and sets your package name |
| `test/unit/` | Unit tests (validators, use cases, BLoCs) |
| `test/widget/` | Widget tests (CustomerForm) |
| `test/helpers/` | Mocks, fakes and a `pumpApp` helper |
| `integration_test/` | E2E flows using the Robot pattern |
| `reference/lib/` | Minimal reference implementation the sample tests target |
| `qa/` | Manual QA: test cases, scenarios, regression suite, exploratory charters, device matrix, bug template, release checklist |
| `.github/workflows/qa.yml` | CI pipeline: analyze → unit/widget → coverage → report artifact |

## Quick start

```bash
# 1. Unzip next to (or inside) your Flutter project, then install:
./QA-engineering/scripts/install.sh /path/to/steelforce_app steelforce_app

# 2. From the Flutter project root:
./scripts/qa_agent.sh doctor        # checks toolchain + dependencies
./scripts/qa_agent.sh all           # analyze + unit + widget (+ coverage)
./scripts/qa_agent.sh integration emulator-5554
cat reports/qa_report.md
```

Add these to `pubspec.yaml` if `install.sh` reports them missing:

```yaml
dependencies:
  flutter_bloc: ^8.1.0
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
```

## About the reference code

The sample tests import from `package:<your_app>/features/customer/...`. `install.sh` copies `reference/lib` into your project **only for files that don't already exist**, so the kit runs out of the box. Once your real SteelForce classes exist, point the tests at them and delete any reference files you don't need.

## Test layout note

Flutter expects E2E tests in a top-level `integration_test/` folder, not `test/integration/`. This kit follows that convention. `test/` contains only unit and widget tests, which run without a device.

## Principle

- **Manual testing** discovers and validates real-world behaviour.
- **Automation** repeatedly verifies known behaviour quickly.
- **Unit tests** protect business logic.
- **Widget tests** protect UI components.
- **Integration/E2E tests** protect critical user journeys.
