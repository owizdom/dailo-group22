#!/usr/bin/env bash
# The gate. Every line below must pass before any work counts as done.
#   1. dart format changes nothing
#   2. flutter analyze reports 0 issues
#   3. no setState in lib/, no Firebase import in presentation/ or domain/
#   4. tests: more than 0 ran, 0 skipped, all passed
#   5. line coverage of lib/ is at least 70% (firebase_options.dart excluded)
# Usage: tool/check.sh            run everything
#        MIN_COVERAGE=0 tool/check.sh   skip the coverage floor (early waves)
set -u
cd "$(dirname "$0")/.."
MIN_COVERAGE="${MIN_COVERAGE:-70}"
fail() { echo "GATE FAIL: $1"; exit 1; }

echo "== 1. format"
dart format --output=none --set-exit-if-changed lib test >/dev/null || fail "dart format would change files"

echo "== 2. analyze"
flutter analyze --no-pub || fail "flutter analyze reported issues"

echo "== 3. architecture rules"
if grep -rn "setState(" lib/ ; then fail "setState found in lib/"; fi
if grep -rnE "package:(cloud_firestore|firebase_auth|firebase_core|google_sign_in)" lib/presentation lib/domain ; then
  fail "Firebase import outside the data layer"
fi

echo "== 4. tests"
out="$(flutter test --no-pub --coverage 2>&1)"; status=$?
summary="$(printf '%s\n' "$out" | tr '\r' '\n' | grep -E '^[0-9]+:[0-9]+ \+[0-9]+' | tail -1)"
echo "$summary"
passed="$(printf '%s' "$summary" | sed -nE 's/.*\+([0-9]+).*/\1/p')"
skipped="$(printf '%s' "$summary" | sed -nE 's/.*~([0-9]+).*/\1/p')"
[ "$status" -eq 0 ] || { printf '%s\n' "$out" | tail -40; fail "tests failed"; }
[ "${passed:-0}" -gt 0 ] || fail "0 tests ran"
[ "${skipped:-0}" -eq 0 ] || fail "${skipped} tests skipped"

echo "== 5. coverage"
# Flutter leaves a file out of the report unless a test loads it, which would
# inflate the percentage. test/coverage_imports_test.dart loads them all, so
# every file under lib/ must be imported there. (Files with nothing to run,
# such as abstract interfaces, still never appear in the report; that is fine.)
missing=0
for f in $(find lib -name '*.dart' | sort); do
  grep -q "package:dailo/${f#lib/}'" test/coverage_imports_test.dart || { echo "not imported: $f"; missing=1; }
done
[ "$missing" -eq 0 ] || fail "add the files above to test/coverage_imports_test.dart"
pct="$(awk -F: '
  /^SF:/ { skip = ($0 ~ /firebase_options\.dart$/) }
  /^LF:/ && !skip { total += $2 }
  /^LH:/ && !skip { hit += $2 }
  END { if (total == 0) print 0; else printf "%.1f", hit * 100 / total }' coverage/lcov.info)"
echo "line coverage: ${pct}% (floor ${MIN_COVERAGE}%)"
awk -v p="$pct" -v m="$MIN_COVERAGE" 'BEGIN { exit (p + 0 >= m + 0) ? 0 : 1 }' || fail "coverage ${pct}% is under ${MIN_COVERAGE}%"

echo "GATE PASS: ${passed} tests, 0 skipped, coverage ${pct}%"
