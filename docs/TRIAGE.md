# Triage: what the reference machine has that the profiles do not

Scanned 2026-11-16 on the Latitude 5400 (Ubuntu 26.04.1 LTS, GNOME, bash). Only things the
profiles do not already declare are listed. Tick what the repo should reproduce and write the
target profile in the last column (`base`, `desktop`, `dev`, `embedded`, `skip`). Suggestions
are pre-filled from the stateless-laptop plan; they are a starting point, not a decision.

Decisions already taken (2026-11-16): bash + starship; Flatpak-first for GUI apps; VS Code and
VirtualBox stay apt.

## 1. CLI tools (apt unless noted)

| Adopt | Item | Installed today as | Suggested |
|:-----:|------|--------------------|-----------|
| [ ] | `bat` | apt | base |
| [ ] | `fd-find` | apt | base |
| [ ] | `fzf` | apt | base |
| [ ] | `zoxide` | apt | base |
| [ ] | `ripgrep` | cargo | base (apt) |
| [ ] | `eza` | cargo | base (apt) |
| [ ] | `starship` | cargo | base (release binary, pinned) |
| [ ] | `duf`, `ncdu` | apt | base |
| [ ] | `xclip` | apt | desktop |
| [ ] | `gh` | apt | stage 1 (not here) |
| [ ] | `nmap`, `tshark` | apt | dev |
| [ ] | `nvme-cli`, `smartmontools`, `lm-sensors`, `powertop` | apt | base |
| [ ] | `mesa-utils`, `vainfo` | apt | desktop |
| [ ] | `rclone` | apt | base (stage 4 depends on it) |
| [ ] | `ffmpeg`, `handbrake-cli` | apt | desktop |
| [ ] | `php-cli`, `php-gd` | apt | skip unless still used |
| [ ] | `pipx` | apt | skip (use `uv tool`) |
| [ ] | `uv` | installer in `~/.local/bin` | dev (custom) |
| [ ] | `rustup` | apt | dev |
| [ ] | `go` | tarball in `~/.local/bin` | dev (custom, pinned version) |
| [ ] | `nodejs` 22 | apt (Ubuntu archive) | dev; remove NodeSource 20 source and `~/.local/bin/node.v20`, `n` |
| [ ] | `pnpm`, `yarn`, `corepack` | `~/.local/bin` | dev (via corepack) |
| [ ] | `shellcheck` | apt | already in base |
| [ ] | `gitleaks`, `semgrep`, `trivy` | loose binaries in `~/.local/bin` | stage 3 (agentic-workspace) |
| [ ] | `mkdocs`, `ghp-import`, `httpx`, `uvicorn`, `watchmedo` | pip/uv | skip; per-project venvs |
| [ ] | `git-filter-repo` | `~/.local/bin` | dev |

## 2. GUI apps

| Adopt | Item | Installed today as | Suggested |
|:-----:|------|--------------------|-----------|
| [ ] | Google Chrome | deb, vendor repo | desktop, Flatpak `com.google.Chrome` |
| [ ] | Firefox | snap (Ubuntu default) | leave as is |
| [ ] | Signal | deb, vendor repo | desktop, Flatpak `org.signal.Signal` |
| [ ] | VS Code | deb (`code`) | dev, Microsoft apt repo (stays apt) |
| [ ] | VirtualBox 7.2 | apt | dev, apt (kernel modules) |
| [ ] | VLC | deb and snap | desktop, Flatpak `org.videolan.VLC` |
| [ ] | Inkscape | snap | desktop, Flatpak `org.inkscape.Inkscape` |
| [ ] | Krita | snap | desktop, Flatpak `org.kde.krita` |
| [ ] | LibreOffice | snap | desktop, Flatpak `org.libreoffice.LibreOffice` |
| [ ] | Spotify | snap | desktop, Flatpak `com.spotify.Client` |
| [ ] | GitKraken | snap | dev, Flatpak `com.axosoft.GitKraken` |
| [ ] | Transmission | snap | desktop, Flatpak `com.transmissionbt.Transmission` |
| [ ] | Mailspring | snap | desktop, Flatpak `com.getmailspring.Mailspring` |
| [ ] | Cheese | snap | skip (GNOME Camera is in 26.04) |
| [ ] | Alacritty | classic snap | desktop, apt |
| [ ] | FileZilla | apt | desktop, Flatpak `org.filezillaproject.Filezilla` |
| [ ] | OrcaSlicer | Flatpak | desktop |
| [ ] | HandBrake | Flatpak | desktop |
| [ ] | ElegooSlicer | AppImage in `~/.local/bin` | skip, or custom with pinned URL |
| [ ] | Raspberry Pi Imager | apt | desktop, Flatpak `org.raspberrypi.rpi-imager` |
| [ ] | gparted, pavucontrol, gnome-shell-extension-manager | apt | desktop |
| [ ] | RealVNC Viewer | apt | skip |
| [ ] | gftp, curlftpfs, innoextract | apt | skip |
| [ ] | coder, goose | apt | skip |

## 3. Shell, GNOME and dotfiles

| Adopt | Item | Where today | Suggested |
|:-----:|------|-------------|-----------|
| [ ] | `~/.config/alacritty` | unmanaged | dotfiles |
| [ ] | `~/.config/starship.toml` | missing | dotfiles |
| [ ] | `~/.config/git/ignore` | managed by agentic-workspace | leave there |
| [ ] | GNOME dconf (dock, tiling-assistant, dark mode, keybindings) | unmanaged | `dotfiles/dconf.ini`, loaded by install.sh |
| [ ] | GNOME extensions: tiling-assistant, appindicators, dock, ding | Ubuntu defaults | leave |
| [ ] | Fonts: `fonts-firacode` + a Nerd Font for starship | partly | desktop |
| [ ] | `~/.zshrc`, `~/.config/fish` | orphaned (zsh, fish not installed) | delete |
| [ ] | `~/.config/{BraveSoftware,microsoft-edge,opera,vivaldi,chromium}` | leftovers, apps not installed | delete |
| [ ] | `~/.config/{unity3d,godot,Ultralytics,coderv2}` | leftovers | delete |

## 4. Hardware and embedded (candidate profile `embedded`)

| Adopt | Item | Where today | Suggested |
|:-----:|------|-------------|-----------|
| [ ] | `adb`, `fastboot` | apt | embedded |
| [ ] | `libusb-1.0-0-dev`, `libsdl2-dev`, `pkg-config` | apt | embedded |
| [ ] | `arm-none-eabi-*` toolchain 14.2.1 | `~/.local/bin` | embedded (custom, pinned tarball) |
| [ ] | PocketBook SDK | `~/opt/pocketbook-sdk` | embedded (custom) or skip |
| [ ] | `esptool`, `python3-serial`, `minicom`, user in `dialout` | not installed (FEAT-0006 draft) | embedded |

## 5. System-level leftovers to remove on the current machine

| Done | Item |
|:----:|------|
| [ ] | NodeSource `node_20.x` apt source |
| [ ] | `linux-generic-hwe-24.04` metapackage (24.04 leftover) |
| [ ] | Chinese input methods: `ibus-table-cangjie*`, `libchewing3*`, `libpinyin*`, `m17n-db`, `libopencc*` |
| [ ] | `fluhus/gnome-googledrive` PPA (replaced by rclone) |
| [ ] | Disabled apt lists: `vscode.list.disabled`, `github-cli.list.disabled`, `waydroid.list.disabled` |
| [ ] | Old snap revisions and the `vlc` snap once the Flatpak is in |

## 6. Not for this repo

| Item | Belongs to |
|------|------------|
| `claude`, `gemini-cli`, `agy`, `kimi`, `twin`, `ask`, `agent`, `ollama` and models | agentic-workspace (stage 3) |
| `~/.ssh/id_ed25519`, `~/.config/rclone/rclone.conf` | password manager (stage 0) |
| `~/Repos` clone list, Documents and Pictures sync | stage 4 |
