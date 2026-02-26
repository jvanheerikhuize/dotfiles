#!/usr/bin/env bash
# Scenario: SSH key already exists — second run skips generation; existing ~/.ssh/config
# with custom content is left untouched.
# Verifies AC-002 (key skipped) and AC-004 (config untouched).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# First run: generate key and write config.
# ---------------------------------------------------------------------------
echo "  First run: generate key..."
printf "Test User\ntest@example.com\n" \
  | bash "${REPO_ROOT}/install.sh" --profile base --dotfiles-only --force --non-interactive \
  &>/dev/null

# ---------------------------------------------------------------------------
# AC-004: replace the generated config with custom content before the second run.
# If the second run modifies it, the custom marker will be gone.
# ---------------------------------------------------------------------------
echo "  Replacing ~/.ssh/config with custom content..."
cat > "${HOME}/.ssh/config" <<'EOF'
# CUSTOM CONFIG — must not be overwritten
Host myserver
    HostName 192.168.1.1
    User deploy
EOF

original_config=$(cat "${HOME}/.ssh/config")

# ---------------------------------------------------------------------------
# Second run: must skip key generation and leave config untouched.
# ---------------------------------------------------------------------------
echo "  Second run: install.sh --non-interactive..."
output=$(printf "Test User\ntest@example.com\n" \
  | bash "${REPO_ROOT}/install.sh" --profile base --dotfiles-only --non-interactive 2>&1)

# ---------------------------------------------------------------------------
# AC-002: skip message logged for existing key
# ---------------------------------------------------------------------------
echo ""
echo "  Checking key generation was skipped..."

if echo "$output" | grep -qF "SSH key already exists"; then
  _pass "Skip message logged for existing key"
else
  _fail "Skip message logged for existing key"
fi

# Original key files must still exist and be unchanged
assert_file_exists "${HOME}/.ssh/id_ed25519"
assert_file_exists "${HOME}/.ssh/id_ed25519.pub"

# ---------------------------------------------------------------------------
# AC-004: custom ~/.ssh/config is untouched
# ---------------------------------------------------------------------------
echo ""
echo "  Checking ~/.ssh/config was not overwritten..."

current_config=$(cat "${HOME}/.ssh/config")
if [[ "$current_config" == "$original_config" ]]; then
  _pass "~/.ssh/config contents unchanged"
else
  _fail "~/.ssh/config contents unchanged (was modified)"
fi

assert_file_contains "${HOME}/.ssh/config" "CUSTOM CONFIG"

if echo "$output" | grep -qF "SSH config already exists, skipping"; then
  _pass "Config skip message logged"
else
  _fail "Config skip message logged"
fi

finish
