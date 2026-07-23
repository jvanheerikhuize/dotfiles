# Contributing Guide

This repo is plain bash driven by declarative YAML profiles — no build step, no
framework, nothing to compile. Contributions are welcome; keep them small and
focused.

## Getting Started

### Prerequisites

- Ubuntu 22.04+
- bash 5.x
- git
- python3 (YAML parsing — present by default on Ubuntu 22.04)
- shellcheck (in the `base` profile; used for linting)
- Docker (optional — for testing a real run in a throwaway container)

### Setup

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh --profile base --dry-run   # preview without changing anything
```

## Workflow

1. Branch off `main` — never commit to `main` directly.
2. Make your change (see [Adding a package](#adding-a-package) below for the
   common case).
3. Check it (see [Verifying changes](#verifying-changes)).
4. Open a pull request with a conventional-commit title.

### Adding a package

Add it under the right type (`apt`/`snap`/`flatpak`/`deb`/`custom`) in the
appropriate `profiles/*.yaml`. Put it in the most general profile that should
receive it — `base` reaches every machine; `desktop`/`server`/`dev` narrow it
down. No shell code is needed for a new package — the dispatcher reads the YAML.

### Adding a new behaviour

Behaviour lives in `src/*.sh`, sourced by `install.sh`. Follow the existing
libraries as a template — they show the house style for guards, logging, and
idempotency.

## Verifying changes

There is no test harness in the repo. Before opening a PR:

```bash
bash -n install.sh src/*.sh                      # syntax-check every script
shellcheck install.sh src/*.sh                   # static analysis
./install.sh --profile <profile> --validate-only # validate profile YAML structure
./install.sh --profile <profile> --dry-run       # preview the full run, no changes
```

To exercise a real run without touching your host, use a throwaway container:

```bash
docker run --rm -it ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y git sudo &&
  useradd -m -s /bin/bash -G sudo tester && passwd -d tester &&
  su - tester -c 'git clone <repo-url> ~/dotfiles && cd ~/dotfiles &&
    ./install.sh --profile base --force --non-interactive'
"
```

`--force` is needed in a fresh container because `useradd -m` seeds `$HOME` with
`/etc/skel` copies (`.bashrc` etc.) that would otherwise block symlinking.

## Code standards

1. **`set -euo pipefail`** at the top of every script — no exceptions.
2. **Named functions** — no logic at the top level of a library; keep the body a
   thin dispatcher.
3. **`local` variables** — don't mutate globals inside functions.
4. **Idempotency** — check state before acting; a second run must be a safe no-op.
5. **`log_info` / `log_warn` / `log_error`** from `src/utils.sh` — never bare `echo`
   for status output.
6. **Package lists live in YAML** — never hardcode packages in shell scripts.
7. **No `[[ cond ]] && cmd` as a statement** under `set -e` — a false test returns
   exit 1 and trips errexit. Use an `if` block instead.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(packages): add flatpak dispatch to the installer
fix(dotfiles): skip .gitkeep when linking
docs: trim README to match the lean repo
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`.

## Branch naming

```
feat/nerd-fonts       # new feature
fix/dotfile-symlink   # bug fix
docs/update-readme     # docs only
```
