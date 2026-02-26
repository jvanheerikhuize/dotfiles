#!/usr/bin/env bash
# Scenario: src/setup-git-identity.sh works when run standalone (without install.sh).
# Verifies AC-006.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Pre-condition: link dotfiles so ~/.gitconfig includes ~/.gitconfig.local.
# Without this, git config --global user.name won't reflect values from the
# local file even after it is written.
# --force replaces /etc/skel skeleton files created by useradd -m.
# ---------------------------------------------------------------------------
echo "  Pre-condition: linking dotfiles (--dotfiles-only --force --non-interactive)"
bash "${REPO_ROOT}/install.sh" \
  --profile base --dotfiles-only --force --non-interactive

# ---------------------------------------------------------------------------
# AC-006: run setup-git-identity.sh standalone with piped stdin.
# ---------------------------------------------------------------------------
echo ""
echo "  Running: src/setup-git-identity.sh standalone (with piped identity)"
printf "Standalone User\nstandalone@example.com\n" \
  | bash "${REPO_ROOT}/src/setup-git-identity.sh"

# ---------------------------------------------------------------------------
# AC-006: ~/.gitconfig.local exists.
# ---------------------------------------------------------------------------
echo ""
echo "  Checking ~/.gitconfig.local was created..."

assert_file_exists "${HOME}/.gitconfig.local"

# ---------------------------------------------------------------------------
# AC-006: git config reflects the values entered to the standalone script.
# ---------------------------------------------------------------------------
echo ""
echo "  Checking git config reflects identity from standalone run..."

assert_git_config "user.name"  "Standalone User"
assert_git_config "user.email" "standalone@example.com"

finish
