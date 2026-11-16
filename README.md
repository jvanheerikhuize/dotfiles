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
├── dotfiles/             # .bashrc, .bash_aliases, .bash_profile, .gitconfig (symlinked into $HOME)
├── src/                  # packages.sh (apt, snap, flatpak, deb, custom), dotfiles.sh, validate.sh, setup-git-identity.sh, setup-ssh.sh, utils.sh
└── docs/
    └── TRIAGE.md         # What the reference machine has that the profiles do not; tick to adopt
```

## Checks before a PR

```bash
shellcheck install.sh src/*.sh
./install.sh --profile dev --validate-only
```

## Rules

1. Declarative only: packages go in a profile, not in a script.
2. No secrets in the repo. Git identity and SSH keys are set per machine by `src/setup-git-identity.sh` and `src/setup-ssh.sh`.
3. GUI apps are Flatpak-first (decision 2026-11-16). Vendor apt repos only where Flatpak is the wrong fit (VS Code, VirtualBox).
4. Anything that must exist before first login belongs to stage 1, not here.
