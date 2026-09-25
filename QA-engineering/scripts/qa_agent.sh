#!/usr/bin/env bash
# QA agent runner for ISI Steel Sales Mobile Flutter App.
# Usage: ./scripts/qa_agent.sh <command> [device_id]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect Flutter Project Root & QA Directory
if [ -f "$SCRIPT_DIR/../../pubspec.yaml" ]; then
  ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
  QA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [ -f "$SCRIPT_DIR/../pubspec.yaml" ]; then
  ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  QA_DIR="$ROOT/QA-engineering"
elif [ -f "$PWD/pubspec.yaml" ]; then
  ROOT="$PWD"
  QA_DIR="$ROOT/QA-engineering"
else
  ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  QA_DIR="$ROOT"
fi

cd "$ROOT"

REPORT_DIR="${QA_REPORT_DIR:-$QA_DIR/reports}"
RAW_DIR="$REPORT_DIR/raw"
MIN_COVERAGE="${QA_MIN_COVERAGE:-50}"
RETRY="${QA_RETRY:-0}"
PYTHON="${PYTHON:-python3}"
mkdir -p "$RAW_DIR"

EXIT_OK=0; EXIT_TEST_FAIL=1; EXIT_ANALYZE_FAIL=2; EXIT_ENV=3; EXIT_COVERAGE=4
FINAL=0

log()  { printf '\033[1;34m[qa]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[qa]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[qa]\033[0m %s\n' "$*" >&2; }
set_exit() { [ "$FINAL" -eq 0 ] && FINAL="$1"; }   # keep first failure code

usage() { 
  echo "ISI Steel QA Runner"
  echo "Usage: ./QA-engineering/scripts/qa_agent.sh <command> [device_id]"
  echo "Commands: doctor analyze unit widget smoke regression integration all report"
}

doctor() {
  log "Checking environment for ISI Steel Sales Mobile"
  local ok=1
  for bin in flutter dart "$PYTHON"; do
    if command -v "$bin" >/dev/null 2>&1; then log "found $bin"; else err "missing $bin"; ok=0; fi
  done
  [ -f pubspec.yaml ] || { err "pubspec.yaml not found at $ROOT."; ok=0; }
  if [ -f pubspec.yaml ]; then
    for dep in flutter_test bloc_test mocktail flutter_bloc equatable; do
      grep -qE "^\s+$dep:" pubspec.yaml && log "dependency $dep ok" || { warn "dependency $dep not in pubspec.yaml"; ok=0; }
    done
    if grep -qE "^\s+integration_test:" pubspec.yaml; then
      log "dependency integration_test ok"
    else
      warn "dependency integration_test not declared under dev_dependencies in pubspec.yaml"
    fi
  fi
  if [ "$ok" -eq 1 ]; then flutter pub get >/dev/null 2>&1 || { err "flutter pub get failed"; ok=0; }; fi
  [ "$ok" -eq 1 ] || { set_exit $EXIT_ENV; return 1; }
  log "Environment OK (Workspace: $ROOT)"
}

analyze() {
  log "Static analysis on ISI Steel codebase"
  flutter analyze --no-fatal-infos > "$RAW_DIR/analyze.txt" 2>&1
  local a=$?
  dart format --output=none --set-exit-if-changed lib test > "$RAW_DIR/format.txt" 2>&1
  local f=$?
  if [ $a -ne 0 ] || [ $f -ne 0 ]; then
    warn "analyze=$a format=$f (inspect $RAW_DIR/analyze.txt, $RAW_DIR/format.txt)"
    # We do not block entirely on styling formatting if analyze is clean
    if [ $a -ne 0 ]; then set_exit $EXIT_ANALYZE_FAIL; return 1; fi
  fi
  log "Analysis completed"
}

# run_suite <name> <flutter test args...>
run_suite() {
  local name="$1"; shift
  local out="$RAW_DIR/$name.jsonl"
  log "Running $name: flutter test $*"
  flutter test --machine "$@" > "$out" 2> "$RAW_DIR/$name.stderr"
  local rc=$?
  if [ $rc -ne 0 ] && [ "$RETRY" -gt 0 ]; then
    warn "$name failed; retrying once to detect flakiness"
    cp "$out" "$RAW_DIR/$name.firstrun.jsonl"
    flutter test --machine "$@" > "$out" 2> "$RAW_DIR/$name.stderr"
    rc=$?
    [ $rc -eq 0 ] && warn "$name passed on retry: possible FLAKY tests (compare $name.firstrun.jsonl)"
  fi
  if [ $rc -ne 0 ]; then
    if [ ! -s "$out" ]; then err "$name produced no output (tooling issue)"; set_exit $EXIT_ENV
    else err "$name has test failures"; set_exit $EXIT_TEST_FAIL; fi
  else log "$name passed successfully"; fi
  return $rc
}

coverage() {
  local lcov="coverage/lcov.info"
  [ -f "$lcov" ] || { warn "no coverage file found at $lcov"; return 0; }
  local pct
  pct=$("$PYTHON" "$QA_DIR/scripts/report.py" --coverage-only "$lcov" 2>/dev/null || echo "0")
  echo "$pct" > "$RAW_DIR/coverage.txt"
  log "Line coverage: ${pct}% (minimum threshold: ${MIN_COVERAGE}%)"
}

report() {
  if [ -f "$QA_DIR/scripts/report.py" ]; then
    "$PYTHON" "$QA_DIR/scripts/report.py" --raw "$RAW_DIR" --out "$REPORT_DIR" --exit-code "$FINAL" 2>/dev/null \
      && log "Report generated: $REPORT_DIR/qa_report.md" || warn "Report generation encountered a notice."
  fi
}

integration() {
  local device="${1:-${QA_DEVICE:-}}"
  if [ -z "$device" ]; then err "no device. Use: integration <device_id> or set QA_DEVICE (run: flutter devices)"; set_exit $EXIT_ENV; return 1; fi
  local target_dir="integration_test"
  if [ ! -d "$target_dir" ] && [ -d "$QA_DIR/integration_test" ]; then
    target_dir="$QA_DIR/integration_test"
  fi
  run_suite integration "$target_dir" -d "$device" \
    --dart-define=QA_BASE_URL="${QA_BASE_URL:-https://api-staging.isisteel.com.kh}" \
    --dart-define=QA_USERNAME="${QA_USERNAME:-test_sales_rep}" \
    --dart-define=QA_PASSWORD="${QA_PASSWORD:-test_pass}"
}

cmd="${1:-}"; shift || true
[ "$cmd" = "report" ] || rm -f "$RAW_DIR"/*.jsonl "$RAW_DIR"/coverage.txt 2>/dev/null

# Select test target path (supports root test/ structure)
resolve_test_path() {
  local target="$1"
  if [ -d "test/$target" ]; then echo "test/$target";
  elif [ -d "$QA_DIR/test/$target" ]; then echo "$QA_DIR/test/$target";
  else echo "test"; fi
}

case "$cmd" in
  doctor)      doctor ;;
  analyze)     analyze ;;
  unit)        run_suite unit "$(resolve_test_path features)" ;;
  widget)      run_suite widget "$(resolve_test_path widget)" ;;
  smoke)       analyze; run_suite smoke test --tags smoke 2>/dev/null || run_suite smoke test/core ;;
  regression)  analyze; run_suite regression test ;;
  integration) integration "${1:-}" ;;
  all)         doctor || { report; exit $FINAL; }
               analyze
               run_suite regression test
               if [ -n "${QA_DEVICE:-}" ]; then integration "$QA_DEVICE"; else warn "QA_DEVICE not set: skipping integration"; fi ;;
  report)      ;;
  *)           usage; exit $EXIT_ENV ;;
esac

[ "$cmd" = "doctor" ] || report
exit $FINAL
