# Package & Config Candidates

A triage list of apps, toolchains, and configs found installed on a working
machine but **not yet declared in `profiles/`**. Tick an item when it's added to
the appropriate profile (or strike it if you decide against it). This directly
serves the "content & correctness" roadmap goal — several entries are the first
real users of the `deb`, `custom`, and `flatpak` code paths, which the dispatcher
supports but no profile currently exercises.

> Snapshot taken 2026-07-23. Re-run the inventory (`apt-mark showmanual`,
> `snap list`, `flatpak list`) periodically; this list will drift.

## `base` — modern CLI tools (apt)

Everyday tools present on the machine but missing from `base`:

- [ ] `bat` — better `cat` with syntax highlighting
- [ ] `fd-find` — better `find` (binary is `fdfind` on Ubuntu)
- [ ] `fzf` — fuzzy finder
- [ ] `zoxide` — smarter `cd`
- [ ] `duf` — better `df`
- [ ] `tldr` — concise, example-driven man pages
- [ ] `pipx` — install Python CLI apps in isolated venvs
- [ ] `ffmpeg` — media transcoding

## `dev` — toolchains & developer apps

These are the main candidates for the **`custom`** and **`deb`** paths:

- [ ] `rustup` + cargo — via **`custom`** (rustup.rs) or `apt rustup`
- [ ] `uv` — via **`custom`** (Astral installer); Python packaging
- [ ] `ollama` — via **`custom`** (`curl … | sh`)
- [ ] `aider` — via `pipx` (a `custom` step; depends on `pipx` in `base`)
- [ ] `terraform` — via **`deb`** or the HashiCorp apt repo
- [ ] `coder` — via **`deb`** / `custom`
- [ ] `go` — `apt golang-go` or **`custom`**
- [ ] `gitkraken` — `snap` (classic)
- [ ] **Decide on VS Code source** — the machine has it from the **Microsoft apt
      repo**, but `desktop.yaml` installs `code` as a **snap**. Pick one and make
      the profile match reality.

## `desktop` — GUI apps

The **`flatpak`** path finally gets a real user here:

- [ ] `com.orcaslicer.OrcaSlicer` — **`flatpak`** (the only flatpak installed;
      exercises that dispatcher path)
- [ ] `alacritty` — `snap` (classic); config also worth capturing (see below)
- [ ] `inkscape` — `snap`
- [ ] `krita` — `snap`
- [ ] `openscad-nightly` — `snap`
- [ ] `libreoffice` — `snap`
- [ ] `transmission` — `snap`
- [ ] `cheese` — `snap`
- [ ] `mailspring` — `snap`
- [ ] `google-chrome-stable` — **`deb`** or the Google apt repo (third-party)
- [ ] `signal-desktop` — **`deb`** or the Signal apt repo (third-party)
- [ ] `realvnc-vnc-viewer` — `apt` / `deb`
- [ ] `rpi-imager` — `apt`
- [ ] `gnome-shell-extension-manager` — `apt`

## Dotfiles / configs to capture in `dotfiles/`

- [ ] `~/.config/alacritty` — alacritty is installed but its config isn't tracked
- [ ] `.tmux.conf` — `tmux` ships in `base` but there's no tracked config
- [ ] Resolve orphaned shell configs — `.zshrc` and `~/.config/fish` exist on the
      machine, but neither `zsh` nor `fish` is installed. Either add the shell to a
      profile or drop the config.

## Third-party apt repos already configured

Relevant to the roadmap's "pin third-party repos" item — the machine already
carries these, but no profile sets them up:

- [ ] GitHub CLI (`cli.github.com`)
- [ ] Microsoft / VS Code (`packages.microsoft.com/repos/code`)
- [ ] Waydroid (`repo.waydro.id`)

## Deliberately excluded (machine / hardware-specific)

Not generalizable across machines; listed so a future inventory doesn't re-flag
them: `lm-sensors`, `powertop`, `smartmontools`, `nvme-cli`, `bluez*`,
`pavucontrol`, `iio-sensor-proxy`, `mesa-utils`, `vainfo`, gstreamer plugins,
`virtualbox`.
