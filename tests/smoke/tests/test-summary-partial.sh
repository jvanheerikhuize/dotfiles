#!/usr/bin/env bash
# Scenario: partial summary is printed when a run fails mid-way.
# Verifies:
#   - Exit code is non-zero when a command fails (AC-003)
#   - Summary is still printed even on failure (AC-003)
#   - Summary header reads "incomplete — error occurred" (AC-003)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Create a temporary profile with a custom command that always fails
# ---------------------------------------------------------------------------
TEMP_PROFILE="${REPO_ROOT}/profiles/failing-test.yaml"

cat > "$TEMP_PROFILE" <<'EOF'
profile:
  name: failing-test
  extends: null
packages:
  custom:
    - cmd: "exit 1"
      idempotency_check: ""
EOF

# ---------------------------------------------------------------------------
# Run with the failing profile
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile failing-test (expects failure)"
output=$(bash "${REPO_ROOT}/install.sh" --profile failing-test 2>&1)
exit_code=$?

# Clean up the temporary profile immediately after the run
rm -f "$TEMP_PROFILE"

# ---------------------------------------------------------------------------
# AC-003: exit code is non-zero
# ---------------------------------------------------------------------------
if [[ $exit_code -ne 0 ]]; then
  _pass "Failing run exits non-zero (exit_code=${exit_code})"
else
  _fail "Failing run should have exited non-zero, got 0"
fi

# AC-003: partial summary is printed
if echo "$output" | grep -q "Run Summary"; then
  _pass "Partial summary is printed on failure"
else
  _fail "Partial summary was not printed on failure"
fi

# AC-003: summary header reads "incomplete — error occurred"
if echo "$output" | grep -q "incomplete — error occurred"; then
  _pass "Summary header contains 'incomplete — error occurred'"
else
  _fail "Summary header does not contain 'incomplete — error occurred'"
fi

finish
