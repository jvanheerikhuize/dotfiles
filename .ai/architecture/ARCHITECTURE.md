# System Architecture

> **For AI Assistants**: This document defines HOW the provisioner is built. For WHAT it does, see `../CONTEXT.md`. For WHY decisions were made, see `../decisions/`.

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.1.0 |
| Status | Current |
| Last Updated | 2026-02-26 |
| Owner | Jerry van Heerikhuize |

---

## 1. Architecture Overview

This is a **single-machine CLI provisioner**. There is no network service, no database, and no API. The entire system is a set of Bash scripts that run on a fresh Ubuntu 22.04 host to configure it to a declared state.

### 1.1 System Context

```
┌─────────────────────────────────────────────────────────────┐
│                     Operator (Jerry)                         │
│         runs:  bash install.sh --profile <name>             │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     install.sh (entrypoint)                  │
│  Reads CLI flags → loads profile YAML → sources modules     │
│  → installs packages → symlinks dotfiles → runs bootstrap   │
└──────────────────────────┬──────────────────────────────────┘
                           │ writes / symlinks to
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  $HOME / System                              │
│  ~/.bashrc  ~/.gitconfig  ~/.ssh/  apt packages  snaps  … │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Architecture Style

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| Overall style | Shell script library | No runtime deps beyond Bash + python3 |
| Config format | YAML (profiles) | Human-readable, supports inheritance |
| Config parsing | `python3` inline | Already available on Ubuntu 22.04, no extra install |
| Testing | Docker smoke tests | Reproducible, isolated, CI-compatible |

---

## 2. Component Architecture

### 2.1 Component Map

```
install.sh  (main entrypoint)
    │
    ├── source  src/utils.sh              # Logging, YAML helpers, guards
    ├── source  src/validate.sh           # Profile YAML structure validation
    ├── source  src/packages.sh           # Package install functions (apt/snap/flatpak/deb/custom)
    ├── source  src/dotfiles.sh           # Dotfile symlink management
    ├── source  src/setup-git-identity.sh # Interactive git user.name/email bootstrap
    └── source  src/setup-ssh.sh          # ed25519 keypair, ~/.ssh/config, public key print
```

### 2.2 Component Descriptions

| Component | File | Purpose |
|-----------|------|---------|
| Entrypoint | `install.sh` | Parses CLI flags, loads profile, calls all modules in order |
| Utilities | `src/utils.sh` | Logging functions, YAML parsing helpers, safety guards |
| Validator | `src/validate.sh` | Validates profile YAML structure before any installs |
| Package manager | `src/packages.sh` | Installs apt / snap / flatpak / deb / custom packages |
| Dotfile linker | `src/dotfiles.sh` | Symlinks `dotfiles/*` → `$HOME`, backs up conflicts |
| Git bootstrap | `src/setup-git-identity.sh` | Prompts for git identity, writes `~/.gitconfig` |
| SSH bootstrap | `src/setup-ssh.sh` | Generates ed25519 keypair, writes `~/.ssh/config` |

---

## 3. Data Flow

### 3.1 Happy-Path Execution Order

```
CLI invocation
    │
    ▼
parse_args()                    # install.sh — sets DRY_RUN, PROFILE, DOTFILES_ONLY, …
    │
    ▼
require_not_root()              # src/utils.sh — abort if running as root
    │
    ▼
validate_profiles()             # src/validate.sh — check YAML structure; exit on error
    │
    ▼
load_profile()                  # install.sh — reads profiles/<name>.yaml + all extends:
    │
    ▼
deduplicate_packages()          # install.sh — merge inherited + own package lists
    │
    ▼
install_packages()              # src/packages.sh — apt → snap → flatpak → deb → custom
    │
    ▼
apply_dotfiles()                # src/dotfiles.sh — symlink dotfiles/* → $HOME
    │
    ▼
setup_git_identity()            # src/setup-git-identity.sh — prompt / write ~/.gitconfig
    │
    ▼
setup_ssh_key()                 # src/setup-ssh.sh — generate key / write config / print pubkey
    │
    ▼
print_summary()                 # install.sh — installed / skipped / linked / warnings table
```

### 3.2 Flag Effects on Data Flow

| Flag | Effect |
|------|--------|
| `--dry-run` | All write operations replaced with `log_dry_run` no-ops |
| `--dotfiles-only` | Skips `install_packages()` entirely |
| `--skip-dotfiles` | Skips `apply_dotfiles()` entirely |
| `--validate-only` | Exits after `validate_profiles()` |
| `--non-interactive` | Skips interactive prompts in git/SSH bootstrap scripts |
| `--force` | `apply_dotfiles()` overwrites existing files (backs up as `.bak`) |
| `--quiet` | Suppresses `log_info` and `log_step`; errors still shown |

---

## 4. Profile Architecture

### 4.1 Profile Inheritance

Profiles extend each other via the `extends:` key. Inheritance is additive — child profiles add to parent package lists; they do not override them.

```
base.yaml       ← foundation: core apt packages, shell dotfiles
    ↑
desktop.yaml    ← extends base: GUI tools, fonts, desktop apps
    ↑
dev.yaml        ← extends desktop: developer tools, IDEs, SDKs

base.yaml       ← (also parent of)
    ↑
server.yaml     ← extends base: server/ops tools, no GUI
```

### 4.2 Profile YAML Structure

```yaml
name: "base"
extends: []          # or: ["desktop"] for child profiles

packages:
  apt:
    - git
    - curl
    - openssh-client
  snap:
    - name: "some-snap"
      classic: true
  flatpak: []
  deb: []
  custom: []

dotfiles:
  - src: ".bashrc"
    dest: "~/.bashrc"
```

### 4.3 Package Type Processing Order

```
apt   → snap   → flatpak   → deb   → custom
```

Each type is processed only if its list is non-empty. `deb` packages are downloaded to a temp dir and installed with `dpkg -i`. `custom` entries are raw shell commands.

---

## 5. Source Chain and `SCRIPT_DIR` Safety

### 5.1 The Problem

Every Bash script defines `SCRIPT_DIR` at global scope (needed for standalone execution). When `install.sh` sources a script (e.g. `src/setup-git-identity.sh`), that script's `SCRIPT_DIR` assignment overwrites `install.sh`'s own `SCRIPT_DIR`. Subsequent sources using `${SCRIPT_DIR}/src/...` then resolve incorrectly.

### 5.2 The Fix

`install.sh` captures the repo root into `_INSTALL_ROOT` **before** any source calls:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_INSTALL_ROOT="${SCRIPT_DIR}"   # immune to source clobbering

PROFILES_DIR="${_INSTALL_ROOT}/profiles"
DOTFILES_DIR="${_INSTALL_ROOT}/dotfiles"

source "${_INSTALL_ROOT}/src/utils.sh"
source "${_INSTALL_ROOT}/src/validate.sh"
# … all other sources use _INSTALL_ROOT …
```

All sourced scripts continue to define their own `SCRIPT_DIR` (for standalone use). `install.sh` never uses `SCRIPT_DIR` after the initial capture.

---

## 6. Test Architecture

### 6.1 Smoke Test Framework

```
tests/smoke/
├── Dockerfile          # ubuntu:22.04 base + sudo + git + python3 + openssh-client
├── run-tests.sh        # Build image, run each scenario, report pass/fail count
├── helpers.sh          # _pass, _fail, finish, assert_file_perms, assert_file_contains, …
└── tests/              # One script per test scenario
    ├── test-base.sh
    ├── test-dry-run.sh
    ├── test-dotfiles-only.sh
    ├── test-validate-only.sh
    ├── test-git-identity-fresh.sh
    ├── test-git-identity-idempotent.sh
    ├── test-ssh-key-fresh.sh
    ├── test-ssh-key-idempotent.sh
    ├── test-ssh-key-standalone.sh
    └── test-ssh-key-dry-run.sh
```

### 6.2 Test Execution Model

Each scenario is a **fresh `docker run`** against a pre-built image. The image bakes the entire working tree at build time (`COPY . /home/testuser/dotfiles`). There is no package caching between scenarios — packages installed in one scenario are NOT available in another.

**Consequence**: Any tool required by a test that runs `--dotfiles-only` (skipping `apt install`) must be pre-installed in the Dockerfile bootstrap layer.

### 6.3 Known Constraints

| Constraint | Reason | Workaround |
|------------|--------|------------|
| `--force` required in tests | `useradd -m` pre-creates `/etc/skel` copies | Always pass `--force` in smoke tests |
| `openssh-client` in Dockerfile | SSH tests use `--dotfiles-only` | Pre-install in Dockerfile RUN layer |
| `NON_INTERACTIVE=true` needed | Docker has no TTY for prompts | Export before running install.sh |

---

## 7. Architecture Decision Records

See [`../decisions/`](../decisions/) for full ADRs. Key decisions:

| ADR | Decision | Status |
|-----|----------|--------|
| ADR-001 | Use ed25519 key type for SSH keypair | Accepted |
| ADR-002 | No passphrase in non-interactive SSH key generation | Accepted |
| ADR-003 | Add `openssh-client` to base profile (not just Dockerfile) | Accepted |

---

## 8. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-26 | Jerry van Heerikhuize | Initial real content (FEAT-0016) |
| 1.1.0 | 2026-02-26 | Jerry van Heerikhuize | Added §5 source chain safety, §6 test constraints |
