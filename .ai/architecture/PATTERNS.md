# Code Patterns & Conventions

> **For AI Assistants**: Follow these patterns when generating or modifying code. Every script in this repo must conform to these conventions.

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.4.0 |
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

All output goes through helpers in `src/utils.sh`. Never use bare `echo`.

```bash
# utils.sh defines these:
log_info()    { echo "[INFO]  $(date '+%H:%M:%S') $*"; }
log_warn()    { echo "[WARN]  $(date '+%H:%M:%S') $*" >&2; }
log_error()   { echo "[ERROR] $(date '+%H:%M:%S') $*" >&2; exit 1; }
log_step()    { echo ""; echo "==> $*"; }   # section header
log_dry_run() { echo "[DRY RUN] $(date '+%H:%M:%S') $*"; }  # FEAT-0005
```

Usage:

```bash
log_step "Installing apt packages"
log_info "Installing: curl"
log_warn "Package vim already installed, skipping"
log_error "apt-get failed for package: curl"   # exits 1
log_dry_run "Would install (apt): curl"         # dry-run preview, no-op
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
DRY_RUN=false

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
      --dry-run)
        DRY_RUN=true
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
  --dry-run            Preview what would be installed/linked; make no changes
  --help               Show this help
EOF
}
```

---

## 7. YAML Parsing Pattern

Use `python3` via heredoc — pass file path and keys as `sys.argv`, never via shell string interpolation.

```bash
# Extract a scalar value from YAML
yaml_get() {
  local file="$1" key="$2"
  python3 - "$file" "$key" <<'PYEOF'
import sys, yaml
file, key = sys.argv[1], sys.argv[2]
with open(file) as f:
    data = yaml.safe_load(f)
val = data
for k in key.split('.'):
    val = val.get(k) if isinstance(val, dict) else None
if val is not None and str(val).lower() not in ('none', 'null', '~'):
    print(val)
PYEOF
}

# Extract a simple list from YAML (one item per line)
yaml_get_list() {
  local file="$1" key="$2"
  python3 - "$file" "$key" <<'PYEOF'
import sys, yaml
file, key = sys.argv[1], sys.argv[2]
with open(file) as f:
    data = yaml.safe_load(f)
val = data
for k in key.split('.'):
    val = val.get(k) if isinstance(val, dict) else None
if isinstance(val, list):
    for item in val:
        if item is not None:
            print(item)
PYEOF
}

# Extract a list of dicts as tab-separated pairs: "field1<TAB>field2"
# Used for deb ({name, url}) and custom ({cmd, idempotency_check}) entries.
yaml_get_list_pairs() {
  local file="$1" key="$2" field1="$3" field2="$4"
  python3 - "$file" "$key" "$field1" "$field2" <<'PYEOF'
import sys, yaml
file, key, f1, f2 = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(file) as f:
    data = yaml.safe_load(f)
val = data
for k in key.split('.'):
    val = val.get(k) if isinstance(val, dict) else None
if isinstance(val, list):
    for item in val:
        if isinstance(item, dict):
            print(f"{item.get(f1,'') or ''}\t{item.get(f2,'') or ''}")
PYEOF
}

# Usage:
extends=$(yaml_get "profiles/desktop.yaml" "profile.extends")
while IFS= read -r pkg; do APT_PACKAGES+=("$pkg"); done \
  < <(yaml_get_list "profiles/base.yaml" "packages.apt")
while IFS= read -r entry; do DEB_PACKAGES+=("$entry"); done \
  < <(yaml_get_list_pairs "profiles/dev.yaml" "packages.deb" "name" "url")
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
DEB_PACKAGES=()     # entries: "name<TAB>url"
CUSTOM_PACKAGES=()  # entries: "cmd<TAB>idempotency_check"

# Merge a profile with its parent (recursive, depth-first)
load_profile() {
  local profile_name="$1"
  local profile_file="${PROFILES_DIR}/${profile_name}.yaml"

  [[ -f "$profile_file" ]] || log_error "Profile not found: $profile_name"

  # Recurse into parent first so base packages come first
  local extends
  extends=$(yaml_get "$profile_file" "profile.extends")
  [[ -n "$extends" ]] && load_profile "$extends"

  # Collect simple lists
  while IFS= read -r pkg; do [[ -n "$pkg" ]] && APT_PACKAGES+=("$pkg")
  done < <(yaml_get_list "$profile_file" "packages.apt")

  while IFS= read -r pkg; do [[ -n "$pkg" ]] && SNAP_PACKAGES+=("$pkg")
  done < <(yaml_get_list "$profile_file" "packages.snap")

  while IFS= read -r pkg; do [[ -n "$pkg" ]] && FLATPAK_PACKAGES+=("$pkg")
  done < <(yaml_get_list "$profile_file" "packages.flatpak")

  # Collect paired lists (deb and custom use dict entries)
  local _n _u
  while IFS= read -r _e; do
    IFS=$'\t' read -r _n _u <<< "$_e"
    [[ -n "$_n" && -n "$_u" ]] && DEB_PACKAGES+=("$_e")
  done < <(yaml_get_list_pairs "$profile_file" "packages.deb" "name" "url")

  local _c
  while IFS= read -r _e; do
    IFS=$'\t' read -r _c _ <<< "$_e"
    [[ -n "$_c" ]] && CUSTOM_PACKAGES+=("$_e")
  done < <(yaml_get_list_pairs "$profile_file" "packages.custom" "cmd" "idempotency_check")
}
```

**Important**: Never use `[[ cond ]] && cmd` as a statement under `set -e` — use `if [[ cond ]]; then cmd; fi` instead. When `[[ ]]` is false, the `&&` compound returns 1 and triggers `errexit`.

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
| `[[ cond ]] \|\| return` in dotfiles | `return` inherits exit code 1 from failed `[[ ]]`; propagates through `.bash_profile`; breaks `bash --login -c exit` | Use `return 0` explicitly |

---

## 13. Dotfile Conventions

Rules that apply to all files in `dotfiles/`:

**Non-interactive guard in `.bashrc`** — First real logic must return early for non-interactive shells:

```bash
[[ $- == *i* ]] || return 0
```

**Always use `return 0`, not bare `return`.** Without the explicit `0`, `return` inherits the exit code of the failed `[[ ]]` test (exit code 1). That 1 propagates through `.bash_profile` (via `source ~/.bashrc`) and causes `bash --login -c exit` to exit 1, because `exit` with no argument uses `$?` from the last startup file. This is a subtle but real bug that breaks CI smoke tests.

**No user identity in `.gitconfig`** — `user.name` and `user.email` are machine-specific and set by FEAT-0008. The repo `.gitconfig` must never include them.

**No undeclared tool dependencies** — Every tool referenced in dotfiles must exist on stock Ubuntu 22.04. Guard optional tools:

```bash
if command -v dircolors &>/dev/null; then
  eval "$(dircolors -b)"
fi
```

**Extensively commented** — Every non-obvious setting must have an inline comment explaining what it does and why.

---

## 14. Smoke Test Pattern

Test scripts live in `tests/smoke/tests/`. Each script:
1. Sources `../helpers.sh`
2. Runs `install.sh` with appropriate flags (full, `--skip-dotfiles`, or `--dotfiles-only`)
3. Calls `assert_*` helpers for each condition
4. Calls `finish` to print summary and exit

```bash
#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"

# Provision (--force replaces /etc/skel skeleton files created by useradd -m)
bash "${REPO_ROOT}/install.sh" --profile base --dotfiles-only --force

# Assert
assert_symlink "${HOME}/.bashrc" "${REPO_ROOT}/dotfiles/.bashrc"
assert_git_config "core.editor" "vim"
assert_cmd_success "bash --login exits 0" bash --login -c exit

finish   # prints summary; exits 0 or 1
```

Available assertions (all defined in `tests/smoke/helpers.sh`):

| Helper | What it checks |
|--------|---------------|
| `assert_cmd_success <desc> <cmd...>` | Command exits 0 |
| `assert_cmd_fails <desc> <cmd...>` | Command exits non-zero |
| `assert_pkg_installed <pkg>` | `dpkg -s <pkg>` exits 0 |
| `assert_file_exists <path>` | `test -e <path>` |
| `assert_symlink <link> <target>` | `readlink <link>` == `<target>` |
| `assert_git_config <key> <value>` | `git config --global <key>` == `<value>` |

---

## 15. Dry-Run Pattern (FEAT-0005)

The `DRY_RUN` global variable gates all mutating operations. No separate dry-run functions — the same install and link functions check `DRY_RUN` before executing side effects.

```bash
# In a package install function
install_apt_package() {
  local pkg="$1"

  if dpkg -s "$pkg" &>/dev/null 2>&1; then
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log_dry_run "Already installed: ${pkg} (skip)"
    else
      log_info "Already installed: ${pkg}"
    fi
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_dry_run "Would install (apt): ${pkg}"
    return 0
  fi

  log_info "Installing (apt): ${pkg}"
  sudo apt-get install -y "$pkg"
}

# In the symlink function
link_dotfile() {
  local src="$1" dest="$2" force="$3"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log_dry_run "Already linked correctly: ${dest} (skip)"
    else
      log_info "Already linked: ${dest}"
    fi
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_dry_run "Would link: ${dest} → ${src}"
    return 0
  fi

  ln -sf "$src" "$dest"
  log_info "Linked: ${dest} → ${src}"
}
```

**Rules:**
- `DRY_RUN` is a global variable in `install.sh`; sourced scripts (`packages.sh`, `dotfiles.sh`) reference it via `${DRY_RUN:-false}` (defaults to false when not set, e.g. standalone sourcing)
- Read-only operations (idempotency checks like `dpkg -s`) still execute in dry-run mode — only writes are skipped
- All `log_dry_run` output uses the `[DRY RUN]` prefix from `src/utils.sh`

---

## 16. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-25 | Jerry | Initial bash patterns for dotfiles provisioning |
| 1.1.0 | 2026-02-25 | Jerry | FEAT-0003: added dotfile conventions section |
| 1.2.0 | 2026-02-25 | Jerry | FEAT-0004: added smoke test pattern section |
| 1.3.0 | 2026-02-25 | Jerry | Bug fixes: document return 0 guard and --force requirement in smoke tests |
| 1.4.0 | 2026-02-25 | Jerry | FEAT-0005: added log_dry_run to logging section; --dry-run to arg parsing; DRY_RUN pattern section |
