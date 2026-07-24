# dotfiles — Improvement Plan

Assessment date: 2026-07-24
Scanned machine: `jerry@` — Ubuntu 24.04.4 LTS, GNOME, bash

---

## 1. What this repo is for

Stage 2 of a two-stage Ubuntu provisioning framework. Stage 1 (`Autoinstall.yaml`,
elsewhere) lays down a clean OS unattended; this repo turns that clean OS into a
working machine by installing packages and applying dotfiles, driven by declarative
YAML profiles with an `extends:` inheritance chain (`base ← desktop ← dev`, `base ← server`).

The design is sound and the implementation is genuinely careful — recursive profile
merge with circular-`extends` detection, order-preserving dedup, `--dry-run`,
`--validate-only`, an EXIT-trap run summary, and idempotent symlinking with `.bak`
backups. Roughly 1,550 lines of disciplined bash.

**The problem is not the engine. It is that the engine has drifted away from the
machine it is supposed to reproduce.** Everything below follows from that.

---

## 2. The five findings that matter

### F1 — The repo targets 22.04; the machine runs 24.04.4 (blocking)

Every reference (README, profiles, prior notes) assumes Ubuntu 22.04. The actual
machine is 24.04.4 LTS on kernel 7.0.0-28. Concrete breakage this causes:

| Profile entry | Problem on 24.04 |
|---|---|
| `docker.io`, `docker-compose` (dev) | superseded by the Docker `docker-ce` repo + `docker-compose-plugin`; the Ubuntu packages are stale and the v1 `docker-compose` binary is EOL |
| `nodejs`, `npm` (dev) | the machine actually uses NodeSource (`nodesource.sources`), not Ubuntu's; running this profile would fight the installed setup |
| `code` as a **snap** (desktop) | the machine has `code` from the **Microsoft apt repo** (`vscode.list`). Applying the desktop profile installs a *second*, conflicting VS Code |
| `python3-pip` + `pip install --user` | 24.04 enforces PEP 668; unqualified `pip install --user` now fails without `--break-system-packages`. The machine works around this with `pipx` — which the repo has no concept of |
| `fonts-firacode` (desktop) | fine, but the machine actually uses Cascadia Code + JetBrainsMono Nerd Font installed by hand into `~/.local/share/fonts` |

**Action:** retarget to 24.04, and add an OS-version pre-flight guard that refuses
(or loudly warns) on a mismatch rather than half-applying.

### F2 — The dotfiles have never actually been deployed to this machine

`~/.bashrc` and `~/.gitconfig` are **regular files, not symlinks**. `~/.bash_aliases`
and `~/.bash_profile` don't exist in `$HOME` at all. So `install.sh` has either never
run here, or ran without `--force` and silently skipped everything (which is exactly
what the collision logic is designed to do).

That would be a minor gap, except the live `~/.bashrc` has real configuration the repo
knows nothing about:

```bash
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export OLLAMA_HOST="http://192.168.178.25:11434"
export OLLAMA_API_BASE="http://192.168.178.25:11434"
alias fd='fdfind'
alias bat='batcat'
alias ls='eza --group-directories-first'
alias ll='eza -l --git --group-directories-first'
alias la='eza -la --git --group-directories-first'
. /usr/share/doc/fzf/examples/key-bindings.bash
. /usr/share/bash-completion/completions/fzf
eval "$(zoxide init bash)"
eval "$(starship init bash)"
```

Meanwhile `dotfiles/.bashrc` in the repo ships a **hand-rolled coloured `PS1`**. Running
`./install.sh --force` today would back up the real `.bashrc` to `.bak` and replace the
starship prompt, the eza/bat/fd aliases, the fzf keybindings, and the Ollama endpoint
with a prompt string. That is a silently destructive outcome for the one command this
repo exists to run.

**Action:** this is the highest-value fix. Reconcile the repo's `.bashrc`/`.bash_aliases`
with what is actually on the machine (see the triage list), and only then deploy. Treat
"the repo reproduces this machine" as the acceptance test.

### F3 — Coverage is roughly a third of the machine

| Category | On machine | Declared in profiles |
|---|---|---|
| apt (manually installed) | 89 | ~35 |
| snap (user-facing apps) | 12 | 2 |
| flatpak | 1 (OrcaSlicer) | 0 |
| third-party apt repos | 6 | 0 — **no mechanism exists** |
| cargo binaries | 2 (eza, starship) | 0 — no mechanism |
| pipx | 2 (aider-chat, yamllint) | 0 — no mechanism |
| pip --user | ~38 (mkdocs/material stack) | 0 — no mechanism |
| VS Code extensions | 11 | 0 — no mechanism |
| GNOME/dconf settings | several | 0 |
| installer-script binaries (`ollama`, `gemini`, `uv`, `claude`, …) | ~9 | 0 — `custom:` is unused |

The `custom:` package type is the intended escape hatch for some of this, but it's
unused and pushes the burden onto free-form shell. Several of these deserve first-class
types.

**Action:** add package types in this order of payoff — `apt_repo` (unblocks Chrome,
VS Code, NodeSource, Signal, GitHub CLI, Waydroid, Docker), `cargo`, `pipx`, then
`vscode_ext` and `font`.

### F4 — There is no test suite and no CI

Prior notes reference a Docker smoke-test suite; there is none in the tree now, and no
`.github/workflows/`. For a tool whose entire job is to run privileged, system-mutating
commands on a fresh machine, this is the biggest correctness risk after F2. Note also
that `install.sh` sources six files and the profile-merge logic is the subtlest code in
the repo — precisely the kind of thing that regresses invisibly.

**Action:** restore container smoke tests (one per profile, `--dry-run` first then a real
run in a 24.04 image), plus `shellcheck` and `yamllint` in CI. Both linters are already
installed on the machine, so this is cheap.

Two gotchas worth encoding as tests, since they are easy to reintroduce:
- Never use `[[ cond ]] && cmd` as a bare statement under `set -e` — a false condition
  returns 1 and trips errexit. Use `if`.
- In dotfiles, use `return 0`, never bare `return`, in non-interactive guards — bare
  `return` inherits exit code 1 and breaks `bash --login -c exit`.
- Smoke tests that link dotfiles need `--force`, because `useradd -m` seeds `/etc/skel`
  copies into `$HOME` before provisioning runs.

### F5 — No place for machine-local values

`OLLAMA_HOST=http://192.168.178.25:11434` is a LAN IP specific to this network. There is
currently nowhere for it to live: putting it in the repo makes it wrong on every other
machine, leaving it out means the repo doesn't reproduce this one.

**Action:** add a sourced-if-present `~/.bashrc.local` (gitignored), and optionally a
`profiles/local.yaml` that is gitignored and merged last. Cheap, and it unblocks
honest reproduction.

---

## 3. Plan

Phased so each phase is independently shippable and leaves the repo working.

### Phase 0 — Stop the footgun (do first, small)
1. Reconcile `dotfiles/.bashrc` and `dotfiles/.bash_aliases` with the live machine
   (starship, zoxide, fzf, eza/bat/fd aliases; drop or gate the hand-rolled `PS1`).
2. Add `~/.bashrc.local` sourcing for machine-local values; move `OLLAMA_*` there.
3. Make `--force` show a diff and require confirmation when it would overwrite a
   non-symlink, unless `--non-interactive`.
4. Add an OS-version pre-flight check.

*Exit criteria:* `./install.sh --profile dev --force` on this machine is a no-op-equivalent —
it reproduces the current shell rather than replacing it.

### Phase 1 — Retarget to 24.04
5. Update README and all profile comments to 24.04.
6. Fix `dev.yaml`: Docker via the official repo (`docker-ce`, `docker-compose-plugin`),
   Node via NodeSource, drop `docker.io`/`docker-compose`.
7. Fix `desktop.yaml`: VS Code via the Microsoft apt repo, not snap. Resolve the
   `htop` apt-vs-snap duplication.
8. Pin or templatize the hardcoded `gh` .deb URL (currently v2.67.0) — or drop it, since
   `gh` now comes from the GitHub CLI apt repo that's already on the machine.

### Phase 2 — New package types
9. `apt_repo:` — key URL + keyring path + sources line, applied before `apt:`. Unblocks six repos.
10. `cargo:` and `pipx:`.
11. `vscode_ext:` and `font:` (Nerd Font download into `~/.local/share/fonts` + `fc-cache`).

### Phase 3 — Safety net
12. Container smoke tests per profile on a 24.04 base image.
13. GitHub Actions: shellcheck + yamllint + smoke tests on PR.

### Phase 4 — Ergonomics
14. `--status` / drift detection: report what's declared-but-missing and
    installed-but-undeclared. This is the feature that would have surfaced F2 and F3
    on its own, and it makes the triage list below regenerable instead of a one-off.
15. Log to file (`~/.local/logs/dotfiles/`).
16. Pre-flight connectivity check.
17. GNOME/dconf settings for the desktop profile.

### Deliberately not planned
- **Reinstating the `.ai/` governance tree** (DIRECTIVES / SESSION_LOG / TRACEABILITY /
  ADRs / spec registry). It was removed in the `chore: baseline lean repo state` reset.
  For a single-author bash repo of this size, the ceremony cost is real and the tests in
  Phase 3 buy more safety than the process did. Flagging it as an explicit call, not an
  oversight — if you want it back, that's a decision to make deliberately rather than by
  drift. Note that the stale spec IDs (FEAT-00xx) still referenced in profile comments
  should be cleaned up either way.

---

## 4. Suggested order

Phase 0 is worth doing on its own, today — it's a handful of small edits and it removes
a destructive failure mode. Phase 1 and Phase 2's `apt_repo` are the substance. Phase 3
should land before Phase 2 grows much, so new package types arrive with test coverage
rather than after it.

See [`MACHINE-INVENTORY.md`](MACHINE-INVENTORY.md) for the item-by-item triage list.
