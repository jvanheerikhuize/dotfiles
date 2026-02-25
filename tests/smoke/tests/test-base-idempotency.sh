#!/usr/bin/env bash
# Scenario: Running install.sh --profile base twice exits 0 both times.
# Verifies that the provisioner is fully idempotent (no duplicate installs,
# no broken symlinks on the second run).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# First run
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile base (first run)"

if bash "${REPO_ROOT}/install.sh" --profile base; then
  _pass "First run exits 0"
else
  _fail "First run exited non-zero — cannot continue idempotency check"
  finish
fi

# ---------------------------------------------------------------------------
# Second run (idempotency check)
# ---------------------------------------------------------------------------
echo ""
echo "  Running: install.sh --profile base (second run — idempotency)"

if bash "${REPO_ROOT}/install.sh" --profile base; then
  _pass "Second run exits 0 (idempotent)"
else
  _fail "Second run exited non-zero"
fi

# ---------------------------------------------------------------------------
# Verify dotfile symlinks are still correct after the second run
# ---------------------------------------------------------------------------
echo ""
echo "  Checking dotfile symlinks are intact after second run..."

DOTFILES_DIR="${REPO_ROOT}/dotfiles"
assert_symlink "${HOME}/.bashrc"       "${DOTFILES_DIR}/.bashrc"
assert_symlink "${HOME}/.bash_aliases" "${DOTFILES_DIR}/.bash_aliases"
assert_symlink "${HOME}/.bash_profile" "${DOTFILES_DIR}/.bash_profile"
assert_symlink "${HOME}/.gitconfig"    "${DOTFILES_DIR}/.gitconfig"

finish
