# System Architecture

> **For AI Assistants**: This document defines HOW the system is built. For WHAT it does, see `../specs/SPEC.md`. For WHY decisions were made, see `../decisions/`.

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Status | Active |
| Last Updated | 2026-02-25 |
| Owner | Jerry |

---

## 1. Architecture Overview

### 1.1 System Context

```
┌─────────────────────────────────────────────────────────────┐
│                     STAGE 1                                  │
│  Autoinstall.yaml  →  Fresh Ubuntu 22.04 install            │
│  (base OS, users, partitions, minimal packages)              │
└────────────────────────────┬────────────────────────────────┘
                             │  git clone + ./install.sh
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                     STAGE 2 (this repo)                      │
│                                                              │
│   install.sh                                                 │
│   ├── profiles/<name>.yaml   (what to install)              │
│   ├── src/packages.sh    (how to install packages)      │
│   └── src/dotfiles.sh    (how to link dotfiles)         │
│                                                              │
│   Package managers: apt, snap, flatpak, deb, custom         │
│   Dotfiles: symlinks from dotfiles/ → $HOME                 │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│              Fully Configured Ubuntu Machine                 │
│  tools installed · dotfiles linked · ready to use           │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Architecture Style

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| Language | Bash | Zero dependencies; present on every Ubuntu install |
| Config format | YAML | Human-readable, AI-readable, well-structured |
| YAML parsing | python3 inline | python3 is on Ubuntu 22.04 by default; no bootstrap needed |
| Execution model | Single entrypoint script | Simple to invoke; no make, no ansible, no runtime |
| State management | None (idempotent ops) | apt/snap/flatpak are naturally idempotent; symlinks checked before creation |

---

## 2. Component Architecture

### 2.1 Component Diagram

```
install.sh (entrypoint)
│
├── parse args (--profile, --skip-dotfiles, --dotfiles-only, --force, --dry-run, --validate-only, --quiet, --non-interactive, --help)
│
├── trap '_on_exit' EXIT → print_summary() on all exits (FEAT-0007)
│
├── src/utils.sh
│   ├── log_info()      print timestamped info line (suppressed when QUIET=true)
│   ├── log_warn()      print warning (does not exit)
│   ├── log_error()     print error and exit 1
│   ├── log_step()      print section header (suppressed when QUIET=true)
│   ├── log_dry_run()   print [DRY RUN] preview line (FEAT-0005; suppressed when QUIET=true)
│   └── require_cmd()   assert a command exists or exit
│
├── src/validate.sh (FEAT-0006)
│   └── validate_profiles()  python3 walk of extends chain; collect all errors
│
├── profile loader
│   ├── load profiles/<profile>.yaml
│   ├── resolve extends: chain (recursive merge, base first)
│   └── emit merged package lists per type
│
├── src/packages.sh
│   ├── install_apt()       sudo apt-get install -y <pkg>; → INSTALLED/SKIPPED_PACKAGES[]
│   ├── install_snap()      sudo snap install <pkg>; → INSTALLED/SKIPPED_PACKAGES[]
│   ├── install_flatpak()   flatpak install -y <pkg>; → INSTALLED/SKIPPED_PACKAGES[]
│   ├── install_deb()       wget <url> → sudo dpkg -i; → INSTALLED/SKIPPED_PACKAGES[]
│   └── install_custom()    eval <script>; → INSTALLED/SKIPPED_PACKAGES[]
│
├── src/dotfiles.sh
│   ├── link_dotfile()      ln -sf <repo>/dotfiles/<file> $HOME/<file>; → LINKED/SKIPPED_DOTFILES[]
│   ├── check_existing()    detect file vs symlink vs missing
│   └── backup_and_link()   mv <file> <file>.bak && ln -sf
│
└── src/setup-git-identity.sh (FEAT-0008)
    └── setup_git_identity()  check git config → prompt or warn → write ~/.gitconfig.local
```

### 2.2 Component Descriptions

| Component | File | Purpose |
|-----------|------|---------|
| Entrypoint | `install.sh` | Arg parsing, orchestration, profile loading |
| Utilities | `src/utils.sh` | Logging, guards, shared helpers |
| Validator | `src/validate.sh` | Pre-install YAML structure validation (FEAT-0006) |
| Package installer | `src/packages.sh` | One function per package type |
| Dotfile manager | `src/dotfiles.sh` | Symlink creation, collision handling |
| Git identity | `src/setup-git-identity.sh` | Prompt for name/email; write ~/.gitconfig.local (FEAT-0008) |
| Profile manifests | `profiles/*.yaml` | Declarative package lists per profile |
| Dotfiles | `dotfiles/` | Actual config files to symlink into $HOME |

---

## 3. Profile System

### 3.1 Inheritance Chain

```
base.yaml
├── desktop.yaml  (extends: base)
│   └── dev.yaml  (extends: desktop)
└── server.yaml   (extends: base)
```

### 3.2 Merge Semantics

When a profile has `extends: <parent>`, the installer:
1. Loads the parent profile (recursively, depth-first)
2. Merges the parent's package lists first
3. Appends the child's package lists after
4. Deduplicates within each type

No packages are removed by extending — inheritance is additive only.

### 3.3 Profile YAML Schema

```yaml
profile:
  name: base          # string, must match filename
  extends: null       # null | string (name of parent profile)

packages:
  apt:
    - curl
    - git
  snap:
    - code            # package name passed to `snap install`
  flatpak:
    - org.gimp.GIMP   # app-id passed to `flatpak install flathub`
  deb:
    - name: gh        # package name (used for dpkg -s idempotency check)
      url: https://github.com/cli/cli/releases/download/v2.67.0/gh_2.67.0_linux_amd64.deb
  custom:
    - cmd: "curl -fsSL https://example.com/install.sh | bash"
      idempotency_check: "command -v mytool"  # optional; skip if exits 0
```

---

## 4. Dotfile Management

### 4.1 Symlink Strategy

All files in `dotfiles/` are symlinked into `$HOME` with the same filename:

```
<repo>/dotfiles/.bashrc        →  ~/.bashrc
<repo>/dotfiles/.bash_aliases  →  ~/.bash_aliases
<repo>/dotfiles/.bash_profile  →  ~/.bash_profile
<repo>/dotfiles/.gitconfig     →  ~/.gitconfig
```

Subdirectories are mirrored:

```
<repo>/dotfiles/.config/nvim/  →  ~/.config/nvim/
```

### 4.3 Dotfile Conventions

| Rule | Detail |
|------|--------|
| Non-interactive guard | `.bashrc` returns early if `[[ $- != *i* ]]` — safe to source from scripts |
| No user identity in git | `.gitconfig` omits `user.name` / `user.email` — set per-machine by FEAT-0008 |
| No tool assumptions | Files only use tools present on stock Ubuntu 22.04 |
| Self-documenting | Each file is commented to explain every non-obvious setting |

### 4.2 Collision Handling

| State of `$HOME/<file>` | Default behaviour | With `--force` |
|------------------------|-------------------|----------------|
| Does not exist | Create symlink | Create symlink |
| Already correct symlink | Skip (no-op) | Skip (no-op) |
| Symlink to wrong target | Warn, skip | Replace symlink |
| Regular file | Warn, skip | Backup to `.bak`, replace |
| Directory | Warn, skip | Not replaced (manual action required) |

---

## 5. Package Installation

### 5.1 Per-Type Behaviour

| Type | Command | Idempotency check |
|------|---------|-------------------|
| `apt` | `sudo apt-get install -y` | `dpkg -s <pkg>` — skip if installed |
| `snap` | `sudo snap install` | `snap list <pkg>` — skip if installed |
| `flatpak` | `flatpak install -y flathub` | `flatpak info <id>` — skip if installed; auto-adds flathub remote |
| `deb` | `wget <url> && sudo dpkg -i` | `dpkg -s <name>` — skip if installed; http URLs blocked without `--force` |
| `custom` | `bash -c "<cmd>"` | optional `idempotency_check` field; if provided and exits 0, step is skipped |

### 5.2 Execution Order

Within a provisioning run, types are installed in this order:
1. `apt` — most common, required by others
2. `snap`
3. `flatpak`
4. `deb`
5. `custom`

---

## 6. Testing Architecture

### 6.1 Smoke Test Suite (FEAT-0004)

Docker-based smoke tests that provision a clean Ubuntu 22.04 container and assert the result.

```
tests/smoke/
├── Dockerfile          # FROM ubuntu:22.04; adds sudo+git+python3; COPYs repo; non-root testuser
├── run-tests.sh        # Build image; run each scenario; print pass/fail; clean up image
├── helpers.sh          # assert_cmd_success, assert_cmd_fails, assert_pkg_installed,
│                       # assert_symlink, assert_git_config, assert_file_exists, finish()
└── tests/
    ├── test-help.sh              # --help exits 0
    ├── test-unknown-profile.sh   # Unknown --profile exits non-zero
    ├── test-base-apt.sh          # All base.yaml apt packages installed
    ├── test-base-dotfiles.sh     # Symlinks + git config + aliases + live symlink
    ├── test-base-bash-login.sh   # bash --login exits 0; bash -n syntax checks
    ├── test-base-idempotency.sh  # Second run exits 0; symlinks still correct
    ├── test-base-dry-run.sh      # --dry-run: no packages installed, no symlinks created
    ├── test-validate-only.sh     # --validate-only: exits 0, "Validation passed", no changes
    ├── test-validate-invalid.sh  # invalid YAML: exits 1 with correct error messages
    ├── test-summary.sh                    # run summary present; idempotent 0-install; dry-run labels; --quiet
    ├── test-summary-partial.sh            # partial summary + "incomplete" header on failure
    ├── test-git-identity-fresh.sh         # first-time prompt writes ~/.gitconfig.local; git config returns values
    ├── test-git-identity-idempotent.sh    # second run skips prompt; ~/.gitconfig.local unchanged
    ├── test-git-identity-non-interactive.sh  # --non-interactive warns; no file created
    └── test-git-identity-standalone.sh   # src/setup-git-identity.sh works without install.sh
```

### 6.2 Test Runner Behaviour

| Behaviour | Detail |
|-----------|--------|
| Image build | `docker build --no-cache` by default; `--use-cache` flag for development |
| Scenario isolation | Each scenario runs in a fresh `docker run --rm` container |
| Profile filter | `--profile <name>` runs only scenarios tagged with that profile |
| Cleanup | Image removed after all scenarios complete (`docker image rm`) |
| Exit code | 0 if all pass; 1 if any fail |

### 6.3 CI Integration

`.github/workflows/smoke-tests.yml` triggers on every PR and push to `main`.

---

## 7. Security Considerations

| Concern | Approach |
|---------|----------|
| sudo scope | Only individual package install commands; not the whole script |
| Custom scripts | Must be reviewed before adding to a profile; no auto-fetching of scripts |
| No secrets | No credentials, tokens, or passwords anywhere in the repo |
| Dotfile scope | Only files in `dotfiles/`; no writes outside `$HOME` |
| deb downloads | wget to a temp file; checksum validation recommended in future ADR |

---

## 7. Development Standards

### 7.1 Script Layout (every script)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source dependencies
source "$(dirname "$0")/utils.sh"

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions
function_name() {
  local arg1="$1"
  # implementation
}

# Main (only in entrypoint scripts)
main() {
  # ...
}
main "$@"
```

### 7.2 Key Patterns

| Pattern | Usage |
|---------|-------|
| Guard clause | Check preconditions at top; exit early |
| Named functions | All logic in named functions, not inline |
| Local variables | `local var=` inside functions; never global side effects |
| Idempotency check | Check state before acting, not just after |
| Structured logging | `log_info`, `log_warn`, `log_error` from utils.sh |

---

## 8. Appendix

### A. Architecture Decision Records

See `../decisions/` for ADRs:
- (none yet — decisions so far documented in CONTEXT.md)

### B. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-25 | Jerry | Initial architecture for dotfiles provisioning system |
| 1.1.0 | 2026-02-25 | Jerry | FEAT-0002: deb/custom schema, idempotency table updated |
| 1.2.0 | 2026-02-25 | Jerry | FEAT-0003: documented actual dotfiles and dotfile conventions |
| 1.3.0 | 2026-02-25 | Jerry | FEAT-0004: added testing architecture section (Docker smoke tests) |
| 1.4.0 | 2026-02-25 | Jerry | FEAT-0005: added log_dry_run() to utils diagram; --dry-run to arg list; dry-run test to smoke suite |
| 1.5.0 | 2026-02-25 | Jerry | FEAT-0006: added src/validate.sh to component diagram; --validate-only to arg list; validation tests to smoke suite |
| 1.6.0 | 2026-02-26 | Jerry | FEAT-0007: added summary arrays + trap + print_summary() to component diagram; --quiet to arg list; summary tests to smoke suite |
| 1.7.0 | 2026-02-26 | Jerry | FEAT-0008: added src/setup-git-identity.sh to component diagram; --non-interactive to arg list; git identity tests to smoke suite |
