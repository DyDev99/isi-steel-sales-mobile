#!/usr/bin/env python3
"""Turn `flutter test --machine` JSON lines into reports/qa_report.md and qa_summary.json."""
import argparse, datetime, json, re, sys
from pathlib import Path

EXIT_MEANING = {0: "PASS", 1: "FAIL (test failures)", 2: "FAIL (static analysis)",
                3: "BLOCKED (environment)", 4: "FAIL (coverage below threshold)"}


def lcov_percent(path):
    found = hit = 0
    for line in Path(path).read_text().splitlines():
        if line.startswith("LF:"): found += int(line[3:])
        elif line.startswith("LH:"): hit += int(line[3:])
    return round(100.0 * hit / found, 1) if found else 0.0


def parse_suite(path):
    tests, errors, prints = {}, {}, {}
    for raw in path.read_text(errors="replace").splitlines():
        try:
            ev = json.loads(raw)
        except json.JSONDecodeError:
            continue
        t = ev.get("type")
        if t == "testStart":
            test = ev["test"]
            tests[test["id"]] = {"name": test["name"], "file": test.get("root_url") or test.get("url") or "",
                                 "line": test.get("root_line") or test.get("line"), "result": "running"}
        elif t == "testDone" and ev["testID"] in tests:
            rec = tests[ev["testID"]]
            if ev.get("hidden"):
                rec["hidden"] = True
            rec["result"] = "skipped" if ev.get("skipped") else ev.get("result", "unknown")
            rec["ms"] = ev.get("time")
        elif t == "error":
            errors.setdefault(ev["testID"], []).append(ev.get("error", "") + "\n" + ev.get("stackTrace", ""))
        elif t == "print":
            prints.setdefault(ev["testID"], []).append(ev.get("message", ""))
    rows = []
    for tid, rec in tests.items():
        if rec.get("hidden") and rec["result"] == "success":
            continue  # "loading x.dart" pseudo tests
        rec["errors"] = errors.get(tid, [])
        rec["case_ids"] = sorted(set(re.findall(r"TC-[A-Z]+-\d+", rec["name"])))
        rows.append(rec)
    return rows


def short(text, limit=1200):
    text = text.strip()
    return text if len(text) <= limit else text[:limit] + "\n... (truncated)"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="reports/raw")
    ap.add_argument("--out", default="reports")
    ap.add_argument("--exit-code", type=int, default=0)
    ap.add_argument("--coverage-only")
    a = ap.parse_args()

    if a.coverage_only:
        print(lcov_percent(a.coverage_only)); return

    raw, out = Path(a.raw), Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    suites = {p.stem: parse_suite(p) for p in sorted(raw.glob("*.jsonl")) if not p.stem.endswith(".firstrun")}
    cov_file = raw / "coverage.txt"
    coverage = float(cov_file.read_text().strip()) if cov_file.exists() else None
    analyze_file = raw / "analyze.txt"

    summary = {"generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
               "status": EXIT_MEANING.get(a.exit_code, f"exit {a.exit_code}"),
               "exit_code": a.exit_code, "coverage_percent": coverage, "suites": {}}
    failures = []
    for name, rows in suites.items():
        c = {k: sum(1 for r in rows if r["result"] == k) for k in ("success", "failure", "error", "skipped")}
        c["total"] = len(rows)
        summary["suites"][name] = c
        for r in rows:
            if r["result"] in ("failure", "error"):
                failures.append({"suite": name, **{k: r[k] for k in ("name", "file", "line", "case_ids")},
                                 "error": short("\n".join(r["errors"]))})
    summary["failures"] = failures
    if failures and summary["exit_code"] == 0:  # e.g. standalone `report` command
        summary["exit_code"], summary["status"] = 1, EXIT_MEANING[1]
    (out / "qa_summary.json").write_text(json.dumps(summary, indent=2))

    md = [f"# QA Report\n", f"**Result:** {summary['status']}  ", f"**Generated:** {summary['generated_at']}  "]
    if coverage is not None:
        md.append(f"**Line coverage:** {coverage}%  ")
    md += ["", "## Suites", "", "| Suite | Total | Passed | Failed | Errors | Skipped |", "|---|---|---|---|---|---|"]
    for name, c in summary["suites"].items():
        md.append(f"| {name} | {c['total']} | {c['success']} | {c['failure']} | {c['error']} | {c['skipped']} |")
    if not suites:
        md.append("| (no test results found) | - | - | - | - | - |")
    if analyze_file.exists() and a.exit_code == 2:
        md += ["", "## Static analysis output", "", "```", short(analyze_file.read_text(), 3000), "```"]
    md += ["", "## Failures", ""]
    if not failures:
        md.append("None.")
    for i, f in enumerate(failures, 1):
        loc = f"{f['file']}:{f['line']}" if f["line"] else f["file"]
        ids = f" (cases: {', '.join(f['case_ids'])})" if f["case_ids"] else ""
        md += [f"### {i}. [{f['suite']}] {f['name']}{ids}", f"`{loc}`", "", "```", f["error"] or "(no error text)", "```",
               "Triage bucket: _product bug / test bug / flaky / environment_  ", ""]
    md += ["", "## Agent checklist", "", "- [ ] Every failure triaged (see AGENTS.md section 4)",
           "- [ ] Bugs filed with qa/bug_reports/BUG_TEMPLATE.md", "- [ ] Open business questions listed"]
    (out / "qa_report.md").write_text("\n".join(md) + "\n")


if __name__ == "__main__":
    sys.exit(main())
