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
dotfiles/.bashrc        →  ~/.bashrc
dotfiles/.bash_aliases  →  ~/.bash_aliases
dotfiles/.bash_profile  →  ~/.bash_profile
dotfiles/.gitconfig     →  ~/.gitconfig
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
├── profiles/                   # Declarative package manifests (YAML)
│   ├── base.yaml              # Base profile
│   ├── desktop.yaml           # Desktop profile (extends: base)
│   ├── server.yaml            # Server profile (extends: base)
│   └── dev.yaml               # Dev profile (extends: desktop)
├── dotfiles/                   # Config files to symlink into $HOME
│   ├── .bashrc
│   ├── .bash_aliases
│   ├── .bash_profile
│   └── .gitconfig
├── src/                        # Library scripts (sourced by install.sh)
│   ├── utils.sh               # Logging, guards, YAML parsing helpers
│   ├── validate.sh            # Profile YAML structure validation
│   ├── packages.sh            # Package install dispatcher (apt/snap/flatpak/deb/custom)
│   ├── dotfiles.sh            # Symlink management
│   ├── setup-git-identity.sh  # Git identity bootstrap (standalone-runnable)
│   └── setup-ssh.sh           # SSH keypair bootstrap (standalone-runnable)
├── README.md
├── CONTRIBUTING.md
├── SECURITY.md
└── LICENSE
```

The tree above is the whole repository — there is no build step, no runtime
dependency beyond bash and `python3` (used only for YAML parsing, present by
default on Ubuntu). `src/*.sh` are libraries: `install.sh` sources them, and
`setup-git-identity.sh` / `setup-ssh.sh` can additionally be run on their own.

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

The repo is plain bash driven by declarative YAML — no build step and nothing to
compile. See [CONTRIBUTING.md](CONTRIBUTING.md) for conventions.

### Adding a package

1. Add the package under the right type (`apt`/`snap`/`flatpak`/`deb`/`custom`) in
   the appropriate `profiles/*.yaml`. Put it in the most general profile that
   should get it — `base` reaches every machine, `desktop`/`server`/`dev` narrow
   it down.
2. Preview the effect without touching the system:
   ```bash
   ./install.sh --profile <profile> --dry-run
   ```
3. Apply it: `./install.sh --profile <profile>`. Re-running is safe — every
   install checks state first and skips what's already present.

### Checking your changes

There is no test harness in the repo. Before committing:

```bash
bash -n install.sh src/*.sh                      # syntax-check every script
shellcheck install.sh src/*.sh                   # static analysis (shellcheck is in base)
./install.sh --profile <profile> --validate-only # validate profile YAML structure
./install.sh --profile <profile> --dry-run       # preview the full run, no changes
```

To exercise a real run without risking your host, use a throwaway container:

```bash
docker run --rm -it ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y git sudo &&
  useradd -m -s /bin/bash -G sudo tester && passwd -d tester &&
  su - tester -c 'git clone <repo-url> ~/dotfiles && cd ~/dotfiles &&
    ./install.sh --profile base --force --non-interactive'
"
```

> `--force` is needed in a fresh container because `useradd -m` seeds `$HOME`
> with `/etc/skel` copies (`.bashrc` etc.) that would otherwise block symlinking.

## Requirements

- Ubuntu 22.04+
- bash 5.x
- python3 (YAML parsing — present by default on Ubuntu 22.04)
- git (to clone the repo — present after Stage 1)
- internet connection (for package downloads)

## Roadmap

The repo was recently slimmed down to its functional core. Planned next steps,
roughly in priority order:

**Safety net (do first)**
- **CI on every push/PR** — a small GitHub Actions workflow running `bash -n` and
  `shellcheck` on all scripts, plus `--validate-only` against each profile. Cheap,
  no Docker required.
- **A minimal smoke test** — one container run per profile (`--dry-run`, then a
  real `--force --non-interactive` run) asserting exit 0 and idempotency on a
  second run. Enough to catch regressions without rebuilding the old 19-scenario
  suite.

**Provisioning features**
- **Connectivity pre-flight** — bail early with a clear message when there's no
  network instead of failing mid-install.
- **Log to a file** — tee the run to `~/.local/logs/dotfiles/` for post-mortems.
- **`--status` / diff** — report which dotfiles are linked, drifted, or missing
  without applying anything.
- **Nerd Font install** and **GNOME/dconf settings** for the desktop profile.

**Content & correctness**
- **Exercise every package type** — `deb`, `custom`, `snap`, and `flatpak` are
  supported by the dispatcher but only `apt`/`snap` appear in profiles today. Add
  real entries (or document the intent) so the code paths are actually used.
- **Pin third-party repos** — `nodejs`/`npm` and `docker.io` currently come from
  Ubuntu's repos; add proper upstream apt sources for current versions.

## Author

Jerry van Heerikhuize — [@jvanheerikhuize](https://github.com/jvanheerikhuize)
