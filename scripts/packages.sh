#!/usr/bin/env bash
# Package installation dispatcher — apt only (FEAT-0001).
# Additional package types (snap, flatpak, deb, custom) added in FEAT-0002.
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
