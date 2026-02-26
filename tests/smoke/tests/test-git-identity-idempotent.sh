#!/usr/bin/env bash
# Scenario: git identity already configured — second run skips the prompt.
# Verifies AC-002 (already-configured skip) and AC-004 (~/.gitconfig.local untouched).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# First run: link dotfiles and set identity via piped stdin.
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile base --dotfiles-only --force (first run)"
printf "Idempotent User\nidempotent@example.com\n" \
  | bash "${REPO_ROOT}/install.sh" --profile base --dotfiles-only --force

if [[ $? -eq 0 ]]; then
  _pass "First run exits 0"
else
  _fail "First run exited non-zero — cannot continue idempotency check"
  finish
fi

# Capture ~/.gitconfig.local content after first run.
local_config_after_first=$(cat "${HOME}/.gitconfig.local" 2>/dev/null || echo "")

# ---------------------------------------------------------------------------
# Second run: identity already set — prompt should be skipped.
# No piped stdin; install.sh should detect identity and skip without hanging.
# ---------------------------------------------------------------------------
echo ""
echo "  Running: install.sh --profile base --dotfiles-only (second run — idempotent)"

if bash "${REPO_ROOT}/install.sh" --profile base --dotfiles-only; then
  _pass "Second run exits 0 (idempotent)"
else
  _fail "Second run exited non-zero"
fi

# ---------------------------------------------------------------------------
# AC-004: ~/.gitconfig.local is left untouched (content unchanged).
# ---------------------------------------------------------------------------
echo ""
echo "  Checking ~/.gitconfig.local is unchanged after second run..."

local_config_after_second=$(cat "${HOME}/.gitconfig.local" 2>/dev/null || echo "")
if [[ "$local_config_after_first" == "$local_config_after_second" ]]; then
  _pass "~/.gitconfig.local unchanged after second run"
else
  _fail "~/.gitconfig.local was modified on second run"
fi

# ---------------------------------------------------------------------------
# AC-002: identity values still correct after second run.
# ---------------------------------------------------------------------------
echo ""
echo "  Checking git identity is still correct after second run..."

assert_git_config "user.name"  "Idempotent User"
assert_git_config "user.email" "idempotent@example.com"

finish
