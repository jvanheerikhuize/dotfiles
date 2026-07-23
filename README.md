# dotfiles

Ubuntu provisioning system (Stage 2) — installs packages and applies dotfiles on a fresh Ubuntu install, driven by declarative YAML profiles.

## Overview

This repo is **Stage 2** of a two-stage Ubuntu provisioning framework:

| Stage | What it does | How |
|-------|-------------|-----|
| **Stage 1** | Base OS install | `Autoinstall.yaml` — unattended Ubuntu installer |
| **Stage 2** (this repo) | Tools, packages, dotfiles | `./install.sh` — this repo |

After Stage 1 you have a clean Ubuntu system. Running this repo gets you a fully configured machine.

## Quick Start

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh --profile base
```

## Profiles

Profiles are declared in `profiles/` as YAML. Each profile can extend a parent.

| Profile | Extends | Purpose |
|---------|---------|---------|
| `base` | — | Core CLI tools, applied to every machine |
| `desktop` | `base` | GUI apps, desktop environment tools |
| `server` | `base` | Headless/server tooling |
| `dev` | `desktop` | Full developer environment |

```bash
./install.sh --profile dev       # Full dev machine
./install.sh --profile server    # Server/headless
./install.sh --profile base      # Minimal base only
```

## Package Types

Packages are declared in profile YAML and dispatched by type:

| Type | Example | How it installs |
|------|---------|-----------------|
| `apt` | `curl`, `git`, `vim` | `sudo apt-get install` |
| `snap` | `code`, `slack` | `sudo snap install` |
| `flatpak` | `org.gimp.GIMP` | `flatpak install` |
| `deb` | URL to `.deb` file | `wget` + `sudo dpkg -i` |
| `custom` | any script | runs a defined shell command |

## Dotfiles

Dotfiles live in `dotfiles/` and are symlinked into `$HOME`:

```
dotfiles/.bashrc      →  ~/.bashrc
dotfiles/.gitconfig   →  ~/.gitconfig
dotfiles/.vimrc       →  ~/.vimrc
```

- Existing symlinks pointing to the correct target are left untouched (idempotent)
- Existing regular files produce a warning and are skipped
- Pass `--force` to replace and back up existing files (`.bak`)

## Flags

```
./install.sh [--profile PROFILE] [--skip-dotfiles] [--dotfiles-only] [--force]
             [--dry-run] [--validate-only] [--quiet] [--non-interactive] [--help]

  --profile PROFILE   Profile to apply (default: base)
  --skip-dotfiles     Install packages only, skip symlinks
  --dotfiles-only     Apply symlinks only, skip packages
  --force             Replace existing dotfiles (backs up to .bak)
  --dry-run           Preview what would be installed/linked; make no changes
  --validate-only     Validate profile YAML structure only; skip installs and dotfiles
  --quiet             Suppress per-step log lines; summary is always shown
  --non-interactive   Skip the git identity prompt; emit a warning instead
  --help              Show this message
```

`install.sh` also bootstraps a git identity (`~/.gitconfig.local`) and an
ed25519 SSH keypair (`~/.ssh/id_ed25519`) after dotfiles/packages are applied.
Both steps are idempotent (skipped if already configured) and can be run
standalone:

```bash
src/setup-git-identity.sh [--non-interactive]
src/setup-ssh.sh [--non-interactive]
```

## Repository Structure

```
dotfiles/
├── install.sh                  # Main entrypoint
├── profiles/
│   ├── base.yaml              # Base profile
│   ├── desktop.yaml           # Desktop profile (extends: base)
│   ├── server.yaml            # Server profile (extends: base)
│   └── dev.yaml               # Dev profile (extends: desktop)
├── dotfiles/                   # Config files to symlink into $HOME
├── src/
│   ├── utils.sh               # Logging, error handling, helpers
│   ├── packages.sh            # Package install dispatcher
│   ├── dotfiles.sh            # Symlink management
│   ├── validate.sh            # Profile YAML structure validation (sourced only)
│   ├── setup-git-identity.sh  # Git identity bootstrap (standalone-runnable)
│   └── setup-ssh.sh           # SSH keypair bootstrap (standalone-runnable)
├── tests/
│   └── smoke/                  # Docker-based smoke test suite (19 scenarios)
│       ├── run-tests.sh       # Test runner — see Testing Playbooks below
│       ├── Dockerfile
│       ├── helpers.sh
│       └── tests/              # One script per scenario
├── memory/                      # File-based agent-memory knowledge base
│   └── AGENT.md                # Start here for agent-memory context
├── scripts/                     # Knowledge-base tooling (kb.py, visualize.py)
├── specs/                      # Feature specifications (spec-driven dev)
│   └── features/
│       └── FEAT-0001-core-provisioning-engine.yaml
├── .github/workflows/
│   ├── smoke-tests.yml        # Runs tests/smoke/run-tests.sh on PR/push to main
│   └── kb-lint.yml            # Lints memory/ knowledge base
└── .ai/                         # AI assistant context
    └── CONTEXT.md             # Start here for AI context
```

`memory/` and `.ai/` cover different concerns and are meant to coexist rather
than merge: `memory/` is a scaffolded copy of the
[agent-memory knowledge base](https://github.com/jvanheerikhuize/knowledge-base)
(an agent's own cross-session memory — facts, procedures, past episodes),
while `.ai/` is this repo's own AI-assistant governance system (ADRs,
authorizations, request-to-code traceability, architecture docs). See the
knowledge base README's "Relationship to other AI-context systems" section
for the reasoning behind the split.

## Profile YAML Format

```yaml
# profiles/base.yaml
profile:
  name: base
  extends: null   # or a profile name

packages:
  apt:
    - curl
    - git
    - vim
  snap: []
  flatpak: []
  deb: []
  custom: []
```

## Development

This repo uses **Specification-Driven Development** — all changes to provisioning behaviour start with a spec in `specs/features/`.

See [specs/features/FEAT-0001-core-provisioning-engine.yaml](specs/features/FEAT-0001-core-provisioning-engine.yaml) for the first feature spec and [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.

### Adding a Package

1. Write a spec if it's a new feature/profile change
2. Add the package to the appropriate profile YAML
3. Test with `./install.sh --profile <profile>` on a clean machine or container

### Testing Playbooks

All tests run in Docker containers built from a clean `ubuntu:22.04` image —
no host-machine side effects. Requires Docker.

**Run the full smoke test suite** (what CI runs on every PR and push to `main`,
see `.github/workflows/smoke-tests.yml`):

```bash
tests/smoke/run-tests.sh
```

**Iterate on a single profile during development** (reuses Docker layer
cache for faster rebuilds; only runs scenarios tagged for that profile plus
profile-agnostic ones):

```bash
tests/smoke/run-tests.sh --profile base --use-cache
```

**Add a new scenario:**

1. Write `tests/smoke/tests/test-<name>.sh` — a self-contained script that
   exits `0` on pass, non-zero on fail.
2. Register it in `SCENARIO_DEFS` in `tests/smoke/run-tests.sh` as
   `"<name>|<profile-or-all>|test-<name>.sh"`.
3. Run `tests/smoke/run-tests.sh --profile <profile>` to confirm it passes
   in isolation before running the full suite.

**Debug a failing scenario** by running it directly against the built image
instead of through the full suite:

```bash
docker build --tag dotfiles-smoke-test --file tests/smoke/Dockerfile .
docker run --rm -it dotfiles-smoke-test bash /home/testuser/dotfiles/tests/smoke/tests/test-base-apt.sh
```

**Manual smoke test** without the test harness (useful for exploring behavior
interactively):

```bash
docker run --rm -it ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y git &&
  git clone <repo> ~/dotfiles &&
  cd ~/dotfiles && ./install.sh --profile base
"
```

Scenario coverage includes: `--help`/unknown-profile argument handling,
package installation (`base-apt`), dotfile symlinking and idempotency,
`--dry-run` and `--validate-only` no-op guarantees, run summaries (full and
partial-failure), and the git-identity/SSH-key bootstrap flows (fresh,
idempotent, non-interactive, dry-run, and standalone-script invocation). Run
`tests/smoke/run-tests.sh --help` for the full, current scenario list.

## Requirements

- Ubuntu 22.04+
- bash 5.x
- git (to clone the repo — present after Stage 1)
- internet connection (for package downloads)
- Docker (only for running the smoke test suite under `tests/smoke/`)

## Author

Jerry van Heerikhuize — [@jvanheerikhuize](https://github.com/jvanheerikhuize)
