#!/usr/bin/env bash
# Shared utilities: logging, guards, YAML parsing
# Source this file from other scripts — do not execute directly.
set -euo pipefail

# ---------------------------------------------------------------------------
# Colours (suppressed if NO_COLOR is set)
# ---------------------------------------------------------------------------
if [[ -z "${NO_COLOR:-}" && -t 1 ]]; then
  _RED='\033[0;31m'
  _YELLOW='\033[1;33m'
  _GREEN='\033[0;32m'
  _CYAN='\033[0;36m'
  _BOLD='\033[1m'
  _RESET='\033[0m'
else
  _RED='' _YELLOW='' _GREEN='' _CYAN='' _BOLD='' _RESET=''
fi

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
log_info() {
  echo -e "${_GREEN}[INFO]${_RESET}  $(date '+%H:%M:%S') $*"
}

log_warn() {
  echo -e "${_YELLOW}[WARN]${_RESET}  $(date '+%H:%M:%S') $*" >&2
}

log_error() {
  echo -e "${_RED}[ERROR]${_RESET} $(date '+%H:%M:%S') $*" >&2
  exit 1
}

log_step() {
  echo -e "\n${_BOLD}${_CYAN}==> $*${_RESET}"
}

log_dry_run() {
  echo -e "${_CYAN}[DRY RUN]${_RESET} $(date '+%H:%M:%S') $*"
}

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------

# Reject running as root
require_not_root() {
  if [[ $EUID -eq 0 ]]; then
    log_error "Do not run as root. Use a regular user with sudo access."
  fi
}

# Assert a command exists on PATH
require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    log_error "Required command not found: ${cmd}"
  fi
}

# ---------------------------------------------------------------------------
# YAML parsing (via python3 — present by default on Ubuntu 22.04)
# ---------------------------------------------------------------------------

# yaml_get <file> <dot.separated.key>
# Prints the scalar value at the given key, or nothing if absent.
yaml_get() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PYEOF'
import sys, yaml

file, key = sys.argv[1], sys.argv[2]
with open(file) as f:
    data = yaml.safe_load(f)

val = data
for k in key.split('.'):
    if isinstance(val, dict):
        val = val.get(k)
    else:
        val = None
        break

if val is not None and str(val).lower() not in ('none', 'null', '~'):
    print(val)
PYEOF
}

# yaml_get_list <file> <dot.separated.key>
# Prints each list item on its own line. Prints nothing if key is absent or empty.
yaml_get_list() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PYEOF'
import sys, yaml

file, key = sys.argv[1], sys.argv[2]
with open(file) as f:
    data = yaml.safe_load(f)

val = data
for k in key.split('.'):
    if isinstance(val, dict):
        val = val.get(k)
    else:
        val = None
        break

if isinstance(val, list):
    for item in val:
        if item is not None:
            print(item)
PYEOF
}

# yaml_get_list_pairs <file> <dot.separated.key> <field1> <field2>
# For each dict item in the list, prints "field1_val\tfield2_val" (tab-separated).
# Items missing a field emit an empty string for that field.
# Non-dict items are skipped.
yaml_get_list_pairs() {
  local file="$1"
  local key="$2"
  local field1="$3"
  local field2="$4"
  python3 - "$file" "$key" "$field1" "$field2" <<'PYEOF'
import sys, yaml

file, key, f1, f2 = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(file) as f:
    data = yaml.safe_load(f)

val = data
for k in key.split('.'):
    if isinstance(val, dict):
        val = val.get(k)
    else:
        val = None
        break

if isinstance(val, list):
    for item in val:
        if isinstance(item, dict):
            v1 = item.get(f1, '') or ''
            v2 = item.get(f2, '') or ''
            print(f"{v1}\t{v2}")
PYEOF
}
