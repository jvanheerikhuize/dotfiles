#!/usr/bin/env bash
# Package installation dispatcher — apt, snap, flatpak, deb, custom (FEAT-0001/0002).
# Source this file; do not execute directly.
set -euo pipefail

# Guard: source utils.sh only when not already loaded (i.e. when run standalone)
if ! declare -f log_info &>/dev/null; then
  _PKG_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${_PKG_SCRIPT_DIR}/utils.sh"
fi

# ---------------------------------------------------------------------------
# apt
# ---------------------------------------------------------------------------

# install_apt_package <package>
# Installs a single apt package idempotently.
install_apt_package() {
  local pkg="$1"

  if dpkg -s "$pkg" &>/dev/null 2>&1; then
    log_info "Already installed: ${pkg}"
    return 0
  fi

  log_info "Installing (apt): ${pkg}"
  if ! sudo apt-get install -y "$pkg" 2>&1; then
    log_error "apt-get failed for package: ${pkg}"
  fi
}

# install_apt_packages <package> [<package> ...]
# Runs apt-get update once then installs each package.
install_apt_packages() {
  local packages=("$@")

  if [[ ${#packages[@]} -eq 0 ]]; then
    log_info "No apt packages to install"
    return 0
  fi

  log_step "Installing apt packages (${#packages[@]} total)"

  log_info "Running apt-get update..."
  sudo apt-get update -qq

  for pkg in "${packages[@]}"; do
    install_apt_package "$pkg"
  done
}

# ---------------------------------------------------------------------------
# snap
# ---------------------------------------------------------------------------

# install_snap_package <package>
# Installs a single snap package idempotently.
install_snap_package() {
  local pkg="$1"

  if snap list "$pkg" &>/dev/null 2>&1; then
    log_info "Already installed (snap): ${pkg}"
    return 0
  fi

  log_info "Installing (snap): ${pkg}"
  if ! sudo snap install "$pkg"; then
    log_error "snap install failed: ${pkg}"
  fi
}

# install_snap_packages <package> [<package> ...]
install_snap_packages() {
  local packages=("$@")
  if [[ ${#packages[@]} -eq 0 ]]; then return 0; fi

  if ! command -v snap &>/dev/null; then
    log_error "snap is not available. Ensure snapd is installed (Stage 1 / apt install snapd)."
  fi

  log_step "Installing snap packages (${#packages[@]} total)"
  for pkg in "${packages[@]}"; do
    install_snap_package "$pkg"
  done
}

# ---------------------------------------------------------------------------
# flatpak
# ---------------------------------------------------------------------------

# _ensure_flatpak
# Installs flatpak via apt and adds the flathub remote if not already present.
_ensure_flatpak() {
  if ! command -v flatpak &>/dev/null; then
    log_info "flatpak not found — installing via apt"
    sudo apt-get install -y flatpak
  fi

  if ! flatpak remotes 2>/dev/null | grep -q flathub; then
    log_info "Adding flathub remote"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
}

# install_flatpak_package <app-id>
# Installs a single flatpak package idempotently.
install_flatpak_package() {
  local id="$1"

  if flatpak info "$id" &>/dev/null 2>&1; then
    log_info "Already installed (flatpak): ${id}"
    return 0
  fi

  log_info "Installing (flatpak): ${id}"
  if ! flatpak install -y flathub "$id"; then
    log_error "flatpak install failed: ${id}"
  fi
}

# install_flatpak_packages <app-id> [<app-id> ...]
install_flatpak_packages() {
  local packages=("$@")
  if [[ ${#packages[@]} -eq 0 ]]; then return 0; fi

  _ensure_flatpak

  log_step "Installing flatpak packages (${#packages[@]} total)"
  for id in "${packages[@]}"; do
    install_flatpak_package "$id"
  done
}

# ---------------------------------------------------------------------------
# deb (direct URL download)
# ---------------------------------------------------------------------------

# install_deb_package <name> <url>
# Downloads a .deb from a URL, installs it, and removes the temp file.
# Idempotency: skips if dpkg already reports the package as installed.
# Security: http URLs are skipped unless FORCE=true.
install_deb_package() {
  local name="$1"
  local url="$2"

  if [[ "$url" == http://* ]]; then
    if [[ "${FORCE:-false}" != "true" ]]; then
      log_warn "Insecure URL (http) for deb '${name}' — skipping. Use --force to override."
      return 0
    fi
    log_warn "Installing deb over http (--force): ${url}"
  fi

  if dpkg -s "$name" &>/dev/null 2>&1; then
    log_info "Already installed (deb): ${name}"
    return 0
  fi

  local tmp_file
  tmp_file=$(mktemp --suffix=.deb)

  log_info "Downloading (deb): ${url}"
  if ! wget -q -O "$tmp_file" "$url"; then
    rm -f "$tmp_file"
    log_error "Failed to download deb package '${name}': ${url}"
  fi

  log_info "Installing (deb): ${name}"
  if ! sudo dpkg -i "$tmp_file"; then
    rm -f "$tmp_file"
    log_error "dpkg -i failed for: ${name}"
  fi

  rm -f "$tmp_file"
}

# install_deb_packages <"name\turl"> [...]
# Each argument is a tab-separated "name<TAB>url" string.
install_deb_packages() {
  local entries=("$@")
  if [[ ${#entries[@]} -eq 0 ]]; then return 0; fi

  log_step "Installing deb packages (${#entries[@]} total)"
  local _name _url
  for entry in "${entries[@]}"; do
    IFS=$'\t' read -r _name _url <<< "$entry"
    install_deb_package "$_name" "$_url"
  done
}

# ---------------------------------------------------------------------------
# custom (arbitrary shell commands)
# ---------------------------------------------------------------------------

# install_custom_package <cmd> [<idempotency_check>]
# Runs <cmd> via bash -c. If <idempotency_check> is provided and exits 0, step is skipped.
install_custom_package() {
  local cmd="$1"
  local check="${2:-}"

  if [[ -n "$check" ]]; then
    if bash -c "$check" &>/dev/null 2>&1; then
      log_info "Already satisfied (custom): ${cmd}"
      return 0
    fi
  fi

  log_info "Running (custom): ${cmd}"
  if ! bash -c "$cmd"; then
    log_error "Custom command failed: ${cmd}"
  fi
}

# install_custom_packages <"cmd\tcheck"> [...]
# Each argument is a tab-separated "cmd<TAB>idempotency_check" string.
install_custom_packages() {
  local entries=("$@")
  if [[ ${#entries[@]} -eq 0 ]]; then return 0; fi

  log_step "Running custom install commands (${#entries[@]} total)"
  local _cmd _check
  for entry in "${entries[@]}"; do
    IFS=$'\t' read -r _cmd _check <<< "$entry"
    install_custom_package "$_cmd" "$_check"
  done
}
