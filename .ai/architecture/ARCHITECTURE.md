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
├── parse args (--profile, --skip-dotfiles, --dotfiles-only, --force, --help)
│
├── src/utils.sh
│   ├── log_info()      print timestamped info line
│   ├── log_warn()      print warning (does not exit)
│   ├── log_error()     print error and exit 1
│   └── require_cmd()   assert a command exists or exit
│
├── profile loader
│   ├── load profiles/<profile>.yaml
│   ├── resolve extends: chain (recursive merge, base first)
│   └── emit merged package lists per type
│
├── src/packages.sh
│   ├── install_apt()       sudo apt-get install -y <pkg>
│   ├── install_snap()      sudo snap install <pkg>
│   ├── install_flatpak()   flatpak install -y <pkg>
│   ├── install_deb()       wget <url> → sudo dpkg -i
│   └── install_custom()    eval <script>
│
└── src/dotfiles.sh
    ├── link_dotfile()      ln -sf <repo>/dotfiles/<file> $HOME/<file>
    ├── check_existing()    detect file vs symlink vs missing
    └── backup_and_link()   mv <file> <file>.bak && ln -sf
```

### 2.2 Component Descriptions

| Component | File | Purpose |
|-----------|------|---------|
| Entrypoint | `install.sh` | Arg parsing, orchestration, profile loading |
| Utilities | `src/utils.sh` | Logging, guards, shared helpers |
| Package installer | `src/packages.sh` | One function per package type |
| Dotfile manager | `src/dotfiles.sh` | Symlink creation, collision handling |
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
    - []
  flatpak:
    - []
  deb:
    - []              # URLs to .deb files
  custom:
    - []              # Shell commands to run
```

---

## 4. Dotfile Management

### 4.1 Symlink Strategy

All files in `dotfiles/` are symlinked into `$HOME` with the same filename:

```
<repo>/dotfiles/.bashrc     →  ~/.bashrc
<repo>/dotfiles/.gitconfig  →  ~/.gitconfig
<repo>/dotfiles/.vimrc      →  ~/.vimrc
```

Subdirectories are mirrored:

```
<repo>/dotfiles/.config/nvim/  →  ~/.config/nvim/
```

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

| Type | Command | Idempotency |
|------|---------|-------------|
| `apt` | `sudo apt-get install -y` | apt skips if already installed |
| `snap` | `sudo snap install` | snap no-ops if already installed |
| `flatpak` | `flatpak install -y` | flatpak no-ops if already installed |
| `deb` | `wget <url> && sudo dpkg -i` | `dpkg -i` upgrades/reinstalls; check version first |
| `custom` | eval of defined command | must be written idempotent by the spec author |

### 5.2 Execution Order

Within a provisioning run, types are installed in this order:
1. `apt` — most common, required by others
2. `snap`
3. `flatpak`
4. `deb`
5. `custom`

---

## 6. Security Considerations

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
