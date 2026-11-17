# Triage: what the reference machine has that the profiles do not

Scanned 2026-11-16 on the Latitude 5400 (Ubuntu 26.04.1 LTS, GNOME, bash). Only things the
profiles do not already declare are listed. Tick what the repo should reproduce and write the
target profile in the last column (`base`, `desktop`, `dev`, `embedded`, `skip`). Suggestions
are pre-filled from the stateless-laptop plan; they are a starting point, not a decision. Each
item name links to the project's website.

Decisions already taken (2026-11-16): bash + starship; Flatpak-first for GUI apps; VS Code and
VirtualBox stay apt.

## 1. CLI tools (apt unless noted)

| Adopt | Item | What it is | Installed today as | Suggested |
|:-----:|------|------------|--------------------|-----------|
| [ ] | [`bat`](https://github.com/sharkdp/bat) | `cat` with syntax highlighting, line numbers and git markers | apt | base |
| [ ] | [`fd-find`](https://github.com/sharkdp/fd) | Fast, friendly alternative to `find` | apt | base |
| [ ] | [`fzf`](https://github.com/junegunn/fzf) | Interactive fuzzy finder for files, history and any list | apt | base |
| [ ] | [`zoxide`](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` that remembers frequently used directories | apt | base |
| [ ] | [`ripgrep`](https://github.com/BurntSushi/ripgrep) | Very fast recursive text search that respects `.gitignore` | cargo | base (apt) |
| [ ] | [`eza`](https://eza.rocks) | Modern `ls` with colours, icons, git status and tree view | cargo | base (apt) |
| [ ] | [`starship`](https://starship.rs) | Fast, configurable shell prompt | cargo | base (release binary, pinned) |
| [ ] | [`duf`](https://github.com/muesli/duf), [`ncdu`](https://dev.yorhel.nl/ncdu) | Readable disk-free overview; interactive disk-usage browser | apt | base |
| [ ] | [`xclip`](https://github.com/astrand/xclip) | Copy to and paste from the clipboard on the command line | apt | desktop |
| [ ] | [`gh`](https://cli.github.com) | GitHub CLI for PRs, issues, releases and auth | apt | stage 1 (not here) |
| [ ] | [`nmap`](https://nmap.org), [`tshark`](https://www.wireshark.org/docs/man-pages/tshark.html) | Network and port scanner; terminal version of Wireshark for packet capture | apt | dev |
| [ ] | [`nvme-cli`](https://github.com/linux-nvme/nvme-cli), [`smartmontools`](https://www.smartmontools.org), [`lm-sensors`](https://github.com/lm-sensors/lm-sensors), [`powertop`](https://github.com/fenrus75/powertop) | SSD health and firmware; disk SMART checks; temperature and fan readings; power-usage tuning | apt | base |
| [ ] | [`mesa-utils`](https://gitlab.freedesktop.org/mesa/demos), [`vainfo`](https://github.com/intel/libva-utils) | OpenGL diagnostics (`glxinfo`); check hardware video decoding | apt | desktop |
| [ ] | [`rclone`](https://rclone.org) | Sync and mount cloud storage such as Google Drive | apt | base (stage 4 depends on it) |
| [ ] | [`ffmpeg`](https://ffmpeg.org), [`handbrake-cli`](https://handbrake.fr) | Convert and edit audio and video; command-line video transcoder | apt | desktop |
| [ ] | [`php-cli`, `php-gd`](https://www.php.net) | PHP interpreter and its image library | apt | skip unless still used |
| [ ] | [`pipx`](https://pipx.pypa.io) | Install Python CLI tools in isolated environments | apt | skip (use `uv tool`) |
| [ ] | [`uv`](https://docs.astral.sh/uv/) | Fast Python package, venv and tool manager | installer in `~/.local/bin` | dev (custom) |
| [ ] | [`rustup`](https://rustup.rs) | Rust toolchain installer and version manager | apt | dev |
| [ ] | [`go`](https://go.dev) | Go compiler and toolchain | tarball in `~/.local/bin` | dev (custom, pinned version) |
| [ ] | [`nodejs`](https://nodejs.org) 22 | JavaScript runtime | apt (Ubuntu archive) | dev; remove NodeSource 20 source and `~/.local/bin/node.v20`, `n` |
| [ ] | [`pnpm`](https://pnpm.io), [`yarn`](https://yarnpkg.com), [`corepack`](https://github.com/nodejs/corepack) | JavaScript package managers; corepack pins them per project | `~/.local/bin` | dev (via corepack) |
| [ ] | [`shellcheck`](https://www.shellcheck.net) | Linter for shell scripts | apt | already in base |
| [ ] | [`gitleaks`](https://github.com/gitleaks/gitleaks), [`semgrep`](https://semgrep.dev), [`trivy`](https://trivy.dev) | Secret scanner for git; static code analysis; vulnerability scanner for dependencies and images | loose binaries in `~/.local/bin` | stage 3 (agentic-workspace) |
| [ ] | [`mkdocs`](https://www.mkdocs.org), [`ghp-import`](https://github.com/c-w/ghp-import), [`httpx`](https://www.python-httpx.org), [`uvicorn`](https://uvicorn.dev), [`watchmedo`](https://github.com/gorakhargosh/watchdog) | Static docs sites; publish to GitHub Pages; HTTP client; Python web server; rerun commands on file changes | pip/uv | skip; per-project venvs |
| [ ] | [`git-filter-repo`](https://github.com/newren/git-filter-repo) | Rewrite git history, for example to purge a leaked file | `~/.local/bin` | dev |

## 2. GUI apps

| Adopt | Item | What it is | Installed today as | Suggested |
|:-----:|------|------------|--------------------|-----------|
| [ ] | [Google Chrome](https://www.google.com/chrome/) | Web browser | deb, vendor repo | desktop, Flatpak `com.google.Chrome` |
| [ ] | [Firefox](https://www.mozilla.org/firefox/) | Web browser, Ubuntu's default | snap (Ubuntu default) | leave as is |
| [ ] | [Signal](https://signal.org) | End-to-end encrypted messenger | deb, vendor repo | desktop, Flatpak `org.signal.Signal` |
| [ ] | [VS Code](https://code.visualstudio.com) | Code editor | deb (`code`) | dev, Microsoft apt repo (stays apt) |
| [ ] | [VirtualBox](https://www.virtualbox.org) 7.2 | Virtual machines, used to test the autoinstall | apt | dev, apt (kernel modules) |
| [ ] | [VLC](https://www.videolan.org/vlc/) | Media player for almost any format | deb and snap | desktop, Flatpak `org.videolan.VLC` |
| [ ] | [Inkscape](https://inkscape.org) | Vector graphics editor (SVG) | snap | desktop, Flatpak `org.inkscape.Inkscape` |
| [ ] | [Krita](https://krita.org) | Digital painting and image editing | snap | desktop, Flatpak `org.kde.krita` |
| [ ] | [LibreOffice](https://www.libreoffice.org) | Office suite: documents, spreadsheets, slides | snap | desktop, Flatpak `org.libreoffice.LibreOffice` |
| [ ] | [Spotify](https://www.spotify.com) | Music streaming client | snap | desktop, Flatpak `com.spotify.Client` |
| [ ] | [GitKraken](https://www.gitkraken.com) | Graphical git client | snap | dev, Flatpak `com.axosoft.GitKraken` |
| [ ] | [Transmission](https://transmissionbt.com) | BitTorrent client | snap | desktop, Flatpak `com.transmissionbt.Transmission` |
| [ ] | [Mailspring](https://getmailspring.com) | Desktop email client | snap | desktop, Flatpak `com.getmailspring.Mailspring` |
| [ ] | [Cheese](https://gitlab.gnome.org/GNOME/cheese) | Webcam app, replaced by [GNOME Camera](https://apps.gnome.org/Snapshot/) | snap | skip (GNOME Camera is in 26.04) |
| [ ] | [Alacritty](https://alacritty.org) | GPU-accelerated terminal emulator | classic snap | desktop, apt |
| [ ] | [FileZilla](https://filezilla-project.org) | FTP and SFTP client | apt | desktop, Flatpak `org.filezillaproject.Filezilla` |
| [ ] | [OrcaSlicer](https://github.com/SoftFever/OrcaSlicer) | 3D-printer slicer | Flatpak | desktop |
| [ ] | [HandBrake](https://handbrake.fr) | Video transcoder with a GUI | Flatpak | desktop |
| [ ] | [ElegooSlicer](https://github.com/ELEGOO-3D/ElegooSlicer) | Elegoo's 3D-printer slicer, an OrcaSlicer fork | AppImage in `~/.local/bin` | skip, or custom with pinned URL |
| [ ] | [Raspberry Pi Imager](https://www.raspberrypi.com/software/) | Writes OS images to SD cards | apt | desktop, Flatpak `org.raspberrypi.rpi-imager` |
| [ ] | [gparted](https://gparted.org), [pavucontrol](https://freedesktop.org/software/pulseaudio/pavucontrol/), [gnome-shell-extension-manager](https://github.com/mjakeman/extension-manager) | Partition editor; per-app audio volume and devices; install and toggle GNOME extensions | apt | desktop |
| [ ] | [RealVNC Viewer](https://www.realvnc.com/) | Remote-desktop client for VNC | apt | skip |
| [ ] | [gftp](https://github.com/masneyb/gftp), [curlftpfs](http://curlftpfs.sourceforge.net), [innoextract](https://constexpr.org/innoextract/) | FTP client; mount FTP as a folder; unpack Windows Inno Setup installers | apt | skip |
| [ ] | [coder](https://coder.com), [goose](https://goose-docs.ai/) | Self-hosted dev environments; Goose AI agent desktop app | apt | skip |

## 3. Shell, GNOME and dotfiles

| Adopt | Item | What it is | Where today | Suggested |
|:-----:|------|------------|-------------|-----------|
| [ ] | [`~/.config/alacritty`](https://alacritty.org/config-alacritty.html) | Alacritty terminal settings | unmanaged | dotfiles |
| [ ] | [`~/.config/starship.toml`](https://starship.rs/config/) | Starship prompt configuration | missing | dotfiles |
| [ ] | [`~/.config/git/ignore`](https://git-scm.com/docs/gitignore) | Global git ignore patterns | managed by agentic-workspace | leave there |
| [ ] | [GNOME dconf](https://wiki.gnome.org/Projects/dconf) (dock, tiling-assistant, dark mode, keybindings) | GNOME's settings database; export once, load on install | unmanaged | `dotfiles/dconf.ini`, loaded by install.sh |
| [ ] | [GNOME extensions](https://extensions.gnome.org): tiling-assistant, appindicators, dock, ding | Ubuntu's default shell extensions: window tiling, tray icons, dock, desktop icons | Ubuntu defaults | leave |
| [ ] | Fonts: [`fonts-firacode`](https://github.com/tonsky/FiraCode) + a [Nerd Font](https://www.nerdfonts.com) for starship | Programming font with ligatures; patched fonts with the icons starship uses | partly | desktop |
| [ ] | `~/.zshrc`, `~/.config/fish` | Config for [zsh](https://www.zsh.org) and [fish](https://fishshell.com), shells that are no longer installed | orphaned (zsh, fish not installed) | delete |
| [ ] | `~/.config/{BraveSoftware,microsoft-edge,opera,vivaldi,chromium}` | Profiles of browsers that were uninstalled | leftovers, apps not installed | delete |
| [ ] | `~/.config/{unity3d,godot,Ultralytics,coderv2}` | Data from uninstalled game engines, a YOLO vision library and an old Coder version | leftovers | delete |

## 4. Hardware and embedded (candidate profile `embedded`)

| Adopt | Item | What it is | Where today | Suggested |
|:-----:|------|------------|-------------|-----------|
| [ ] | [`adb`, `fastboot`](https://developer.android.com/tools/releases/platform-tools) | Android debug bridge and bootloader flashing tool | apt | embedded |
| [ ] | [`libusb-1.0-0-dev`](https://libusb.info), [`libsdl2-dev`](https://www.libsdl.org), [`pkg-config`](https://www.freedesktop.org/wiki/Software/pkg-config/) | Headers to build USB tools; graphics and input library (NumWorks simulator); build-flag helper | apt | embedded |
| [ ] | [`arm-none-eabi-*`](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads) toolchain 14.2.1 | GCC cross-compiler for ARM microcontrollers | `~/.local/bin` | embedded (custom, pinned tarball) |
| [ ] | [PocketBook SDK](https://github.com/pocketbook/SDK_6.3.0) | Toolchain and libraries to build PocketBook e-reader apps | `~/opt/pocketbook-sdk` | embedded (custom) or skip |
| [ ] | [`esptool`](https://github.com/espressif/esptool), [`python3-serial`](https://github.com/pyserial/pyserial), [`minicom`](https://salsa.debian.org/minicom-team/minicom), user in `dialout` | Flash ESP32 boards; serial-port library; serial terminal; group that may open serial ports | not installed | embedded |

## 5. System-level leftovers to remove on the current machine

| Done | Item | Why it can go |
|:----:|------|---------------|
| [ ] | [NodeSource](https://github.com/nodesource/distributions) `node_20.x` apt source | Node 22 now comes from the Ubuntu archive |
| [ ] | `linux-generic-hwe-24.04` metapackage (24.04 leftover) | Hardware-enablement kernel track from 24.04; 26.04 ships its own kernel |
| [ ] | Chinese input methods: `ibus-table-cangjie*`, `libchewing3*`, `libpinyin*`, `m17n-db`, `libopencc*` | Input methods for Chinese that are not used |
| [ ] | `fluhus/gnome-googledrive` PPA (replaced by rclone) | Third-party Google Drive integration; rclone does this now |
| [ ] | Disabled apt lists: `vscode.list.disabled`, `github-cli.list.disabled`, `waydroid.list.disabled` | Dead repository files left by upgrades |
| [ ] | Old snap revisions and the `vlc` snap once the Flatpak is in | Disk space; duplicate VLC install |

## 6. Not for this repo

| Item | Belongs to |
|------|------------|
| `claude`, `gemini-cli`, `agy`, `kimi`, `twin`, `ask`, `agent`, `ollama` and models | agentic-workspace (stage 3) |
| `~/.ssh/id_ed25519`, `~/.config/rclone/rclone.conf` | password manager (stage 0) |
| `~/Repos` clone list, Documents and Pictures sync | stage 4 |
