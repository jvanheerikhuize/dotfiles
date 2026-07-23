#!/usr/bin/env bash
# Profile YAML structure validation.
# Source this file; do not execute directly.
set -euo pipefail

# Guard: source utils.sh only when not already loaded (i.e. when run standalone)
if ! declare -f log_info &>/dev/null; then
  _VAL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${_VAL_SCRIPT_DIR}/utils.sh"
fi

# validate_profiles <profile_name>
#
# Walks the full extends chain for <profile_name> and validates YAML structure.
# Checks:
#   - profile.name key is present
#   - extends references an existing profile file
#   - no circular extends chains (e.g. A extends B extends A)
#   - packages.* values are lists (not scalars or mappings)
#
# All errors across every profile in the chain are collected and printed to
# stderr together before exiting 1 — no partial-error exit.
# Silent and exits 0 on success.
validate_profiles() {
  local profile_name="$1"
  python3 - "${PROFILES_DIR}" "$profile_name" <<'PYEOF'
import sys, yaml, os

profiles_dir, top_profile = sys.argv[1], sys.argv[2]
errors = []
PACKAGE_TYPES = ('apt', 'snap', 'flatpak', 'deb', 'custom')


def load_yaml(name):
    path = os.path.join(profiles_dir, f"{name}.yaml")
    if not os.path.isfile(path):
        return None, path
    with open(path) as f:
        try:
            return yaml.safe_load(f), path
        except yaml.YAMLError:
            return False, path  # False signals YAML parse error


def validate(name, chain=None):
    if chain is None:
        chain = []

    # Circular extends detection
    if name in chain:
        cycle = ' \u2192 '.join(chain + [name])
        errors.append(f'Validation error: circular extends detected: {cycle}')
        return

    data, path = load_yaml(name)
    rel = f'profiles/{name}.yaml'

    # File not found
    if data is None:
        if chain:
            errors.append(
                f'Validation error: profile "{name}" not found'
                f' (referenced by "{chain[-1]}")'
            )
        else:
            errors.append(f'Validation error: profile "{name}" not found: {path}')
        return

    # YAML parse error
    if data is False:
        errors.append(f'Validation error in {rel}: failed to parse YAML')
        return

    # Required key: profile
    if not isinstance(data, dict) or 'profile' not in data:
        errors.append(f'Validation error in {rel}: missing required key: profile')
    elif not isinstance(data.get('profile'), dict) or 'name' not in data['profile']:
        errors.append(f'Validation error in {rel}: missing required key: profile.name')

    # Package list types
    if isinstance(data, dict):
        pkg = data.get('packages') or {}
        if not isinstance(pkg, dict):
            errors.append(f'Validation error in {rel}: packages must be a mapping')
        else:
            for ptype in PACKAGE_TYPES:
                val = pkg.get(ptype)
                if val is not None and not isinstance(val, list):
                    errors.append(
                        f'Validation error in {rel}: packages.{ptype} must be a list'
                    )

    # Recurse into extends
    extends = None
    if isinstance(data, dict) and isinstance(data.get('profile'), dict):
        raw = data['profile'].get('extends')
        if raw is not None and str(raw).strip().lower() not in ('null', 'none', '~', ''):
            extends = str(raw).strip()

    if extends:
        validate(extends, chain + [name])


validate(top_profile)

if errors:
    for e in errors:
        print(e, file=sys.stderr)
    sys.exit(1)
PYEOF
}
