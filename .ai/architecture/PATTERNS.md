# Code Patterns & Conventions

> **For AI Assistants**: Follow these patterns when generating or modifying code. Every script in this repo must conform to these conventions.

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Last Updated | 2026-02-25 |

---

## 1. General Principles

1. **Clarity over cleverness** — Bash is read by humans first; avoid obscure one-liners
2. **Explicit over implicit** — Make behaviour obvious; no silent failures
3. **Fail fast** — Validate early with `set -euo pipefail`; exit on error with a clear message
4. **Idempotent by default** — Every operation must be safe to run multiple times

---

## 2. Script Header (required in every script)

```bash
#!/usr/bin/env bash
# Brief description of what this script does
set -euo pipefail

# Source shared utilities (adjust relative path as needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"
```

Rules:
- `#!/usr/bin/env bash` — always; never `/bin/bash` (portability)
- `set -euo pipefail` — always; no exceptions
- Source `utils.sh` for logging helpers
- `SCRIPT_DIR` uses `BASH_SOURCE[0]` — works when sourced or called from any directory

---

## 3. Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Script files | `kebab-case.sh` | `install-packages.sh` |
| Functions | `snake_case` | `install_apt_package` |
| Local variables | `snake_case` | `package_name` |
| Constants / readonly | `SCREAMING_SNAKE` | `DOTFILES_DIR` |
| Boolean flags | `is_` / `has_` / `skip_` prefix | `is_verbose`, `skip_dotfiles` |

---

## 4. Logging Pattern

All output goes through helpers in `scripts/utils.sh`. Never use bare `echo`.

```bash
# utils.sh defines these:
log_info()  { echo "[INFO]  $(date '+%H:%M:%S') $*"; }
log_warn()  { echo "[WARN]  $(date '+%H:%M:%S') $*" >&2; }
log_error() { echo "[ERROR] $(date '+%H:%M:%S') $*" >&2; exit 1; }
log_step()  { echo ""; echo "==> $*"; }   # section header
```

Usage:

```bash
log_step "Installing apt packages"
log_info "Installing: curl"
log_warn "Package vim already installed, skipping"
log_error "apt-get failed for package: curl"   # exits 1
```

---

## 5. Function Pattern

```bash
# Good: named, documented, uses locals, idempotency check
install_apt_package() {
  local package="$1"

  if dpkg -s "$package" &>/dev/null 2>&1; then
    log_info "Already installed: $package"
    return 0
  fi

  log_info "Installing: $package"
  sudo apt-get install -y "$package"
}

# Bad: inline logic, no function, no idempotency check
sudo apt-get install -y "$pkg"
```

Rules:
- All logic in named functions
- Always declare variables with `local` inside functions
- Check state before acting (idempotency)
- One function = one responsibility

---

## 6. Argument Parsing Pattern

```bash
# In the entrypoint script
PROFILE="base"
SKIP_DOTFILES=false
DOTFILES_ONLY=false
FORCE=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)
        PROFILE="$2"
        shift 2
        ;;
      --skip-dotfiles)
        SKIP_DOTFILES=true
        shift
        ;;
      --dotfiles-only)
        DOTFILES_ONLY=true
        shift
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown argument: $1"
        ;;
    esac
  done
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --profile PROFILE    Profile to apply (default: base)
  --skip-dotfiles      Install packages only
  --dotfiles-only      Apply dotfiles only
  --force              Replace existing dotfiles (backs up to .bak)
  --help               Show this help
EOF
}
```

---

## 7. YAML Parsing Pattern

Use `python3` inline — it's on every Ubuntu 22.04 system by default.

```bash
# Extract a scalar value from YAML
yaml_get() {
  local file="$1"
  local key="$2"
  python3 -c "
import yaml
with open('${file}') as f:
    data = yaml.safe_load(f)
keys = '${key}'.split('.')
val = data
for k in keys:
    val = val.get(k) if isinstance(val, dict) else None
print(val if val is not None else '')
"
}

# Extract a list from YAML as newline-separated values
yaml_get_list() {
  local file="$1"
  local key="$2"
  python3 -c "
import yaml
with open('${file}') as f:
    data = yaml.safe_load(f)
keys = '${key}'.split('.')
val = data
for k in keys:
    val = val.get(k) if isinstance(val, dict) else None
if isinstance(val, list):
    for item in val:
        print(item)
"
}

# Usage:
extends=$(yaml_get "profiles/desktop.yaml" "profile.extends")
mapfile -t apt_packages < <(yaml_get_list "profiles/base.yaml" "packages.apt")
```

---

## 8. Idempotency Patterns

### Package install — check before installing

```bash
install_apt_package() {
  local pkg="$1"
  if dpkg -s "$pkg" &>/dev/null 2>&1; then
    log_info "Already installed: $pkg"
    return 0
  fi
  log_info "Installing (apt): $pkg"
  sudo apt-get install -y "$pkg"
}

install_snap_package() {
  local pkg="$1"
  if snap list "$pkg" &>/dev/null 2>&1; then
    log_info "Already installed: $pkg"
    return 0
  fi
  log_info "Installing (snap): $pkg"
  sudo snap install "$pkg"
}
```

### Symlink — check before linking

```bash
link_dotfile() {
  local src="$1"   # absolute path in repo
  local dest="$2"  # absolute path in $HOME
  local force="$3" # true|false

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    log_info "Already linked: $dest"
    return 0
  fi

  if [[ -e "$dest" ]] && [[ "$force" != "true" ]]; then
    log_warn "Skipping $dest — file exists (use --force to replace)"
    return 0
  fi

  if [[ -e "$dest" ]] && [[ "$force" == "true" ]]; then
    mv "$dest" "${dest}.bak"
    log_info "Backed up: ${dest}.bak"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  log_info "Linked: $dest → $src"
}
```

---

## 9. Error Handling Pattern

```bash
# Wrap external commands and provide context on failure
run_or_fail() {
  local description="$1"
  shift
  if ! "$@"; then
    log_error "${description} failed (command: $*)"
  fi
}

# Usage:
run_or_fail "apt update" sudo apt-get update
```

Prefer `log_error` (which exits 1) over bare `exit 1` — it always prints context.

---

## 10. Guard / Precondition Pattern

```bash
# Reject running as root
require_not_root() {
  if [[ $EUID -eq 0 ]]; then
    log_error "Do not run as root. Use a regular user with sudo access."
  fi
}

# Assert a command is available
require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    log_error "Required command not found: $cmd"
  fi
}

# Usage at top of install.sh:
require_not_root
require_cmd git
require_cmd python3
```

---

## 11. Profile Merge Pattern

```bash
# Declare global arrays before calling load_profile
APT_PACKAGES=()
SNAP_PACKAGES=()
FLATPAK_PACKAGES=()

# Merge a profile with its parent (recursive, depth-first)
load_profile() {
  local profile_name="$1"
  local profile_file="${PROFILES_DIR}/${profile_name}.yaml"

  [[ -f "$profile_file" ]] || log_error "Profile not found: $profile_name"

  local extends
  extends=$(yaml_get "$profile_file" "profile.extends")

  # Recurse into parent first (base packages come first)
  if [[ -n "$extends" && "$extends" != "None" && "$extends" != "null" ]]; then
    load_profile "$extends"
  fi

  # Append this profile's packages to the global arrays
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && APT_PACKAGES+=("$pkg")
  done < <(yaml_get_list "$profile_file" "packages.apt")
}
```

---

## 12. Anti-Patterns to Avoid

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|-----------------|
| `curl \| bash` without checksum | Arbitrary code execution | Download, verify checksum, then run |
| Hardcoded package lists in `.sh` | Not readable by YAML tools / AI | Put lists in profile YAML |
| Global variables mutated inside functions | Hard to reason about | Use `local`; pass values as arguments |
| Running `sudo ./install.sh` as root | Breaks $HOME detection | Require non-root with sudo access |
| Bare `exit 1` without message | Silent failures | Always use `log_error "reason"` |
| `rm -rf` without path validation | Destructive accidents | Validate path is in expected scope first |
| Skipping the idempotency check | Breaks re-runs | Always check state before acting |
| `echo` for user-visible output | Bypasses log format | Use `log_info` / `log_warn` / `log_step` |

---

## 13. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-25 | Jerry | Initial bash patterns for dotfiles provisioning |
