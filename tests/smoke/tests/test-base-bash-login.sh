#!/usr/bin/env bash
# Scenario: bash --login exits 0 after dotfiles are linked.
# Verifies there are no syntax errors in .bash_profile or .bashrc.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Provision: dotfiles only
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile base --dotfiles-only --force"
bash "${REPO_ROOT}/install.sh" --profile base --dotfiles-only --force

# ---------------------------------------------------------------------------
# Assert bash --login exits 0 (no syntax errors in .bash_profile or .bashrc)
# bash --login -c exit is a login, non-interactive shell:
#   - sources /etc/profile and ~/.bash_profile
#   - ~/.bash_profile sources ~/.bashrc
#   - ~/.bashrc returns early (non-interactive guard) but must not have errors
# ---------------------------------------------------------------------------
echo ""
echo "  Checking bash --login exits 0..."

assert_cmd_success "bash --login -c exit exits 0" bash --login -c exit

# ---------------------------------------------------------------------------
# Assert bash syntax check passes for both files
# ---------------------------------------------------------------------------
echo ""
echo "  Checking bash syntax..."

assert_cmd_success ".bash_profile passes bash -n" bash -n "${HOME}/.bash_profile"
assert_cmd_success ".bashrc passes bash -n"        bash -n "${HOME}/.bashrc"
assert_cmd_success ".bash_aliases passes bash -n"  bash -n "${HOME}/.bash_aliases"

finish
