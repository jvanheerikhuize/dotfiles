#!/usr/bin/env bash
# Scenario: No prior SSH key — install.sh generates keypair and writes ~/.ssh/config.
# Verifies AC-001 (keypair + permissions + comment), AC-003 (config written),
# AC-005 (public key printed), AC-006 (non-interactive warning).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Provision: run install.sh non-interactively (no TTY in Docker — covers AC-006).
# Capture full output so we can assert on logged messages.
# --force replaces /etc/skel skeleton files created by useradd -m.
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile base --dotfiles-only --force --non-interactive"
output=$(printf "Test User\ntest@example.com\n" \
  | bash "${REPO_ROOT}/install.sh" --profile base --dotfiles-only --force --non-interactive 2>&1)

# ---------------------------------------------------------------------------
# AC-001: keypair generated at the correct paths
# ---------------------------------------------------------------------------
echo ""
echo "  Checking keypair was generated..."

assert_file_exists "${HOME}/.ssh/id_ed25519"
assert_file_exists "${HOME}/.ssh/id_ed25519.pub"

# ---------------------------------------------------------------------------
# AC-001: correct permissions
# ---------------------------------------------------------------------------
echo ""
echo "  Checking permissions..."

assert_file_perms "${HOME}/.ssh"                "700"
assert_file_perms "${HOME}/.ssh/id_ed25519"     "600"
assert_file_perms "${HOME}/.ssh/id_ed25519.pub" "644"

# ---------------------------------------------------------------------------
# AC-001: key comment is <user>@<hostname>
# ---------------------------------------------------------------------------
echo ""
echo "  Checking key comment..."

expected_comment="$(whoami)@$(hostname)"
assert_file_contains "${HOME}/.ssh/id_ed25519.pub" "$expected_comment"

# ---------------------------------------------------------------------------
# AC-003: ~/.ssh/config written with correct content and permissions
# ---------------------------------------------------------------------------
echo ""
echo "  Checking ~/.ssh/config..."

assert_file_exists   "${HOME}/.ssh/config"
assert_file_perms    "${HOME}/.ssh/config" "600"
assert_file_contains "${HOME}/.ssh/config" "AddKeysToAgent yes"
assert_file_contains "${HOME}/.ssh/config" "IdentityFile ~/.ssh/id_ed25519"

# ---------------------------------------------------------------------------
# AC-005: public key printed to stdout with correct header
# ---------------------------------------------------------------------------
echo ""
echo "  Checking public key was printed..."

if echo "$output" | grep -qF "Your SSH public key (add this to GitHub/GitLab):"; then
  _pass "Output contains public key header"
else
  _fail "Output contains public key header"
fi

if echo "$output" | grep -qF "github.com/settings/ssh/new"; then
  _pass "Output contains GitHub URL"
else
  _fail "Output contains GitHub URL"
fi

# ---------------------------------------------------------------------------
# AC-006: non-interactive warning printed (no passphrase)
# ---------------------------------------------------------------------------
echo ""
echo "  Checking non-interactive warning..."

if echo "$output" | grep -qF "SSH key generated without passphrase (non-interactive mode)"; then
  _pass "Non-interactive passphrase warning printed"
else
  _fail "Non-interactive passphrase warning printed"
fi

finish
