#!/usr/bin/env bash
# Scenario: --dry-run makes no changes and exits 0.
# Verifies:
#   - Exit code is 0 (AC-001)
#   - No packages are installed (AC-001)
#   - No symlinks are created in $HOME (AC-001)
#   - Output contains [DRY RUN] prefix lines (AC-002, AC-003)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Baseline: record package count before dry-run
# ---------------------------------------------------------------------------
pkg_count_before=$(dpkg --get-selections | wc -l)

echo "  Running: install.sh --profile base --dry-run"
output=$(bash "${REPO_ROOT}/install.sh" --profile base --dry-run 2>&1)
exit_code=$?

# ---------------------------------------------------------------------------
# AC-001: exits 0
# ---------------------------------------------------------------------------
if [[ $exit_code -eq 0 ]]; then
  _pass "--dry-run exits 0"
else
  _fail "--dry-run exited with code ${exit_code}"
fi

# ---------------------------------------------------------------------------
# AC-001: No packages installed
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
# AC-001: No symlinks created in $HOME
# ---------------------------------------------------------------------------
echo ""
echo "  Checking no symlinks were created in HOME..."

while IFS= read -r -d '' file; do
  relative="${file#"${REPO_ROOT}/dotfiles/"}"
  dest="${HOME}/${relative}"
  if [[ -L "$dest" ]]; then
    _fail "Symlink was created during dry-run: ${dest}"
  else
    _pass "No symlink created (as expected): ${dest}"
  fi
done < <(find "${REPO_ROOT}/dotfiles" -not -name '.gitkeep' -type f -print0)

# ---------------------------------------------------------------------------
# AC-002/AC-003: Output contains [DRY RUN] prefix
# ---------------------------------------------------------------------------
echo ""
echo "  Checking output contains [DRY RUN] lines..."

if echo "$output" | grep -q "\[DRY RUN\]"; then
  _pass "Output contains [DRY RUN] prefix lines"
else
  _fail "Output does not contain any [DRY RUN] prefix lines"
fi

finish
