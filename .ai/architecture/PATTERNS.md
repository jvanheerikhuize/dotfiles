# Code Patterns & Conventions

> **For AI Assistants**: Follow these patterns when generating or modifying code in this repository. Every pattern here reflects the actual Bash idioms used in `src/`. Consistency is critical.

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.1.0 |
| Last Updated | 2026-02-26 |

---

## 1. General Principles

1. **Clarity over cleverness** — Explicit, readable Bash beats a clever one-liner
2. **Fail fast** — `set -euo pipefail` ensures errors are never silently swallowed
3. **Idempotency** — Every function must be safe to run twice; always check state before acting
4. **Minimal globals** — All logic lives in named functions with `local` variables; only `install.sh` owns global state
5. **No direct echo** — All user output goes through the logging functions in `src/utils.sh`

---

## 2. Script Header Pattern

Every script in `src/` **must** start exactly like this:

```bash
#!/usr/bin/env bash
# Brief one-line description of what this script does.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"
```

### Why `set -euo pipefail`

| Flag | Effect |
|------|--------|
| `-e` | Exit immediately on any command returning non-zero |
| `-u` | Treat unset variables as errors |
| `-o pipefail` | Propagate failures through pipes (not just the last command) |

### Why `SCRIPT_DIR` at the top

Each script must resolve its own location so it can be run **standalone** (e.g. `bash src/setup-ssh.sh`) as well as sourced by `install.sh`. Without this, relative paths break.

> **IMPORTANT**: `install.sh` captures `_INSTALL_ROOT="${SCRIPT_DIR}"` before sourcing anything, because sourced scripts redefine `SCRIPT_DIR` at global scope. Never add `SCRIPT_DIR` assignments to `install.sh` after the initial capture. See `ARCHITECTURE.md §5` for full detail.

---

## 3. Function Pattern

All logic must be inside named functions. No code at the top level of a sourced script (except variable declarations and the standalone guard at the bottom).

```bash
# Pattern: function with local variables only
function_name() {
  local arg1="${1}"
  local arg2="${2:-default_value}"
  local result

  # ... implementation ...

  log_info "Done: ${result}"
}
```

### Rules

- All variables inside functions are `local` — no global side effects
- Functions take positional arguments `$1`, `$2`, etc.; document them with a comment if non-obvious
- Functions that produce output use `log_*` functions, not `echo` or `printf`
- Functions that modify the filesystem check state first (idempotency pattern — see §6)

---

## 4. Logging Pattern

**Never use `echo` directly.** All output goes through the logging functions defined in `src/utils.sh`.

```bash
log_info  "Informational message (green)"
log_warn  "Warning — something unexpected (yellow)"
log_error "Fatal error — about to exit (red)"
log_step  "Section heading (bold blue)"
log_dry_run "Would do X (shown only in --dry-run mode)"
```

### Usage examples

```bash
install_apt_packages() {
  log_step "Installing apt packages"

  for pkg in "${apt_packages[@]}"; do
    if dpkg -l "${pkg}" &>/dev/null; then
      log_info "Already installed: ${pkg}"
      continue
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
      log_dry_run "Would install apt package: ${pkg}"
      continue
    fi

    log_info "Installing: ${pkg}"
    sudo apt-get install -y "${pkg}"
  done
}
```

---

## 5. Dry-Run Pattern

Every function that writes to the filesystem or runs side-effecting commands **must** check `DRY_RUN` and short-circuit with `log_dry_run`.

```bash
_write_ssh_config() {
  local config_path="${1}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry_run "Would write ${config_path}"
    return 0
  fi

  # ... actual write logic ...
  log_info "Wrote ${config_path}"
}
```

`DRY_RUN` is set by `install.sh` based on the `--dry-run` flag and exported so sourced scripts can read it.

---

## 6. Idempotency Pattern

Before performing any action that changes system state, check whether it has already been done. If yes, log and skip.

```bash
_generate_keypair() {
  local key_path="${1}"

  if [[ -f "${key_path}" ]]; then
    log_info "SSH key already exists: ${key_path}"
    return 0
  fi

  log_info "Generating ed25519 keypair: ${key_path}"
  ssh-keygen -t ed25519 -f "${key_path}" -C "${USER}@$(hostname)" -N ""
}
```

```bash
_install_apt_package() {
  local pkg="${1}"

  if dpkg -l "${pkg}" &>/dev/null; then
    log_info "Already installed: ${pkg}"
    return 0
  fi

  sudo apt-get install -y "${pkg}"
}
```

---

## 7. Standalone Script Guard

Scripts in `src/` that can be run directly (not just sourced) must include this guard at the **bottom** of the file:

```bash
# ---------------------------------------------------------------------------
# Standalone entrypoint (run directly, not sourced)
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse any standalone-specific flags here
  setup_ssh_key
fi
```

This pattern allows the script to be sourced by `install.sh` without executing immediately, while still supporting direct invocation for testing and manual use.

---

## 8. YAML Parsing Pattern

Profile YAML is parsed using `python3` inline. Three helper functions are available from `src/utils.sh`:

```bash
# Get a single scalar value
# Usage: yaml_get <file> <key>
profile_name="$(yaml_get "${profile_file}" "name")"

# Get a flat list of values
# Usage: yaml_get_list <file> <key>
mapfile -t apt_packages < <(yaml_get_list "${profile_file}" "packages.apt")

# Get a list of key:value pairs (for structured list items)
# Usage: yaml_get_list_pairs <file> <key> <pair_key>
mapfile -t snap_entries < <(yaml_get_list_pairs "${profile_file}" "packages.snap" "name")
```

These functions use `python3 -c` with inline Python to parse YAML. They require `python3-yaml` to be available (pre-installed on Ubuntu 22.04 or present in the Dockerfile bootstrap layer).

---

## 9. Non-Interactive Mode Pattern

Scripts that prompt the user must check `NON_INTERACTIVE` and provide a safe default or skip the prompt:

```bash
setup_git_identity() {
  if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
    log_info "Non-interactive mode: skipping git identity setup"
    return 0
  fi

  # ... interactive prompts ...
}
```

`NON_INTERACTIVE` is exported by `install.sh` when `--non-interactive` is passed. Smoke tests always set `NON_INTERACTIVE=true` before invoking `install.sh`.

---

## 10. Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Script files | `kebab-case.sh` | `setup-ssh.sh` |
| Public functions | `snake_case` | `setup_ssh_key()` |
| Private helpers | `_snake_case` (leading underscore) | `_write_ssh_config()` |
| Global constants | `SCREAMING_SNAKE_CASE` | `DRY_RUN`, `NON_INTERACTIVE` |
| Local variables | `snake_case` | `local key_path` |
| Profile files | `kebab-case.yaml` | `base.yaml`, `dev.yaml` |

---

## 11. Anti-Patterns — NEVER DO THESE

### 11.1 `[[ cond ]] && cmd` as a statement under `set -e`

```bash
# WRONG — when [[ -f "$file" ]] is FALSE, bash returns exit 1,
# which triggers errexit and kills the script.
[[ -f "${key_path}" ]] && log_info "Key exists"

# CORRECT — use if/then
if [[ -f "${key_path}" ]]; then
  log_info "Key exists"
fi
```

**Root cause**: `[[ false ]]` returns exit code 1. Under `set -e`, any non-zero exit causes the script to abort — even the left-hand side of `&&`.

### 11.2 Bare `return` in non-interactive shell guards

```bash
# WRONG — in dotfiles sourced by .bash_profile
# The failed [[ $- == *i* ]] test returns exit 1.
# Bare `return` inherits that exit code.
# .bash_profile propagates it → `bash --login -c exit` returns 1.
[[ $- == *i* ]] || return

# CORRECT — always return 0 explicitly
[[ $- == *i* ]] || return 0
```

### 11.3 Hardcoded package names in scripts

```bash
# WRONG
sudo apt-get install -y git curl build-essential

# CORRECT — read from profile YAML
mapfile -t apt_packages < <(yaml_get_list "${profile_file}" "packages.apt")
for pkg in "${apt_packages[@]}"; do
  _install_apt_package "${pkg}"
done
```

### 11.4 Direct echo for user output

```bash
# WRONG
echo "Installing packages..."
echo "Error: file not found"

# CORRECT
log_step "Installing packages"
log_error "File not found: ${path}"
```

### 11.5 Running as root

```bash
# WRONG — do not sudo the whole script
sudo bash install.sh

# CORRECT — run as normal user; individual package commands use sudo internally
bash install.sh --profile base
```

---

## 12. Smoke Test Patterns

### Test script header

```bash
#!/usr/bin/env bash
# Scenario: brief description of what this test covers.
# Verifies: AC-NNN from FEAT-XXXX
set -uo pipefail   # Note: NOT -e — tests must continue after failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"
```

Note `set -uo pipefail` (not `-euo`) — tests must run through all assertions and report failures rather than aborting.

### Assertion helpers (from `helpers.sh`)

```bash
_pass "Description of what passed"
_fail "Description of what failed"
assert_file_perms "${path}" "600"          # Check octal permissions
assert_file_contains "${path}" "substring"  # Check file content
assert_output_contains "substring" <command> [args...]  # Check command output
finish  # Print summary and exit with correct code
```

### Running install.sh in tests

```bash
# Standard test invocation pattern
printf "Test User\ntest@example.com\n" \
  | NON_INTERACTIVE=true bash "${REPO_ROOT}/install.sh" \
    --profile base \
    --dotfiles-only \
    --force \
    --non-interactive \
    &>/dev/null
```

Always use `--force` in smoke tests (Ubuntu's `useradd -m` pre-creates `/etc/skel` copies in `$HOME`).

---

## 13. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-26 | Jerry van Heerikhuize | Initial real content, replacing TypeScript template (FEAT-0016) |
| 1.1.0 | 2026-02-26 | Jerry van Heerikhuize | Added §12 smoke test patterns |
