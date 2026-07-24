# Machine Inventory — Triage List

Scanned 2026-07-24 from `jerry@` (Ubuntu 24.04.4 LTS, GNOME, bash).
Everything found on the machine that the repo does **not** currently declare, grouped so
you can triage it in passes.

**How to use this:** tick the box for anything you want the repo to reproduce, and write
the target profile in the last column (`base` / `desktop` / `dev` / `server` / `skip`).
Suggestions are pre-filled — they're a starting point, not a decision.

Legend: ✅ already declared · ➕ candidate to add · ⚠️ conflict or problem · 🚫 recommend skip

> **Supersedes `docs/PACKAGE_CANDIDATES.md`** (added 2026-07-23 in #20). This scan is a
> superset of that list and corrects a few entries in it, so this PR removes it rather
> than leaving two triage lists to drift apart. Everything from it is carried over below;
> where the two disagree, the disagreement is called out. If you'd rather keep both, the
> deletion is a one-line revert.

---

## 1. Conflicts to resolve first

These aren't additions — they're places where the repo and the machine disagree. Worth
settling before anything else, because they change what "add" means below.

| ⚠️ | Item | Repo says | Machine has | Suggested resolution |
|---|---|---|---|---|
| ☐ | **VS Code** | `snap: code` (desktop) | apt from Microsoft repo (`vscode.list`) | Switch repo to `apt_repo` + `apt: code`. Applying desktop today installs a **second, conflicting** VS Code |
| ☐ | **htop** | `apt: htop` (base) | snap `htop` | Pick one — apt is the saner default for a CLI tool |
| ☐ | **Node.js** | `apt: nodejs, npm` (dev) | NodeSource repo (`nodesource.sources`), node+npm in `/usr/bin` | Switch to `apt_repo` NodeSource; Ubuntu's `nodejs` would downgrade/fight it |
| ☐ | **Docker** | `apt: docker.io, docker-compose` (dev) | **not installed at all** | Move to official `docker-ce` + `docker-compose-plugin`; v1 `docker-compose` is EOL |
| ☐ | **gh** | `deb:` pinned URL v2.67.0 (dev) | apt from GitHub CLI repo | Drop the pinned .deb, use `apt_repo` — pinned URLs rot |
| ☐ | **pip packages** | `apt: python3-pip` (base) | pipx + `pip --user` workarounds | 24.04 enforces PEP 668; unqualified `pip install --user` fails. Standardise on `pipx` |
| ☐ | **Fonts** | `apt: fonts-firacode` (desktop) | Cascadia Code + JetBrainsMono Nerd Font, hand-installed in `~/.local/share/fonts` | Add a `font:` type; decide whether FiraCode stays |
| ☐ | **`~/.bashrc`** | ships a hand-rolled coloured `PS1` | starship prompt + zoxide + fzf + eza aliases | See F2 in the plan — repo would overwrite the real config. **Highest priority** |
| ☐ | **`~/.bashrc` / `~/.gitconfig`** | expected to be symlinks | plain files; `.bash_aliases` and `.bash_profile` absent | Repo has never been deployed here. Reconcile, then deploy |

---

## 2. Third-party apt repos (no mechanism exists in the repo yet)

Nothing here can be declared until an `apt_repo:` type exists. All six are live on the machine.

| | Repo | Provides | Suggested profile |
|---|---|---|---|
| ☐ ➕ | `google-chrome.sources` | `google-chrome-stable` | desktop |
| ☐ ➕ | `vscode.list` (Microsoft) | `code` | dev |
| ☐ ➕ | `nodesource.sources` | `nodejs`, `npm` | dev |
| ☐ ➕ | `signal-desktop.sources` | `signal-desktop` | desktop |
| ☐ ➕ | `github-cli.list` | `gh` | dev |
| ☐ ➕ | `waydroid.list` | Waydroid (Android container) — **binary not currently installed** | skip? repo left behind |

---

## 3. apt packages installed but not declared

### 3a. CLI tools — likely `base`

| | Package | What it is | Suggested |
|---|---|---|---|
| ☐ ➕ | `bat` | `cat` with syntax highlighting (binary is `batcat`, aliased) | base |
| ☐ ➕ | `fd-find` | fast `find` (binary is `fdfind`, aliased) | base |
| ☐ ➕ | `fzf` | fuzzy finder — also wired into `.bashrc` keybindings | base |
| ☐ ➕ | `zoxide` | smarter `cd` — `eval`'d in `.bashrc` | base |
| ☐ ➕ | `duf` | friendlier `df` | base |
| ☐ ➕ | `ncdu` | disk usage TUI | base (currently only in `server`) |
| ☐ ➕ | `tldr` | condensed man pages | base |
| ☐ ➕ | `nmap` | network scanner | base (currently only in `server`) |
| ☐ ➕ | `gnupg` / `gpg` | already partly in base via `gnupg` | ✅ mostly covered |
| ☐ ➕ | `pipx` | isolated Python CLI installs — needed for PEP 668 on 24.04 | base |
| ☐ ➕ | `rustup` | Rust toolchain manager (installs cargo bins below) | dev |

### 3b. Hardware / diagnostics — `base` or `desktop`

| | Package | What it is | Suggested |
|---|---|---|---|
| ☐ ➕ | `lm-sensors` | temperature/fan sensors | base |
| ☐ ➕ | `smartmontools` | SMART disk health | base |
| ☐ ➕ | `nvme-cli` | NVMe management | base |
| ☐ ➕ | `powertop` | power consumption analysis | desktop (laptop-oriented) |
| ☐ ➕ | `mesa-utils` | `glxinfo` etc. | desktop |
| ☐ ➕ | `vainfo` | VA-API hardware video accel check | desktop |
| ☐ ➕ | `iio-sensor-proxy` | accelerometer/ambient light (auto-rotate) | desktop |

### 3c. Desktop apps and media

| | Package | What it is | Suggested |
|---|---|---|---|
| ☐ ➕ | `google-chrome-stable` | browser (needs repo above) | desktop |
| ☐ ➕ | `signal-desktop` | messaging (needs repo above) | desktop |
| ☐ ➕ | `realvnc-vnc-viewer` | VNC client | desktop |
| ☐ ➕ | `rpi-imager` | Raspberry Pi SD flasher | desktop |
| ☐ ➕ | `virtualbox-7.2` | VM hypervisor — version-pinned package name, will need care | desktop |
| ☐ ➕ | `gnome-shell-extension-manager` | GNOME extension GUI | desktop |
| ☐ ➕ | `pavucontrol` | PulseAudio volume control | desktop |
| ☐ ➕ | `ffmpeg` | media conversion | desktop |
| ☐ ➕ | `ubuntu-restricted-addons` | proprietary codecs — **prompts an EULA**, needs non-interactive handling | desktop |
| ☐ ➕ | `gstreamer1.0-pipewire`, `gstreamer1.0-plugins-ugly`, `gstreamer1.0-vaapi` | codec/accel plugins | desktop |
| ☐ ➕ | `bluez`, `bluez-tools`, `pulseaudio-module-bluetooth` | Bluetooth stack + audio | desktop |
| ☐ ➕ | `flatpak` | needed before any `flatpak:` entry can install | base or desktop |
| ☐ ➕ | `gir1.2-ayatanaappindicator3-0.1` | tray-icon support for GNOME extensions | desktop |

### 3d. Dev

| | Package | What it is | Suggested |
|---|---|---|---|
| ☐ ➕ | `coder` | Coder (remote dev environments) — check how it got installed | dev |
| ☐ ➕ | `python3-gi` | Python GObject bindings | dev or desktop |
| ☐ ➕ | `python3-netifaces` | network interface bindings | dev |

### 3e. 🚫 Recommend skipping — OS seed, boot, locale, IME

Installed but not meaningful choices; Stage 1 / the Ubuntu installer owns these.

`bsdutils` `dash` `diffutils` `findutils` `grep` `gzip` `hostname` `init` `login`
`ncurses-base` `ncurses-bin` `ubuntu-minimal` `ubuntu-standard` `ubuntu-desktop-minimal`
`ubuntu-wallpapers` `grub-efi-amd64` `grub-efi-amd64-signed` `shim-signed` `efibootmgr`
`linux-generic-hwe-24.04` `snapd` `wbritish`
`language-pack-en{,-base}` `language-pack-gnome-en{,-base}`
`ibus-table-cangjie{-big,3,5}` `libchewing3{,-data}` `libpinyin15` `libpinyin-data`
`libopencc1.1` `libopencc-data` `libm17n-0` `m17n-db` `libmarisa0` `libotf1`

☐ Confirm the CJK input-method packages (`ibus-table-*`, `libchewing`, `libpinyin`,
`libopencc`) were intentional — if they were, they belong in `desktop`; if they came in
with a language-support prompt, they're noise.

---

## 4. Snaps installed but not declared

| | Snap | What it is | Suggested |
|---|---|---|---|
| ☐ ➕ | `alacritty` | GPU terminal emulator — has a config at `~/.config/alacritty/` | desktop |
| ☐ ➕ | `gitkraken` | git GUI | dev |
| ☐ ➕ | `inkscape` | vector graphics | desktop |
| ☐ ➕ | `krita` | digital painting | desktop |
| ☐ ➕ | `libreoffice` | office suite | desktop |
| ☐ ➕ | `mailspring` | email client | desktop |
| ☐ ➕ | `transmission` | BitTorrent client | desktop |
| ☐ ➕ | `openscad-nightly` | parametric CAD — on the **edge** channel; repo has no channel support | desktop |
| ☐ ➕ | `firefox` | browser — Ubuntu ships it by default as a snap | desktop or skip |
| ☐ ➕ | `cheese` | webcam app — Ubuntu default | skip |
| ☐ ✅ | `spotify` | already declared in desktop | — |
| ☐ ⚠️ | `htop` | conflicts with `apt: htop` in base — see §1 | resolve |
| ☐ 🚫 | `core18` `core20` `core22` `core24` `bare` `gnome-*` `gtk-common-themes` `kf5-core22` `kf6-core24` `mesa-2404` `ffmpeg-2204` `lxqt-support-core24` | auto-pulled runtime bases | skip — never declare |
| ☐ 🚫 | `snapd` `snap-store` `snapd-desktop-integration` `firmware-updater` `cups` `canonical-livepatch` | system/Ubuntu-managed | skip |

☐ **Decision needed:** the repo's `snap:` type takes a bare name with no channel or
`--classic` flag. `openscad-nightly` (edge) and `code`/`gitkraken` (classic confinement)
all need more than a name. Either extend the `snap:` schema or accept the limitation.

## 5. Flatpaks

| | App | Suggested |
|---|---|---|
| ☐ ➕ | `com.orcaslicer.OrcaSlicer` — 3D print slicer | desktop |

☐ Note: no profile declares any flatpak today, and `flatpak` itself isn't in a profile,
so the flatpak code path is entirely untested in practice. Adding this one exercises it.

---

## 6. Language-manager packages (no mechanism exists in the repo)

### 6a. cargo (via rustup)

| | Binary | Suggested |
|---|---|---|
| ☐ ➕ | `eza` — modern `ls`, aliased over `ls`/`ll`/`la` in `.bashrc` | base |
| ☐ ➕ | `starship` — the actual shell prompt | base |

Both are load-bearing for the shell config. Also present in `~/.cargo/bin`: the rustup-managed
toolchain (`rustc` `cargo` `clippy` `rustfmt` `rust-analyzer` `rls` `rust-gdb` `rust-lldb`
`cargo-miri`) — 🚫 skip, they come with `rustup` itself.

### 6b. pipx

| | Package | Suggested |
|---|---|---|
| ☐ ➕ | `aider-chat` 0.86.2 — AI pair programming CLI | dev |
| ☐ ➕ | `yamllint` 1.38.0 — YAML linter (also wanted by the CI plan) | dev |

### 6c. pip `--user` — the mkdocs stack

☐ **Triage as a group.** ~38 packages under `pip --user`, which on 24.04 is a PEP 668
workaround. The top-level intent looks like exactly four things:

| | Package | Note |
|---|---|---|
| ☐ ➕ | `mkdocs` 1.6.1 | docs site generator |
| ☐ ➕ | `mkdocs-material` 9.7.7 | + `mkdocs-material-extensions`, `mkdocs-redirects`, `ghp-import` |
| ☐ ➕ | `properdocs` 1.6.7 | |
| ☐ ➕ | `mcp` 1.27.1 | MCP Python SDK — pulls in `uvicorn`, `starlette`, `pydantic`, `httpx` |

The remaining ~30 (`anyio` `h11` `httpcore` `jsonschema` `markdown` `pyyaml-env-tag`
`rpds-py` `typing-extensions` …) are 🚫 transitive dependencies — declare the four
top-level ones via `pipx` and let resolution handle the rest.

### 6d. npm global

| | Package | Suggested |
|---|---|---|
| ☐ 🚫 | `npm` 10.8.2, `corepack` 0.34.6 | ship with Node; skip |

Nothing to declare here.

### 6e. Loose binaries in `~/.local/bin` — provenance unclear

Several were installed outside any package manager. Worth deciding how each should be
reproduced:

| | Binary | Likely source | Suggested |
|---|---|---|---|
| ☐ ➕ | `claude` | Claude Code installer | dev — `custom:` |
| ☐ ➕ | `uv` / `uvx` | Astral installer script | dev — `custom:` |
| ☐ ➕ | `gitleaks` | secret scanner, GitHub release | dev — `custom:` or `deb:` |
| ☐ ➕ | `trivy` | vulnerability scanner, GitHub release | dev |
| ☐ ➕ | `semgrep` | static analysis | dev — via pipx? |
| ☐ ➕ | `shellcheck` | ⚠️ base declares it as **apt**, but it's here as a loose binary — reconcile | resolve |
| ☐ ➕ | `ubuntu-cast` / `twin` | unidentified — **check what these are** | ? |
| ☐ 🚫 | `aider` `mkdocs` `yamllint` `httpx` `uvicorn` `mcp` `dotenv` `env` `ghp-import` `jsonschema` `markdown_py` `properdocs` `watchmedo` `mkdocs-get-deps` | pipx/pip shims for §6b–6c | skip — covered above |

### 6f. System-wide binaries in `/usr/local/bin` and `/opt`

Installed outside apt entirely — these are the classic `custom:` candidates.

| | Path | What it is | Suggested |
|---|---|---|---|
| ☐ ➕ | `/usr/local/bin/ollama` | local LLM runtime, `curl … \| sh` installer. Pairs with the `OLLAMA_HOST`/`OLLAMA_API_BASE` vars in `.bashrc` (§8) | dev — `custom:` |
| ☐ ➕ | `/usr/local/bin/gemini` | Gemini CLI | dev — `custom:` |
| ☐ 🚫 | `/opt/Signal`, `/opt/google` | installed by the `signal-desktop` / `google-chrome-stable` apt packages | skip — covered in §3c |

### 6g. Wishlist from `PACKAGE_CANDIDATES.md` — not actually installed

The superseded list proposed these; the scan found none of them on the machine. Keep them
as wishlist items or drop them, but they aren't part of reproducing *this* machine:

☐ `terraform` · ☐ `go` / `golang-go`

---

## 7. Dotfiles and configs on the machine, not in the repo

| | Path | What it is | Suggested |
|---|---|---|---|
| ☐ ⚠️ | `~/.bashrc` | the **real** one — starship, zoxide, fzf, eza/bat/fd aliases, `OLLAMA_*` | **reconcile — see §1** |
| ☐ ➕ | `~/.config/alacritty/alacritty.toml` | terminal config (there's a `.bak` beside it) | desktop |
| ☐ ➕ | `~/.config/Code/User/settings.json` | VS Code settings | dev |
| ☐ ➕ | `~/.config/Code/User/keybindings.json` | VS Code keybindings | dev |
| ☐ ➕ | `~/.config/git/ignore` | global gitignore — currently one line: `**/.claude/settings.local.json` | base |
| ☐ ➕ | `~/.config/gh/` | GitHub CLI config — ⚠️ **check for tokens before committing** | dev, secrets-stripped |
| ☐ ➕ | `~/.config/tiling-assistant/` | GNOME tiling extension settings | desktop |
| ☐ ➕ | `~/.config/mimeapps.list` | default-application associations | desktop |
| ☐ ➕ | `~/.config/autostart/ubuntu-cast-tray.desktop` | autostart entry (relates to the `ubuntu-cast` binary above) | desktop |
| ☐ 🚫 | `~/.config/fish/` | fish config exists but **`fish` is not installed** — orphaned | drop from the machine |
| ☐ 🚫 | `~/.zshrc` | zsh config exists (1 line) but **`zsh` is not installed** — orphaned | drop from the machine |
| ☐ 🚫 | `~/.gitconfig` | already declared; live version adds the `gh` credential helper | merge the helper into the repo's version |

### Not on the machine but declared by the repo
☐ `dotfiles/.bash_aliases` and `dotfiles/.bash_profile` exist in the repo but not in
`$HOME` — confirms the repo has never been deployed here.

### Missing from both
☐ `~/.tmux.conf` — `tmux` is declared in `base` but has no config
☐ `~/.vimrc` — `vim` is declared in `base`, README claims `dotfiles/.vimrc` is symlinked, but **no `.vimrc` exists** in the repo or `$HOME`. README is wrong.

---

## 8. Machine-local values (need an escape hatch — see F5)

| | Value | Note |
|---|---|---|
| ☐ | `OLLAMA_HOST=http://192.168.178.25:11434` | LAN IP — wrong on any other machine |
| ☐ | `OLLAMA_API_BASE=http://192.168.178.25:11434` | same |
| ☐ | `~/.ssh/id_ed25519` + `authorized_keys` | 🚫 **never commit.** `setup-ssh.sh` already generates a key; leave it that way |
| ☐ | git identity (`Jerry van Heerikhuize` / `jvanheerikhuize@gmail.com`) | already handled by `setup-git-identity.sh` ✅ |

---

## 9. VS Code extensions (no mechanism exists in the repo)

All 11 installed. Suggested: `dev`.

| | Extension |
|---|---|
| ☐ ➕ | `anthropic.claude-code` |
| ☐ ➕ | `ms-python.python` · `ms-python.debugpy` · `ms-python.vscode-pylance` · `ms-python.vscode-python-envs` |
| ☐ ➕ | `ms-azuretools.vscode-containers` |
| ☐ ➕ | `ms-vscode.makefile-tools` |
| ☐ ➕ | `davidanson.vscode-markdownlint` |
| ☐ ➕ | `mermaidchart.vscode-mermaid-chart` |
| ☐ ➕ | `mechatroner.rainbow-csv` |
| ☐ ➕ | `mtsmfm.vscode-stl-viewer` |

---

## 10. Fonts

| | Font | Note |
|---|---|---|
| ☐ ➕ | **Cascadia Code** (Bold, Italic, Light, Medium, ExtraLight, variable) | ⚠️ the directory has duplicate/garbled filenames — `1CascadiaCode-ExtraLight.ttf`, `11CascadiaCode-ExtraLight.ttf`, `2CascadiaCode-ExtraLight.ttf`. Worth cleaning up on the machine before declaring |
| ☐ ➕ | **JetBrainsMono** Nerd Font (directory) | needed for starship glyphs |
| ☐ | GNOME monospace font is set to `Ubuntu Sans Mono 13` | neither of the above is actually the terminal font — check what Alacritty uses |

---

## 11. GNOME / dconf settings

Only a handful differ from stock. Low priority, but cheap to capture once a `dconf:` mechanism exists.

| | Key | Value |
|---|---|---|
| ☐ ➕ | `org.gnome.desktop.wm.preferences button-layout` | `:minimize,maximize,close` (non-default — minimize/maximize added) |
| ☐ ➕ | `org.gnome.desktop.interface clock-format` | `24h` |
| ☐ ➕ | `org.gnome.desktop.interface monospace-font-name` | `Ubuntu Sans Mono 13` |
| ☐ ➕ | `org.gnome.desktop.peripherals.touchpad natural-scroll` | `true` |
| ☐ 🚫 | `color-scheme` `default` · `gtk-theme` `Yaru` · dock position `LEFT` | all stock defaults — nothing to declare |

☐ No GNOME shell extensions are installed or enabled (`enabled-extensions` is empty),
despite `gnome-shell-extension-manager` and `tiling-assistant` config being present.
Worth confirming whether tiling-assistant is meant to be active.

---

## Summary of counts

| Category | Found | Already declared | Candidates | Recommend skip |
|---|---|---|---|---|
| apt (manual) | 89 | ~12 of them | ~35 | ~40 |
| snap | 33 | 1 | 10 | 21 |
| flatpak | 1 | 0 | 1 | 0 |
| apt repos | 6 | 0 | 5 | 1 |
| cargo | 2 | 0 | 2 | 0 |
| pipx | 2 | 0 | 2 | 0 |
| pip --user (top-level) | 4 | 0 | 4 | ~34 transitive |
| `~/.local/bin` loose | 7 unclear | 0 | 7 | — |
| `/usr/local/bin` | 2 | 0 | 2 | 0 |
| dotfiles/configs | 10 | 2 | 9 | 2 |
| VS Code extensions | 11 | 0 | 11 | 0 |
| fonts | 2 families | 0 | 2 | 0 |
| dconf keys | 4 non-default | 0 | 4 | — |

**Roughly 90 items to triage**, of which the nine conflicts in §1 are the ones that
change behaviour rather than just coverage.
