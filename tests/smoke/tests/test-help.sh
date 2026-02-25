#!/usr/bin/env bash
# Scenario: install.sh --help exits 0 and prints usage.
# No provisioning required.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

echo "  Testing: install.sh --help"

assert_cmd_success "--help exits 0" bash "${REPO_ROOT}/install.sh" --help

finish
