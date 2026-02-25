#!/usr/bin/env bash
# Scenario: All apt packages declared in profiles/base.yaml are installed
# after running install.sh --profile base --skip-dotfiles.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# ---------------------------------------------------------------------------
# Provision: packages only (dotfiles tested separately)
# ---------------------------------------------------------------------------
echo "  Running: install.sh --profile base --skip-dotfiles"
bash "${REPO_ROOT}/install.sh" --profile base --skip-dotfiles

# ---------------------------------------------------------------------------
# Assert each package from base.yaml is installed
# ---------------------------------------------------------------------------
echo ""
echo "  Checking declared apt packages..."

# Parse packages.apt from base.yaml using python3 (available in the image)
while IFS= read -r pkg; do
  [[ -n "$pkg" ]] && assert_pkg_installed "$pkg"
done < <(
  python3 - "${REPO_ROOT}/profiles/base.yaml" <<'PYEOF'
import sys, yaml
with open(sys.argv[1]) as f:
    data = yaml.safe_load(f)
for pkg in (data.get("packages", {}).get("apt") or []):
    print(pkg)
PYEOF
)

finish
