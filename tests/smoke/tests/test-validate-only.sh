#!/usr/bin/env bash
# Scenario: --validate-only exits 0 and prints "Validation passed" for a valid profile.
# Verifies:
#   - Exit code is 0 (AC-006)
#   - Output contains "Validation passed" (AC-006)
#   - No packages are installed (AC-006)
#   - No symlinks are created in $HOME (AC-006)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Baseline: record package count before --validate-only
# ---------------------------------------------------------------------------
pkg_count_before=$(dpkg --get-selections | wc -l)

echo "  Running: install.sh --profile base --validate-only"
output=$(bash "${REPO_ROOT}/install.sh" --profile base --validate-only 2>&1)
exit_code=$?

# ---------------------------------------------------------------------------
# AC-006: exits 0
# ---------------------------------------------------------------------------
if [[ $exit_code -eq 0 ]]; then
  _pass "--validate-only exits 0 for valid profile"
else
  _fail "--validate-only exited with code ${exit_code}"
fi

# ---------------------------------------------------------------------------
# AC-006: output contains "Validation passed"
# ---------------------------------------------------------------------------
if echo "$output" | grep -q "Validation passed"; then
  _pass "Output contains 'Validation passed'"
else
  _fail "Output does not contain 'Validation passed': ${output}"
fi

# ---------------------------------------------------------------------------
# AC-006: no packages installed
# ---------------------------------------------------------------------------
echo ""
echo "  Checking no packages were installed..."

pkg_count_after=$(dpkg --get-selections | wc -l)
if [[ "$pkg_count_before" -eq "$pkg_count_after" ]]; then
  _pass "Package count unchanged (${pkg_count_after})"
else
  _fail "Package count changed: before=${pkg_count_before} after=${pkg_count_after}"
fi

# ---------------------------------------------------------------------------
# AC-006: no symlinks created in $HOME
# ---------------------------------------------------------------------------
echo ""
echo "  Checking no symlinks were created in HOME..."

while IFS= read -r -d '' file; do
  relative="${file#"${REPO_ROOT}/dotfiles/"}"
  dest="${HOME}/${relative}"
  if [[ -L "$dest" ]]; then
    _fail "Symlink was created during --validate-only: ${dest}"
  else
    _pass "No symlink created (as expected): ${dest}"
  fi
done < <(find "${REPO_ROOT}/dotfiles" -not -name '.gitkeep' -type f -print0)

finish
