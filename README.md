# dotfiles

Stage 2 of a three-stage laptop rebuild: turns a clean Ubuntu install into a working machine. Installs packages from declarative YAML profiles and symlinks dotfiles into `$HOME`. Idempotent; safe to re-run.

Stage 1 is [Autoinstall-YAML](https://github.com/jvanheerikhuize/Autoinstall-YAML) (the OS), stage 3 is [agentic-workspace](https://github.com/jvanheerikhuize/agentic-workspace) (agent tooling). The split and the rebuild runbook are in Autoinstall-YAML's `PLAN.md`.

## Usage

```bash
git clone https://github.com/jvanheerikhuize/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh --profile dev
```

Options: `--profile PROFILE`, `--skip-dotfiles`, `--dotfiles-only`, `--force`, `--dry-run`, `--validate-only`, `--quiet`, `--non-interactive`.

Profiles extend each other: `base` (CLI only) → `desktop` (GUI) → `dev` (toolchains). `server` extends `base`.

## Files

```text
├── install.sh            # Entry point
├── profiles/             # base.yaml, desktop.yaml, dev.yaml, server.yaml
├── dotfiles/             # .bashrc, .bash_aliases, .bash_profile, .gitconfig, .config/alacritty/ (symlinked into $HOME)
├── gnome/
│   └── dconf.ini         # Dock, tiling, theme; loaded with `dconf load /` for profiles that include desktop
├── src/                  # packages.sh (apt, snap, flatpak, deb, custom), dotfiles.sh, validate.sh, setup-git-identity.sh, setup-ssh.sh, utils.sh
└── docs/
    └── TRIAGE.md         # What the reference machine has and where each adopted item now lives
```

## Checks before a PR

```bash
shellcheck install.sh src/*.sh
./install.sh --profile dev --validate-only
```

## Verification record

Last run: 2026-11-17, `--profile dev --non-interactive` on a fresh Ubuntu 26.04.1 VM installed by
Autoinstall-YAML (stage 1), driven over SSH.

| Check | Result |
| :--- | :--- |
| 63 apt packages, postman snap, 10 Flatpaks, 4 custom steps | pass |
| Dotfiles linked, including a fresh `~/.bashrc` from `/etc/skel` | pass |
| GNOME settings (`dconf read` of color scheme and dock position) | pass |
| `uv`, `pnpm`, `go` on PATH in an interactive shell | pass |
| Second run installs nothing (idempotent), 13 s | pass |
| Git identity | skipped with a warning, as designed for `--non-interactive` |

Fixes found by this run: Flatpak remote and installs need `sudo`; untouched `/etc/skel` files are
replaced; uv no longer edits `.bashrc`; `docker-compose-v2`, `bind9-dnsutils` and `org.gnome.Snapshot`
replace names that never report as installed.

## Rules

1. Declarative only: packages go in a profile, not in a script.
2. No secrets in the repo. Git identity and SSH keys are set per machine by `src/setup-git-identity.sh` and `src/setup-ssh.sh`.
3. GUI apps are Flatpak-first (decision 2026-11-16). Vendor apt repos only where Flatpak is the wrong fit (VS Code, VirtualBox).
4. The shell is plain bash; starship was dropped on 2026-11-17.
5. Anything that must exist before first login belongs to stage 1, not here.
