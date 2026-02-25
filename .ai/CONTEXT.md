# Project Context

> **For AI Assistants**: This is the master context file. Start here for a complete understanding of the project.

<!--
  AI PROCESSING INSTRUCTIONS:
  1. Read this file first to understand project scope
  2. Follow links to detailed documents as needed
  3. Check config.yaml for behavior preferences
  4. Respect patterns in architecture/PATTERNS.md
-->

## Quick Reference

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [SPEC.md](specs/SPEC.md) | Product requirements | Understanding WHAT to build |
| [ARCHITECTURE.md](architecture/ARCHITECTURE.md) | System design | Understanding HOW it's built |
| [PATTERNS.md](architecture/PATTERNS.md) | Code conventions | Writing or reviewing code |
| [decisions/](decisions/) | ADRs | Understanding WHY decisions were made |

---

## 1. Project Summary

### Identity
- **Name**: dotfiles
- **Type**: CLI / Provisioning Scripts
- **Stage**: Greenfield

### One-Liner
> Stage 2 Ubuntu provisioning system that installs packages (apt, snap, flatpak, deb, custom) and applies dotfiles via symlinks, driven by a declarative YAML manifest with support for role-based profiles.

### Tech Stack
| Layer | Technology |
|-------|------------|
| Language | Bash |
| Config | YAML |
| Package managers | apt, snap, flatpak, direct .deb, custom scripts |
| Dotfile strategy | Symlinks into $HOME |
| Platform | Ubuntu (Linux) |

### Provisioning Framework Context
- **Stage 1**: Unattended Ubuntu base install via `Autoinstall.yaml` — installs OS, sets up users/partitions
- **Stage 2** (this repo): Post-boot provisioning — installs tools, applies configs, links dotfiles

---

## 2. Current State

### Active Work
- [x] FEAT-0001: Core provisioning engine (install.sh + YAML manifest + apt + profile system)
- [x] FEAT-0002: Multi-type package support (snap, flatpak, deb, custom)
- [ ] FEAT-0003 through FEAT-0014: Pending (see specs.config.yaml)

### Recent Changes
- 2026-02-25: Repository initialized; FEAT-0001 and FEAT-0002 implemented

### Known Issues
- None

---

## 3. Key Concepts

### Domain Model
```
[Profile] ──extends──> [Base Profile]
    │
    └──includes──> [Package List]
                       │
                       ├── apt packages
                       ├── snap packages
                       ├── flatpak packages
                       ├── deb packages (URL)
                       └── custom scripts

[Dotfiles repo] ──symlinked into──> [$HOME]
```

### Profile Hierarchy
| Profile | Inherits From | Purpose |
|---------|--------------|---------|
| base | — | Core CLI tools every machine needs |
| desktop | base | GUI apps and desktop environment tools |
| server | base | Server/headless tooling |
| dev | desktop | Full developer environment |

### Critical Paths
1. **Full provisioning**: `./install.sh --profile dev` → reads profile YAML → installs packages by type → links dotfiles
2. **Package install only**: `./install.sh --profile base --skip-dotfiles`
3. **Dotfiles only**: `./install.sh --dotfiles-only`

---

## 4. Codebase Navigation

### Entry Points
| Purpose | Location |
|---------|----------|
| Main provisioning script | `install.sh` |
| Package manifests | `profiles/` |
| Dotfiles | `dotfiles/` |
| Package type installers | `src/` |

### Key Files
```
dotfiles/
├── install.sh                  # Main entrypoint
├── profiles/
│   ├── base.yaml              # Base profile (always applied)
│   ├── desktop.yaml           # Desktop profile
│   ├── server.yaml            # Server profile
│   └── dev.yaml               # Developer profile
├── dotfiles/                   # Actual config files to symlink
│   └── ...
└── src/                        # Package type install helpers
    ├── packages.sh            # Package install dispatcher
    ├── dotfiles.sh            # Symlink management
    └── utils.sh               # Shared utilities (logging, etc.)
```

### Module Map
```
install.sh
  → src/utils.sh              (logging, error handling)
  → profiles/<name>.yaml      (package manifest for profile)
  → src/packages.sh           (dispatch by package type)
      → apt-get install
      → snap install
      → flatpak install
      → wget + dpkg -i (deb)
      → custom script runner
  → src/dotfiles.sh           (symlink $HOME dotfiles)
```

---

## 5. Development Rules

### Must Follow
1. **Idempotent** - Running install.sh multiple times must be safe (no duplicate installs, no broken symlinks)
2. **Profiles only change by spec** - Package list changes require an approved spec
3. **No secrets in repo** - No credentials, tokens, or passwords anywhere
4. **Bash compatibility** - Scripts must work on bash 5.x (Ubuntu 22.04+)
5. **Fail loudly** - Exit non-zero and print clear errors; never silently skip failures

### Prefer
1. `set -euo pipefail` in all scripts
2. Named functions over inline logic
3. YAML for all configuration (not hardcoded lists in scripts)
4. `sudo` only where explicitly needed (not blanket sudo on the whole script)

### Avoid
1. Hardcoding package lists in shell scripts — use YAML manifests
2. `curl | bash` without checksum verification
3. Modifying system files outside of explicitly stated scope
4. Assuming internet access — check connectivity before fetching

---

## 6. Testing Requirements

### Coverage Expectations
| Type | Target | Focus |
|------|--------|-------|
| Unit | Key functions | YAML parsing, symlink logic, package dispatch |
| Integration | Per package type | Install a test package of each type in CI |
| Smoke | Full run | Run install.sh --profile base in a Docker/VM |

### Test Locations
```
tests/
├── unit/           # bats or shellspec tests for individual functions
└── smoke/          # Docker-based full provisioning smoke tests
```

---

## 7. Environment Setup

### Prerequisites
```bash
# Stage 1 must already be complete (Ubuntu installed)
ubuntu >= 22.04
bash >= 5.0
git >= 2.x
```

### Quick Start
```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh --profile base
```

### No Environment Variables Required
All configuration is declarative YAML. No `.env` files needed.

---

## 8. AI Assistant Guidelines

### When Generating Code
1. **Bash first** - All scripts in bash; no Python/Ruby/etc. dependencies for provisioning
2. **YAML config** - Package lists always in YAML, never hardcoded in scripts
3. **Idempotent** - Every operation must be safe to run twice
4. **Minimal sudo** - Elevate only for operations that require it

### When Answering Questions
1. **Reference files** - Point to specific script locations
2. **Check profiles/** - Package decisions belong in profile YAML, not scripts

### When Debugging
1. **Check utils.sh** - Logging and error helpers live there
2. **Check profile YAML** - Most "why isn't X installed" issues are manifest issues

### Forbidden Actions
- Do not add packages to profiles without a spec
- Do not modify system-level config files (fstab, sudoers, etc.) without explicit spec
- Do not add network calls without connectivity checks
- Do not store credentials or API keys anywhere in the repo

---

## 9. Related Documentation

### Internal
- [specs/](../specs/) - Feature specifications
- [architecture/](architecture/) - Technical architecture
- [decisions/](decisions/) - Architecture Decision Records

---

## Document Maintenance

| Field | Value |
|-------|-------|
| Last Updated | 2026-02-25 |
| Update Frequency | After each implemented spec |
| Owner | Jerry |
