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
./install.sh [--profile PROFILE] [--skip-dotfiles] [--dotfiles-only] [--force] [--help]

  --profile PROFILE   Profile to apply (default: base)
  --skip-dotfiles     Install packages only, skip symlinks
  --dotfiles-only     Apply symlinks only, skip packages
  --force             Replace existing dotfiles (backs up to .bak)
  --help              Show this message
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
│   └── dotfiles.sh            # Symlink management
├── specs/                      # Feature specifications (spec-driven dev)
│   └── features/
│       └── FEAT-0001-core-provisioning-engine.yaml
└── .ai/                        # AI assistant context
    └── CONTEXT.md             # Start here for AI context
```

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

### Running Tests

```bash
# Smoke test in Docker (requires Docker)
docker run --rm -it ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y git &&
  git clone <repo> ~/dotfiles &&
  cd ~/dotfiles && ./install.sh --profile base
"
```

## Requirements

- Ubuntu 22.04+
- bash 5.x
- git (to clone the repo — present after Stage 1)
- internet connection (for package downloads)

## Author

Jerry van Heerikhuize — [@jvanheerikhuize](https://github.com/jvanheerikhuize)
