#!/usr/bin/env bash
# QA agent runner for Flutter. Usage: ./scripts/qa_agent.sh <command> [device_id]
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REPORT_DIR="${QA_REPORT_DIR:-reports}"
RAW_DIR="$REPORT_DIR/raw"
MIN_COVERAGE="${QA_MIN_COVERAGE:-60}"
RETRY="${QA_RETRY:-0}"
PYTHON="${PYTHON:-python3}"
mkdir -p "$RAW_DIR"

EXIT_OK=0; EXIT_TEST_FAIL=1; EXIT_ANALYZE_FAIL=2; EXIT_ENV=3; EXIT_COVERAGE=4
FINAL=0

log()  { printf '\033[1;34m[qa]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[qa]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[qa]\033[0m %s\n' "$*" >&2; }
set_exit() { [ "$FINAL" -eq 0 ] && FINAL="$1"; }   # keep first failure code

usage() { sed -n '2,3p' "$0"; echo "Commands: doctor analyze unit widget smoke regression integration all report"; }

doctor() {
  log "Checking environment"
  local ok=1
  for bin in flutter dart "$PYTHON"; do
    if command -v "$bin" >/dev/null 2>&1; then log "found $bin"; else err "missing $bin"; ok=0; fi
  done
  [ -f pubspec.yaml ] || { err "pubspec.yaml not found. Run from the Flutter project root."; ok=0; }
  if [ -f pubspec.yaml ]; then
    for dep in flutter_test integration_test bloc_test mocktail flutter_bloc equatable; do
      grep -qE "^\s+$dep:" pubspec.yaml && log "dependency $dep ok" || { warn "dependency $dep not in pubspec.yaml"; ok=0; }
    done
  fi
  if [ "$ok" -eq 1 ]; then flutter pub get >/dev/null 2>&1 || { err "flutter pub get failed"; ok=0; }; fi
  [ "$ok" -eq 1 ] || { set_exit $EXIT_ENV; return 1; }
  log "Environment OK"
}

analyze() {
  log "Static analysis"
  flutter analyze --no-fatal-infos > "$RAW_DIR/analyze.txt" 2>&1
  local a=$?
  dart format --output=none --set-exit-if-changed lib test integration_test > "$RAW_DIR/format.txt" 2>&1
  local f=$?
  if [ $a -ne 0 ] || [ $f -ne 0 ]; then
    err "analyze=$a format=$f (see $RAW_DIR/analyze.txt, $RAW_DIR/format.txt)"
    set_exit $EXIT_ANALYZE_FAIL; return 1
  fi
  log "Analysis clean"
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
    else err "$name has failures"; set_exit $EXIT_TEST_FAIL; fi
  else log "$name passed"; fi
  return $rc
}

coverage() {
  local lcov="coverage/lcov.info"
  [ -f "$lcov" ] || { warn "no coverage file"; return 0; }
  local pct
  pct=$("$PYTHON" "$ROOT/scripts/report.py" --coverage-only "$lcov")
  echo "$pct" > "$RAW_DIR/coverage.txt"
  log "Line coverage: ${pct}% (minimum ${MIN_COVERAGE}%)"
  if "$PYTHON" -c "import sys; sys.exit(0 if float('$pct') >= float('$MIN_COVERAGE') else 1)"; then :; else
    err "coverage below threshold"; set_exit $EXIT_COVERAGE
  fi
}

report() {
  "$PYTHON" "$ROOT/scripts/report.py" --raw "$RAW_DIR" --out "$REPORT_DIR" --exit-code "$FINAL" \
    && log "Report: $REPORT_DIR/qa_report.md"
}

integration() {
  local device="${1:-${QA_DEVICE:-}}"
  if [ -z "$device" ]; then err "no device. Use: integration <device_id> or set QA_DEVICE (see: flutter devices)"; set_exit $EXIT_ENV; return 1; fi
  if [ ! -d integration_test ]; then err "integration_test/ folder missing"; set_exit $EXIT_ENV; return 1; fi
  run_suite integration integration_test -d "$device" \
    --dart-define=QA_BASE_URL="${QA_BASE_URL:-}" \
    --dart-define=QA_USERNAME="${QA_USERNAME:-}" \
    --dart-define=QA_PASSWORD="${QA_PASSWORD:-}"
}

cmd="${1:-}"; shift || true
[ "$cmd" = "report" ] || rm -f "$RAW_DIR"/*.jsonl "$RAW_DIR"/coverage.txt 2>/dev/null
case "$cmd" in
  doctor)      doctor ;;
  analyze)     analyze ;;
  unit)        run_suite unit test/unit ;;
  widget)      run_suite widget test/widget ;;
  smoke)       analyze; run_suite smoke test --tags smoke ;;
  regression)  analyze; run_suite unit_widget test --coverage; coverage ;;
  integration) integration "${1:-}" ;;
  all)         doctor || { report; exit $FINAL; }
               analyze; run_suite unit_widget test --coverage; coverage
               if [ -n "${QA_DEVICE:-}" ]; then integration "$QA_DEVICE"; else warn "QA_DEVICE not set: skipping integration"; fi ;;
  report)      ;;
  *)           usage; exit $EXIT_ENV ;;
esac

[ "$cmd" = "doctor" ] || report
exit $FINAL
