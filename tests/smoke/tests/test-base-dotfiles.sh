#!/usr/bin/env bash
# Scenario: Dotfile symlinks are created in $HOME after running
# install.sh --profile base --dotfiles-only --force.
# --force is required because Ubuntu creates a default .bashrc (from /etc/skel)
# when the user account is created; without --force install.sh would skip it.
# Also verifies .gitconfig values and that aliases load in interactive bash.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

DOTFILES_DIR="${REPO_ROOT}/dotfiles"
HOME_DIR="${HOME}"

# ---------------------------------------------------------------------------
# Provision: dotfiles only (apt packages tested separately)
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile base --dotfiles-only --force"
bash "${REPO_ROOT}/install.sh" --profile base --dotfiles-only --force

# ---------------------------------------------------------------------------
# Assert symlinks exist and point to the correct repo targets
# ---------------------------------------------------------------------------
echo ""
echo "  Checking dotfile symlinks..."

assert_symlink "${HOME_DIR}/.bashrc"       "${DOTFILES_DIR}/.bashrc"
assert_symlink "${HOME_DIR}/.bash_aliases" "${DOTFILES_DIR}/.bash_aliases"
assert_symlink "${HOME_DIR}/.bash_profile" "${DOTFILES_DIR}/.bash_profile"
assert_symlink "${HOME_DIR}/.gitconfig"    "${DOTFILES_DIR}/.gitconfig"

# ---------------------------------------------------------------------------
# Assert .gitconfig values are applied
# ---------------------------------------------------------------------------
echo ""
echo "  Checking git config values..."

assert_git_config "core.editor"          "vim"
assert_git_config "init.defaultbranch"   "main"
assert_git_config "color.ui"             "auto"
assert_git_config "pull.rebase"          "false"
assert_git_config "push.autosetupremote" "true"
assert_git_config "alias.st"             "status"
assert_git_config "alias.co"             "checkout"
assert_git_config "alias.br"             "branch"
assert_git_config "alias.lg"             "log --oneline --graph --decorate --all"

# Assert user identity is NOT in .gitconfig (handled by FEAT-0008)
echo ""
echo "  Checking git identity is absent..."
if git config --global user.name &>/dev/null 2>&1; then
  _fail "user.name should not be set in .gitconfig"
else
  _pass "user.name is absent from .gitconfig"
fi
if git config --global user.email &>/dev/null 2>&1; then
  _fail "user.email should not be set in .gitconfig"
else
  _pass "user.email is absent from .gitconfig"
fi

# ---------------------------------------------------------------------------
# Assert aliases are available in an interactive bash session
# ---------------------------------------------------------------------------
echo ""
echo "  Checking bash aliases load in interactive mode..."

assert_cmd_success "Alias 'll' is available"  bash -i -c 'type ll'
assert_cmd_success "Alias 'la' is available"  bash -i -c 'type la'
assert_cmd_success "Alias 'gs' is available"  bash -i -c 'type gs'
assert_cmd_success "Alias 'gl' is available"  bash -i -c 'type gl'

# ---------------------------------------------------------------------------
# Assert symlink is live: editing the repo file is immediately visible
# ---------------------------------------------------------------------------
echo ""
echo "  Checking symlink is live (edit in repo is reflected in HOME)..."

# Add a unique comment to the repo file
MARKER="# SMOKE-TEST-MARKER-$$"
echo "$MARKER" >> "${DOTFILES_DIR}/.bash_aliases"

if grep -q "$MARKER" "${HOME_DIR}/.bash_aliases"; then
  _pass "Edit in repo dotfiles is immediately visible via symlink in HOME"
else
  _fail "Edit in repo dotfiles is NOT visible via symlink in HOME"
fi

# Restore the file (remove the test marker line)
# Use a temp file to avoid sed -i portability issues
python3 -c "
import sys
lines = open(sys.argv[1]).readlines()
open(sys.argv[1], 'w').writelines(l for l in lines if l.strip() != sys.argv[2])
" "${DOTFILES_DIR}/.bash_aliases" "$MARKER"

finish
