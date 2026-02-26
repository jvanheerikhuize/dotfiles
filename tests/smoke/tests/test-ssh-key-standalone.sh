#!/usr/bin/env bash
# Scenario: src/setup-ssh.sh run standalone (without install.sh).
# Verifies the standalone entrypoint works and produces a valid keypair.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Run standalone — no install.sh involved.
# ---------------------------------------------------------------------------
echo "  Running: src/setup-ssh.sh --non-interactive"
output=$(bash "${REPO_ROOT}/src/setup-ssh.sh" --non-interactive 2>&1)

# ---------------------------------------------------------------------------
# Keypair must be generated
# ---------------------------------------------------------------------------
echo ""
echo "  Checking keypair was generated..."

assert_file_exists "${HOME}/.ssh/id_ed25519"
assert_file_exists "${HOME}/.ssh/id_ed25519.pub"

# ---------------------------------------------------------------------------
# Correct permissions
# ---------------------------------------------------------------------------
echo ""
echo "  Checking permissions..."

assert_file_perms "${HOME}/.ssh"                "700"
assert_file_perms "${HOME}/.ssh/id_ed25519"     "600"
assert_file_perms "${HOME}/.ssh/id_ed25519.pub" "644"

# ---------------------------------------------------------------------------
# Public key printed to stdout (AC-005)
# ---------------------------------------------------------------------------
echo ""
echo "  Checking public key was printed..."

if echo "$output" | grep -qF "Your SSH public key (add this to GitHub/GitLab):"; then
  _pass "Public key header printed"
else
  _fail "Public key header printed"
fi

if echo "$output" | grep -qF "github.com/settings/ssh/new"; then
  _pass "GitHub URL printed"
else
  _fail "GitHub URL printed"
fi

# ---------------------------------------------------------------------------
# Key type must be ed25519
# ---------------------------------------------------------------------------
echo ""
echo "  Checking key type..."

assert_file_contains "${HOME}/.ssh/id_ed25519.pub" "ssh-ed25519"

finish
