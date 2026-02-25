#!/usr/bin/env bash
# dotfiles — Stage 2 Ubuntu provisioner
# Usage: ./install.sh [--profile PROFILE] [--skip-dotfiles] [--dotfiles-only] [--force] [--help]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="${SCRIPT_DIR}/profiles"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"

source "${SCRIPT_DIR}/src/utils.sh"
source "${SCRIPT_DIR}/src/packages.sh"
source "${SCRIPT_DIR}/src/dotfiles.sh"

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
PROFILE="base"
SKIP_DOTFILES=false
DOTFILES_ONLY=false
FORCE=false
DRY_RUN=false

# Global arrays populated by load_profile()
APT_PACKAGES=()
SNAP_PACKAGES=()
FLATPAK_PACKAGES=()
DEB_PACKAGES=()     # entries are "name<TAB>url"
CUSTOM_PACKAGES=()  # entries are "cmd<TAB>idempotency_check"
_SEEN_PROFILES=()   # for circular extends detection
PROFILE_CHAIN=()    # in application order (base → ... → target)

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF

Usage: $(basename "$0") [options]

Options:
  --profile PROFILE    Profile to apply (default: base)
  --skip-dotfiles      Install packages only; skip dotfile symlinking
  --dotfiles-only      Apply dotfiles only; skip package installation
  --force              Replace existing dotfiles (backs up originals to .bak)
  --dry-run            Preview what would be installed/linked; make no changes
  --help               Show this help and exit

Profiles available: $(ls "${PROFILES_DIR}"/*.yaml 2>/dev/null | xargs -I{} basename {} .yaml | tr '\n' ' ')

Examples:
  ./install.sh                             # Apply base profile
  ./install.sh --profile dev               # Apply dev profile (includes base + desktop)
  ./install.sh --profile base --force      # Apply base, replace conflicting dotfiles
  ./install.sh --dotfiles-only             # Only symlink dotfiles, skip packages
  ./install.sh --profile dev --dry-run     # Preview what dev profile would do

EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)
        [[ $# -ge 2 ]] || log_error "--profile requires an argument"
        PROFILE="$2"
        shift 2
        ;;
      --skip-dotfiles)
        SKIP_DOTFILES=true
        shift
        ;;
      --dotfiles-only)
        DOTFILES_ONLY=true
        shift
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown argument: '$1'. Run with --help for usage."
        ;;
    esac
  done

  # Validate mutually exclusive flags
  if [[ "$SKIP_DOTFILES" == "true" && "$DOTFILES_ONLY" == "true" ]]; then
    log_error "--skip-dotfiles and --dotfiles-only cannot be used together"
  fi
}

# ---------------------------------------------------------------------------
# Profile loading (recursive, base-first)
# ---------------------------------------------------------------------------

# load_profile <profile_name>
# Recursively resolves the extends chain and populates:
#   APT_PACKAGES   — deduplicated list in application order
#   PROFILE_CHAIN  — profile names in application order (base → ... → target)
load_profile() {
  local profile_name="$1"
  local profile_file="${PROFILES_DIR}/${profile_name}.yaml"

  # Verify the profile file exists
  [[ -f "$profile_file" ]] || \
    log_error "Profile not found: '${profile_name}' (expected: ${profile_file})"

  # Circular extends detection
  local seen
  for seen in "${_SEEN_PROFILES[@]+"${_SEEN_PROFILES[@]}"}"; do
    if [[ "$seen" == "$profile_name" ]]; then
      log_error "Circular extends detected: '${profile_name}' is already in the chain: ${_SEEN_PROFILES[*]}"
    fi
  done
  _SEEN_PROFILES+=("$profile_name")

  # Recurse into parent first so packages are in base-first order
  local extends
  extends=$(yaml_get "$profile_file" "profile.extends")
  if [[ -n "$extends" ]]; then
    load_profile "$extends"
  fi

  # Collect packages from this profile (all types)
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && APT_PACKAGES+=("$pkg")
  done < <(yaml_get_list "$profile_file" "packages.apt")

  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && SNAP_PACKAGES+=("$pkg")
  done < <(yaml_get_list "$profile_file" "packages.snap")

  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && FLATPAK_PACKAGES+=("$pkg")
  done < <(yaml_get_list "$profile_file" "packages.flatpak")

  local _dname _durl
  while IFS= read -r _entry; do
    IFS=$'\t' read -r _dname _durl <<< "$_entry"
    [[ -n "$_dname" && -n "$_durl" ]] && DEB_PACKAGES+=("$_entry")
  done < <(yaml_get_list_pairs "$profile_file" "packages.deb" "name" "url")

  local _ccmd
  while IFS= read -r _entry; do
    IFS=$'\t' read -r _ccmd _ <<< "$_entry"
    [[ -n "$_ccmd" ]] && CUSTOM_PACKAGES+=("$_entry")
  done < <(yaml_get_list_pairs "$profile_file" "packages.custom" "cmd" "idempotency_check")

  # Record in application order (after recursion = base first)
  PROFILE_CHAIN+=("$profile_name")
}

# deduplicate_packages
# Removes duplicates from all package arrays while preserving order.
# DEB and CUSTOM entries are deduped by their first field (name / cmd).
deduplicate_packages() {
  local -A seen=()
  local result=()
  local item key

  _dedup_simple() {
    local -n _arr="$1"
    seen=(); result=()
    for item in "${_arr[@]+"${_arr[@]}"}"; do
      if [[ -z "${seen[$item]+set}" ]]; then seen["$item"]=1; result+=("$item"); fi
    done
    _arr=()
    if [[ ${#result[@]} -gt 0 ]]; then _arr=("${result[@]}"); fi
  }

  _dedup_paired() {
    local -n _arr="$1"
    seen=(); result=()
    for item in "${_arr[@]+"${_arr[@]}"}"; do
      IFS=$'\t' read -r key _ <<< "$item"
      if [[ -z "${seen[$key]+set}" ]]; then seen["$key"]=1; result+=("$item"); fi
    done
    _arr=()
    if [[ ${#result[@]} -gt 0 ]]; then _arr=("${result[@]}"); fi
  }

  _dedup_simple    APT_PACKAGES
  _dedup_simple    SNAP_PACKAGES
  _dedup_simple    FLATPAK_PACKAGES
  _dedup_paired    DEB_PACKAGES
  _dedup_paired    CUSTOM_PACKAGES
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  parse_args "$@"

  # Pre-flight guards
  require_not_root
  require_cmd python3
  require_cmd git

  # Header
  log_step "dotfiles provisioner"
  log_info "Profile:  ${PROFILE}"
  log_info "Repo:     ${SCRIPT_DIR}"
  log_info "Home:     ${HOME}"
  [[ "$FORCE" == "true" ]]         && log_info "Mode:     --force (will replace existing dotfiles)"
  [[ "$SKIP_DOTFILES" == "true" ]] && log_info "Mode:     --skip-dotfiles"
  [[ "$DOTFILES_ONLY" == "true" ]] && log_info "Mode:     --dotfiles-only"
  [[ "$DRY_RUN" == "true" ]]       && log_info "Mode:     --dry-run (no changes will be made)"

  # Load and merge profile chain
  log_step "Loading profile"
  load_profile "$PROFILE"
  deduplicate_packages

  local chain_str
  chain_str=$(IFS=" → "; echo "${PROFILE_CHAIN[*]}")
  log_info "Profile chain:  ${chain_str}"

  local _total_pkgs=$(( ${#APT_PACKAGES[@]} + ${#SNAP_PACKAGES[@]} + ${#FLATPAK_PACKAGES[@]} + ${#DEB_PACKAGES[@]} + ${#CUSTOM_PACKAGES[@]} ))
  [[ ${#APT_PACKAGES[@]} -gt 0 ]]     && log_info "apt      (${#APT_PACKAGES[@]}): ${APT_PACKAGES[*]}"
  [[ ${#SNAP_PACKAGES[@]} -gt 0 ]]    && log_info "snap     (${#SNAP_PACKAGES[@]}): ${SNAP_PACKAGES[*]}"
  [[ ${#FLATPAK_PACKAGES[@]} -gt 0 ]] && log_info "flatpak  (${#FLATPAK_PACKAGES[@]}): ${FLATPAK_PACKAGES[*]}"
  [[ ${#DEB_PACKAGES[@]} -gt 0 ]]     && log_info "deb      (${#DEB_PACKAGES[@]})"
  [[ ${#CUSTOM_PACKAGES[@]} -gt 0 ]]  && log_info "custom   (${#CUSTOM_PACKAGES[@]})"
  [[ $_total_pkgs -eq 0 ]]            && log_info "No packages declared in this profile chain"

  # Install packages in order: apt → snap → flatpak → deb → custom
  if [[ "$DOTFILES_ONLY" != "true" ]]; then
    if [[ $_total_pkgs -eq 0 ]]; then
      log_info "Nothing to install"
    else
      [[ ${#APT_PACKAGES[@]} -gt 0 ]]     && install_apt_packages "${APT_PACKAGES[@]}"
      [[ ${#SNAP_PACKAGES[@]} -gt 0 ]]    && install_snap_packages "${SNAP_PACKAGES[@]}"
      [[ ${#FLATPAK_PACKAGES[@]} -gt 0 ]] && install_flatpak_packages "${FLATPAK_PACKAGES[@]}"
      [[ ${#DEB_PACKAGES[@]} -gt 0 ]]     && install_deb_packages "${DEB_PACKAGES[@]}"
      [[ ${#CUSTOM_PACKAGES[@]} -gt 0 ]]  && install_custom_packages "${CUSTOM_PACKAGES[@]}"
    fi
  else
    log_info "Skipping package installation (--dotfiles-only)"
  fi

  # Apply dotfiles
  if [[ "$SKIP_DOTFILES" != "true" ]]; then
    apply_dotfiles "$DOTFILES_DIR" "$HOME" "$FORCE"
  else
    log_info "Skipping dotfiles (--skip-dotfiles)"
  fi

  log_step "Done"
  log_info "Provisioning complete for profile: ${PROFILE}"
}

main "$@"
