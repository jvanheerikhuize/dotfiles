---
paths:
  - "install.sh"
  - "src/**/*.sh"
---

# Shell script patterns (src/ and install.sh)

Full detail with examples: `.ai/architecture/PATTERNS.md`. The essentials:

## Header (every script in src/)

```bash
#!/usr/bin/env bash
# Brief one-line description.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"
```

**install.sh only**: it captures `_INSTALL_ROOT="${SCRIPT_DIR}"` before sourcing anything,
because sourced scripts clobber `SCRIPT_DIR` at global scope. Never add `SCRIPT_DIR`
assignments to `install.sh` after that capture.

## Structure

- All logic in named functions with `local` variables; no top-level code except
  declarations and the standalone guard at the bottom:
  `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then ... fi`
- Output only via `log_info` / `log_warn` / `log_error` / `log_step` / `log_dry_run`
  from `src/utils.sh` — never `echo`/`printf` to the user.
- Side-effecting functions: check `DRY_RUN` first (`log_dry_run "Would ..."` + `return 0`),
  and check current state before acting (idempotency — safe to run twice).
- Prompting functions: honor `NON_INTERACTIVE` with a safe default or skip.
- YAML access via `yaml_get`, `yaml_get_list`, `yaml_get_list_pairs` from utils.sh.

## Naming

Files `kebab-case.sh`; public functions `snake_case`; private helpers `_snake_case`;
constants `SCREAMING_SNAKE_CASE`; locals `snake_case`.

## Never

- `[[ cond ]] && cmd` as a standalone statement — false condition triggers errexit.
  Use `if/then`.
- Bare `return` in interactivity guards — use `[[ $- == *i* ]] || return 0`.
- Hardcoded package names — package lists live in `profiles/*.yaml`.
- `sudo bash install.sh` — run as normal user; individual commands sudo internally.
- `openssh-client` (not `ssh`) is the apt package name for SSH client tools.
