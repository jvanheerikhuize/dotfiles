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
| [DIRECTIVES.md](DIRECTIVES.md) | Mandatory AI rules | **Always — before anything else** |
| [memory/AUTHORIZATIONS.md](memory/AUTHORIZATIONS.md) | What the AI is/isn't allowed to do | Before any gated action |
| [memory/SESSION_LOG.md](memory/SESSION_LOG.md) | Session history | Start of every session |
| [memory/LEARNINGS.md](memory/LEARNINGS.md) | Accumulated project knowledge | Before touching existing code |
| [memory/TRACEABILITY.md](memory/TRACEABILITY.md) | Request → code audit trail | When implementing or investigating |
| [architecture/ARCHITECTURE.md](architecture/ARCHITECTURE.md) | System design | Understanding HOW it's built |
| [architecture/PATTERNS.md](architecture/PATTERNS.md) | Code conventions | Writing or reviewing code |
| [decisions/](decisions/) | ADRs | Understanding WHY decisions were made |

---

## 1. Project Summary

### Identity

- **Name**: dotfiles provisioner
- **Type**: CLI / shell provisioner
- **Stage**: MVP / Growth
- **Author**: Jerry van Heerikhuize

### One-Liner

> A Bash-driven Stage 2 provisioner for Ubuntu 22.04 that installs packages, symlinks dotfiles, and bootstraps developer identity (git config, SSH key) from a declarative YAML profile in a single `./install.sh` run.

### Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Bash (scripts), YAML (profiles) |
| Config parsing | `python3` inline (default on Ubuntu 22.04) |
| Package management | apt, snap, flatpak, deb URL, custom shell command |
| Tests | Docker smoke tests (`ubuntu:22.04` container) |
| CI | GitHub Actions |

---

## 2. Current State

### Recently Completed

- **FEAT-0009** (SSH key setup): generates `~/.ssh/id_ed25519`, sets permissions, writes `~/.ssh/config`, prints public key for GitHub. Implemented 2026-02-26.
- **FEAT-0008** (git identity bootstrap): interactive `user.name`/`user.email` prompt; writes directly to `~/.gitconfig`. Implemented 2026-02-23.
- **FEAT-0007** (run summary report): summary table at end of run showing installed, skipped, linked, and warnings.
- **FEAT-0015** (AI governance system): DIRECTIVES.md, `.ai/` memory structure, ADR infra, template-sync runbook.

### Active / Pending (v1.1)

- [ ] **FEAT-0012** — Log to file (`~/.local/logs/dotfiles/`) — status: approved
- [ ] **FEAT-0014** — Connectivity check before installs — status: approved

### Approved for v1.2

- [ ] **FEAT-0010** — Nerd Font installation (`~/.local/share/fonts/`)
- [ ] **FEAT-0011** — GNOME dconf settings (desktop profile only)
- [ ] **FEAT-0013** — `--status` drift-detection command

### Known Issues

- None at this time. All CI tests are green.

---

## 3. Key Concepts

### Profile System

Profiles are YAML files in `profiles/`. Each profile declares packages to install and dotfiles to symlink. Profiles support `extends:` inheritance — packages are merged base-first, additive only.

```
base  ←  desktop  ←  dev
base  ←  server
```

### Package Types

| Type | Description |
|------|-------------|
| `apt` | Standard Ubuntu package manager |
| `snap` | Snap packages (optional `--classic` flag) |
| `flatpak` | Flatpak packages (from Flathub) |
| `deb` | Direct `.deb` URL download + `dpkg -i` |
| `custom` | Arbitrary shell command |

### Dotfile Symlinking

Files in `dotfiles/` are symlinked to `$HOME`. If a file already exists, `--force` backs it up as `.bak` before overwriting. Smoke tests always pass `--force` because `useradd -m` pre-creates `/etc/skel` copies in the test user's `$HOME`.

### Bootstrap Scripts

After packages and dotfiles, `install.sh` calls two interactive bootstrap scripts:

1. `src/setup-git-identity.sh` — prompts for `user.name` and `user.email`, writes `~/.gitconfig`
2. `src/setup-ssh.sh` — generates `~/.ssh/id_ed25519`, writes `~/.ssh/config`, prints public key

Both respect `NON_INTERACTIVE=true` (set automatically in smoke tests) and `DRY_RUN=true`.

---

## 4. Codebase Navigation

### Entry Points

| Purpose | Location | Notes |
|---------|----------|-------|
| Main provisioner | `install.sh` | Run as non-root user with sudo access |
| Git identity setup | `src/setup-git-identity.sh` | Also runnable standalone |
| SSH key setup | `src/setup-ssh.sh` | Also runnable standalone |
| Smoke test runner | `tests/smoke/run-tests.sh` | Requires Docker |

### `install.sh` Flags

| Flag | Description |
|------|-------------|
| `--profile <name>` | Load `profiles/<name>.yaml` (required) |
| `--skip-dotfiles` | Skip symlink step |
| `--dotfiles-only` | Skip package install; apply dotfiles only |
| `--force` | Overwrite existing dotfiles (backup as `.bak`) |
| `--dry-run` | Preview all actions without executing |
| `--validate-only` | Validate profile YAML and exit |
| `--non-interactive` | Skip interactive prompts (git identity, SSH) |
| `--quiet` | Suppress non-error output |
| `--help` | Print usage |

### Key Files

```
install.sh                        # Main entrypoint — sources all src/ modules
profiles/
├── base.yaml                     # Base profile: core apt packages + dotfiles
├── desktop.yaml                  # Desktop: extends base + GUI tools
├── server.yaml                   # Server: extends base + server tools
└── dev.yaml                      # Dev: extends desktop + dev tools
src/
├── utils.sh                      # Logging (log_info/warn/error/step/dry_run), yaml_get*, guards
├── validate.sh                   # validate_profiles(): YAML structure checks
├── packages.sh                   # install_apt/snap/flatpak/deb/custom functions
├── dotfiles.sh                   # apply_dotfiles(): symlink management
├── setup-git-identity.sh         # Interactive git user.name/email → ~/.gitconfig
└── setup-ssh.sh                  # Generate ed25519 keypair, ~/.ssh/config, print pubkey
dotfiles/
├── .bashrc                       # Bash config (sources .bash_aliases)
├── .bash_aliases                 # Aliases
├── .bash_profile                 # Login shell entry
└── .gitconfig                    # Git config (includes ~/.gitconfig.local)
tests/smoke/
├── Dockerfile                    # ubuntu:22.04 + sudo + git + python3 + openssh-client
├── run-tests.sh                  # Orchestrates all test scenarios via docker run
├── helpers.sh                    # _pass/_fail, assert_file_perms, assert_file_contains, etc.
└── tests/                        # Individual test scripts (one per scenario)
```

---

## 5. Development Rules

### Must Follow

1. **Spec before code** — Features require an approved spec in `specs/features/` and `specs.config.yaml`
2. **Read LEARNINGS.md first** — Before modifying any `src/` file, read `.ai/memory/LEARNINGS.md`
3. **Use existing patterns** — Check `PATTERNS.md` before writing new Bash
4. **No secrets in code** — Use environment variables or interactive prompts only
5. **Update architecture docs** — Update CONTEXT.md / ARCHITECTURE.md / PATTERNS.md before committing if project state changed

### Prefer

1. Named functions with `local` variables over inline logic
2. `if/then` over `[[ cond ]] && cmd` (see §6 in DIRECTIVES.md)
3. Idempotent operations — always check state before acting
4. Explicit paths via `_INSTALL_ROOT` (not relative `./`) to survive `source`-ing

### Avoid

1. Global variable mutation in sourced scripts
2. Hardcoded package names in scripts (belongs in profiles)
3. Direct `echo` for user output (use logging functions)
4. Root execution — scripts must run as a normal user with sudo access

---

## 6. Testing Requirements

### Test Framework

Docker-based smoke tests. Each scenario is a fresh `docker run` against a pre-built image. Tests are shell scripts in `tests/smoke/tests/`.

```
tests/smoke/
├── run-tests.sh          # Build image, iterate scenarios, report pass/fail
├── Dockerfile            # Base image: ubuntu:22.04 + prereqs
├── helpers.sh            # _pass, _fail, finish, assert_* helpers
└── tests/
    ├── test-base.sh
    ├── test-dry-run.sh
    ├── test-dotfiles-only.sh
    ├── test-validate-only.sh
    ├── test-git-identity-*.sh
    └── test-ssh-key-*.sh
```

### Running Tests Locally

```bash
bash tests/smoke/run-tests.sh
```

Requires Docker. Each test run rebuilds the image to bake the current working tree.

---

## 7. Environment Setup

### Prerequisites

```bash
# Required to run install.sh
bash >= 5.0
python3 >= 3.8      # for YAML parsing (default on Ubuntu 22.04)
sudo access

# Required to run smoke tests
docker >= 20.10
```

### Quick Start

```bash
# Install using base profile
bash install.sh --profile base

# Dry run first (safe preview)
bash install.sh --profile base --dry-run

# Run smoke tests
bash tests/smoke/run-tests.sh
```

---

## 8. AI Assistant Guidelines

### When Generating Code

1. **Read before writing** — Read the relevant `src/` file and `PATTERNS.md` first
2. **Match style** — Follow the Bash patterns in `PATTERNS.md` exactly
3. **Minimal changes** — Don't refactor unrelated code
4. **Include smoke tests** — Add a test scenario for each acceptance criterion

### When Answering Questions

1. **Reference files** — Point to specific file paths and line numbers
2. **Cite architecture** — Link to relevant ADRs in `.ai/decisions/`
3. **Stay current** — Check "Recent Changes" and "Active Work" above

### When Debugging

1. **Check LEARNINGS.md** — Review accumulated gotchas before diagnosing
2. **Trace the source chain** — `install.sh` sources all `src/` modules; check for `SCRIPT_DIR` clobbering
3. **Verify Docker context** — Smoke tests run `--dotfiles-only`; packages must be pre-installed in Dockerfile

---

## 9. Related Documentation

### Internal

- [specs/](../specs/) — Feature specifications (YAML)
- [architecture/](architecture/) — Technical architecture
- [decisions/](decisions/) — Architecture Decision Records
- [docs/runbooks/template-sync.md](../docs/runbooks/template-sync.md) — How to pull upstream template updates

---

## Document Maintenance

| Field | Value |
|-------|-------|
| Last Updated | 2026-02-26 |
| Update Frequency | After every implemented feature |
| Owner | Jerry van Heerikhuize |

### Update Checklist

When updating this document:

- [ ] Update "Current State" section (move completed items, add new active work)
- [ ] Review "Key Files" for accuracy (new scripts, renamed flags)
- [ ] Verify links are working
