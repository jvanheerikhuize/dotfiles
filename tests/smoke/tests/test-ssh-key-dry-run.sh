#!/usr/bin/env bash
# Scenario: --dry-run must not generate any SSH files.
# Verifies the DRY_RUN path in setup-ssh.sh.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Run install.sh with --dry-run (no files should be created).
# --force is not needed here because dotfiles are not applied in dry-run.
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile base --dry-run --non-interactive"
printf "Test User\ntest@example.com\n" \
  | bash "${REPO_ROOT}/install.sh" --profile base --dry-run --non-interactive \
  &>/dev/null

# ---------------------------------------------------------------------------
# No SSH files must exist
# ---------------------------------------------------------------------------
echo ""
echo "  Checking no SSH files were created..."

if [[ ! -f "${HOME}/.ssh/id_ed25519" ]]; then
  _pass "~/.ssh/id_ed25519 not created in dry-run"
else
  _fail "~/.ssh/id_ed25519 not created in dry-run (file exists)"
fi

if [[ ! -f "${HOME}/.ssh/id_ed25519.pub" ]]; then
  _pass "~/.ssh/id_ed25519.pub not created in dry-run"
else
  _fail "~/.ssh/id_ed25519.pub not created in dry-run (file exists)"
fi

if [[ ! -f "${HOME}/.ssh/config" ]]; then
  _pass "~/.ssh/config not created in dry-run"
else
  _fail "~/.ssh/config not created in dry-run (file exists)"
fi

finish
