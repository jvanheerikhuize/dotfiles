#!/usr/bin/env bash
# Scenario: install.sh with an unknown --profile name exits non-zero.
# No provisioning required.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

echo "  Testing: unknown profile name exits non-zero"

assert_cmd_fails \
  "Unknown profile 'nonexistent-smoke-profile' exits non-zero" \
  bash "${REPO_ROOT}/install.sh" --profile nonexistent-smoke-profile

finish
