#!/usr/bin/env bash
# Scenario: validation detects structural errors in profile YAML.
# Tests AC-002 through AC-007:
#   AC-002: missing 'profile' key → exits 1 with correct error
#   AC-003: non-existent extends reference → exits 1 with 'not found'
#   AC-004: circular extends → exits 1 with 'circular extends detected'
#   AC-005: packages.apt is a string not a list → exits 1 with correct error
#   AC-007: multiple errors collected and reported before exit
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

PROFILES_DIR="${REPO_ROOT}/profiles"

# Ensure temp profiles are removed even if the test fails
cleanup() {
  rm -f \
    "${PROFILES_DIR}/test-no-profile-key.yaml" \
    "${PROFILES_DIR}/test-bad-extends.yaml" \
    "${PROFILES_DIR}/test-circ-a.yaml" \
    "${PROFILES_DIR}/test-circ-b.yaml" \
    "${PROFILES_DIR}/test-bad-pkgtype.yaml" \
    "${PROFILES_DIR}/test-multi-error.yaml"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# AC-002: Missing 'profile' key
# ---------------------------------------------------------------------------
echo "  Testing: missing 'profile' key (AC-002)..."

cat > "${PROFILES_DIR}/test-no-profile-key.yaml" << 'EOF'
packages:
  apt:
    - curl
EOF

output=$(bash "${REPO_ROOT}/install.sh" --profile test-no-profile-key --validate-only 2>&1)
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
  _pass "AC-002: missing profile key exits non-zero"
else
  _fail "AC-002: missing profile key should exit non-zero"
fi

if echo "$output" | grep -q "missing required key: profile"; then
  _pass "AC-002: correct error message for missing profile key"
else
  _fail "AC-002: wrong output (expected 'missing required key: profile'): ${output}"
fi

rm -f "${PROFILES_DIR}/test-no-profile-key.yaml"

# ---------------------------------------------------------------------------
# AC-003: Non-existent extends reference
# ---------------------------------------------------------------------------
echo ""
echo "  Testing: non-existent extends reference (AC-003)..."

cat > "${PROFILES_DIR}/test-bad-extends.yaml" << 'EOF'
profile:
  name: test-bad-extends
  extends: this-profile-does-not-exist
packages:
  apt: []
EOF

output=$(bash "${REPO_ROOT}/install.sh" --profile test-bad-extends --validate-only 2>&1)
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
  _pass "AC-003: bad extends exits non-zero"
else
  _fail "AC-003: bad extends should exit non-zero"
fi

if echo "$output" | grep -q 'not found'; then
  _pass "AC-003: 'not found' in error message"
else
  _fail "AC-003: wrong output (expected 'not found'): ${output}"
fi

if echo "$output" | grep -q 'referenced by'; then
  _pass "AC-003: 'referenced by' in error message"
else
  _fail "AC-003: wrong output (expected 'referenced by'): ${output}"
fi

rm -f "${PROFILES_DIR}/test-bad-extends.yaml"

# ---------------------------------------------------------------------------
# AC-004: Circular extends
# ---------------------------------------------------------------------------
echo ""
echo "  Testing: circular extends (AC-004)..."

cat > "${PROFILES_DIR}/test-circ-a.yaml" << 'EOF'
profile:
  name: test-circ-a
  extends: test-circ-b
packages:
  apt: []
EOF

cat > "${PROFILES_DIR}/test-circ-b.yaml" << 'EOF'
profile:
  name: test-circ-b
  extends: test-circ-a
packages:
  apt: []
EOF

output=$(bash "${REPO_ROOT}/install.sh" --profile test-circ-a --validate-only 2>&1)
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
  _pass "AC-004: circular extends exits non-zero"
else
  _fail "AC-004: circular extends should exit non-zero"
fi

if echo "$output" | grep -q 'circular extends detected'; then
  _pass "AC-004: 'circular extends detected' in error message"
else
  _fail "AC-004: wrong output (expected 'circular extends detected'): ${output}"
fi

rm -f "${PROFILES_DIR}/test-circ-a.yaml" "${PROFILES_DIR}/test-circ-b.yaml"

# ---------------------------------------------------------------------------
# AC-005: Non-list packages.apt value
# ---------------------------------------------------------------------------
echo ""
echo "  Testing: non-list packages.apt value (AC-005)..."

cat > "${PROFILES_DIR}/test-bad-pkgtype.yaml" << 'EOF'
profile:
  name: test-bad-pkgtype
  extends: null
packages:
  apt: "this-should-be-a-list"
EOF

output=$(bash "${REPO_ROOT}/install.sh" --profile test-bad-pkgtype --validate-only 2>&1)
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
  _pass "AC-005: non-list packages.apt exits non-zero"
else
  _fail "AC-005: non-list packages.apt should exit non-zero"
fi

if echo "$output" | grep -q 'packages.apt must be a list'; then
  _pass "AC-005: correct error message for non-list packages.apt"
else
  _fail "AC-005: wrong output (expected 'packages.apt must be a list'): ${output}"
fi

rm -f "${PROFILES_DIR}/test-bad-pkgtype.yaml"

# ---------------------------------------------------------------------------
# AC-007: Multiple errors reported together
# ---------------------------------------------------------------------------
echo ""
echo "  Testing: multiple errors reported together (AC-007)..."

cat > "${PROFILES_DIR}/test-multi-error.yaml" << 'EOF'
profile:
  name: test-multi-error
  extends: null
packages:
  apt: "should-be-a-list"
  snap: 42
EOF

output=$(bash "${REPO_ROOT}/install.sh" --profile test-multi-error --validate-only 2>&1)
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
  _pass "AC-007: multiple errors exits non-zero"
else
  _fail "AC-007: multiple errors should exit non-zero"
fi

apt_err=$(echo "$output" | grep -c 'packages.apt must be a list' || true)
snap_err=$(echo "$output" | grep -c 'packages.snap must be a list' || true)

if [[ $apt_err -ge 1 && $snap_err -ge 1 ]]; then
  _pass "AC-007: both apt and snap errors reported together"
else
  _fail "AC-007: expected both apt and snap errors, got: ${output}"
fi

rm -f "${PROFILES_DIR}/test-multi-error.yaml"

finish
