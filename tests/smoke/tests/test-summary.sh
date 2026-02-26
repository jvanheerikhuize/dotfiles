#!/usr/bin/env bash
# Scenario: run summary is printed after a provisioning run.
# Verifies:
#   - Summary sections are present after a successful run (AC-001)
#   - Second run shows 0 installed (AC-002)
#   - --dry-run shows "Would install" / "Would link" labels (AC-004)
#   - --quiet suppresses per-step log lines but summary is still printed (AC-005)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# AC-001: first run — summary sections present
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile base --force (first run)"
output=$(bash "${REPO_ROOT}/install.sh" --profile base --force 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
  _pass "First run exits 0"
else
  _fail "First run exited ${exit_code}"
fi

for section in "Run Summary" "Packages — Installed" "Packages — skipped" \
               "Dotfiles — Linked" "Dotfiles — skipped" "Elapsed:"; do
  if echo "$output" | grep -q "$section"; then
    _pass "Summary contains: ${section}"
  else
    _fail "Summary missing: ${section}"
  fi
done

# ---------------------------------------------------------------------------
# AC-002: second run — idempotent; 0 packages installed
# ---------------------------------------------------------------------------
echo ""
echo "  Running: install.sh --profile base --force (second run — idempotent)"
output2=$(bash "${REPO_ROOT}/install.sh" --profile base --force 2>&1)
exit_code2=$?

if [[ $exit_code2 -eq 0 ]]; then
  _pass "Second run exits 0"
else
  _fail "Second run exited ${exit_code2}"
fi

if echo "$output2" | grep -q "Packages — Installed (0)"; then
  _pass "Second run: Packages — Installed (0)"
else
  _fail "Second run: expected 'Packages — Installed (0)' in summary"
fi

# ---------------------------------------------------------------------------
# AC-004: --dry-run shows "Would install" / "Would link" labels
# ---------------------------------------------------------------------------
echo ""
echo "  Running: install.sh --profile base --dry-run"
output_dry=$(bash "${REPO_ROOT}/install.sh" --profile base --dry-run 2>&1)
exit_code_dry=$?

if [[ $exit_code_dry -eq 0 ]]; then
  _pass "--dry-run exits 0"
else
  _fail "--dry-run exited ${exit_code_dry}"
fi

if echo "$output_dry" | grep -q "Would install"; then
  _pass "--dry-run summary contains 'Would install'"
else
  _fail "--dry-run summary missing 'Would install'"
fi

if echo "$output_dry" | grep -q "Would link"; then
  _pass "--dry-run summary contains 'Would link'"
else
  _fail "--dry-run summary missing 'Would link'"
fi

# ---------------------------------------------------------------------------
# AC-005: --quiet suppresses per-step log lines; summary still printed
# ---------------------------------------------------------------------------
echo ""
echo "  Running: install.sh --profile base --force --quiet"
output_quiet=$(bash "${REPO_ROOT}/install.sh" --profile base --force --quiet 2>&1)
exit_code_quiet=$?

if [[ $exit_code_quiet -eq 0 ]]; then
  _pass "--quiet exits 0"
else
  _fail "--quiet exited ${exit_code_quiet}"
fi

if echo "$output_quiet" | grep -q "Run Summary"; then
  _pass "--quiet: summary is still printed"
else
  _fail "--quiet: summary is missing"
fi

if ! echo "$output_quiet" | grep -q "\[INFO\]"; then
  _pass "--quiet: [INFO] lines suppressed"
else
  _fail "--quiet: [INFO] lines were not suppressed"
fi

finish
