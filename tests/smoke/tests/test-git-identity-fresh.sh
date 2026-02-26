#!/usr/bin/env bash
# Scenario: No prior git identity — install.sh prompts and writes ~/.gitconfig.local.
# Verifies AC-001: prompted values are written and picked up by git config.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Provision: link dotfiles (required so ~/.gitconfig includes ~/.gitconfig.local)
# Pipe name + email answers to stdin to simulate interactive input.
# --force replaces /etc/skel skeleton files created by useradd -m.
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile base --dotfiles-only --force (with piped identity)"
printf "Test User\ntest@example.com\n" \
  | bash "${REPO_ROOT}/install.sh" --profile base --dotfiles-only --force

# ---------------------------------------------------------------------------
# AC-001: ~/.gitconfig.local exists and contains the [user] stanza
# ---------------------------------------------------------------------------
echo ""
echo "  Checking ~/.gitconfig.local was created..."

assert_file_exists "${HOME}/.gitconfig.local"

# ---------------------------------------------------------------------------
# AC-001: git config reads the entered values via the [include] in .gitconfig
# ---------------------------------------------------------------------------
echo ""
echo "  Checking git config reflects entered identity..."

assert_git_config "user.name"  "Test User"
assert_git_config "user.email" "test@example.com"

finish
