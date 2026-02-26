#!/usr/bin/env bash
# Scenario: --non-interactive with no prior identity — prompt is skipped,
# a warning is emitted, and ~/.gitconfig.local is NOT created.
# Verifies AC-003.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Provision: link dotfiles in non-interactive mode (no stdin piped).
# --force replaces /etc/skel skeleton files created by useradd -m.
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile base --dotfiles-only --force --non-interactive"
output=$(bash "${REPO_ROOT}/install.sh" \
  --profile base --dotfiles-only --force --non-interactive 2>&1)
exit_code=$?

# ---------------------------------------------------------------------------
# AC-003: install.sh must exit 0 (warning, not an error).
# ---------------------------------------------------------------------------
if [[ $exit_code -eq 0 ]]; then
  _pass "--non-interactive exits 0"
else
  _fail "--non-interactive exited ${exit_code}"
fi

# ---------------------------------------------------------------------------
# AC-003: warning message present in output.
# ---------------------------------------------------------------------------
echo ""
echo "  Checking warning message is present..."

if echo "$output" | grep -q "Git identity not configured"; then
  _pass "Warning message present in output"
else
  _fail "Warning message not found in output"
fi

# ---------------------------------------------------------------------------
# AC-003: ~/.gitconfig.local must NOT be created.
# ---------------------------------------------------------------------------
echo ""
echo "  Checking ~/.gitconfig.local was NOT created..."

if [[ ! -f "${HOME}/.gitconfig.local" ]]; then
  _pass "~/.gitconfig.local was not created (as expected)"
else
  _fail "~/.gitconfig.local was created in --non-interactive mode"
fi

finish
