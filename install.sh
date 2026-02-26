#!/usr/bin/env bash
# dotfiles — Stage 2 Ubuntu provisioner
# Usage: ./install.sh [--profile PROFILE] [--skip-dotfiles] [--dotfiles-only] [--force] [--dry-run] [--validate-only] [--quiet] [--non-interactive] [--help]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="${SCRIPT_DIR}/profiles"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"

source "${SCRIPT_DIR}/src/utils.sh"
source "${SCRIPT_DIR}/src/validate.sh"
source "${SCRIPT_DIR}/src/packages.sh"
source "${SCRIPT_DIR}/src/dotfiles.sh"
source "${SCRIPT_DIR}/src/setup-git-identity.sh"

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
PROFILE="base"
SKIP_DOTFILES=false
DOTFILES_ONLY=false
FORCE=false
DRY_RUN=false
VALIDATE_ONLY=false
QUIET=false
NON_INTERACTIVE=false

# Global arrays populated by load_profile()
APT_PACKAGES=()
SNAP_PACKAGES=()
FLATPAK_PACKAGES=()
DEB_PACKAGES=()     # entries are "name<TAB>url"
CUSTOM_PACKAGES=()  # entries are "cmd<TAB>idempotency_check"
_SEEN_PROFILES=()   # for circular extends detection
PROFILE_CHAIN=()    # in application order (base → ... → target)

# Summary tracking arrays (populated by install/link functions during the run)
INSTALLED_PACKAGES=()
SKIPPED_PACKAGES=()
LINKED_DOTFILES=()
SKIPPED_DOTFILES=()
WARNINGS=()

# Run state (used by print_summary and _on_exit trap)
RUN_FAILED=false
PROVISIONING_STARTED=false

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
  --validate-only      Validate profile YAML structure only; skip all installs and dotfiles
  --quiet              Suppress per-step log lines; summary is always shown
  --non-interactive    Skip git identity prompt; emit a warning instead
  --help               Show this help and exit

Profiles available: $(ls "${PROFILES_DIR}"/*.yaml 2>/dev/null | xargs -I{} basename {} .yaml | tr '\n' ' ')

Examples:
  ./install.sh                             # Apply base profile
  ./install.sh --profile dev               # Apply dev profile (includes base + desktop)
  ./install.sh --profile base --force      # Apply base, replace conflicting dotfiles
  ./install.sh --dotfiles-only             # Only symlink dotfiles, skip packages
  ./install.sh --profile dev --dry-run     # Preview what dev profile would do
  ./install.sh --profile base --validate-only  # Validate base profile YAML

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
      --validate-only)
        VALIDATE_ONLY=true
        shift
        ;;
      --quiet)
        QUIET=true
        shift
        ;;
      --non-interactive)
        NON_INTERACTIVE=true
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
# Run summary (printed via EXIT trap)
# ---------------------------------------------------------------------------

# print_summary
# Prints a structured summary of installed/skipped packages and dotfiles.
# Only runs if PROVISIONING_STARTED=true (skips for --help and --validate-only exits).
print_summary() {
  if [[ "$PROVISIONING_STARTED" != "true" ]]; then
    return 0
  fi

  local pkg_label dotfile_label header item
  if [[ "$DRY_RUN" == "true" ]]; then
    pkg_label="Would install"
    dotfile_label="Would link"
  else
    pkg_label="Installed"
    dotfile_label="Linked"
  fi

  if [[ "$RUN_FAILED" == "true" ]]; then
    header="Run Summary  [incomplete — error occurred]"
  else
    header="Run Summary"
  fi

  echo -e "\n${_BOLD}${_CYAN}==> ${header}${_RESET}"
  echo -e "    Elapsed: ${SECONDS}s"
  echo ""

  echo -e "    ${_BOLD}Packages — ${pkg_label} (${#INSTALLED_PACKAGES[@]})${_RESET}"
  for item in "${INSTALLED_PACKAGES[@]+"${INSTALLED_PACKAGES[@]}"}"; do
    echo "      - ${item}"
  done
  echo ""

  echo -e "    ${_BOLD}Packages — skipped / already installed (${#SKIPPED_PACKAGES[@]})${_RESET}"
  for item in "${SKIPPED_PACKAGES[@]+"${SKIPPED_PACKAGES[@]}"}"; do
    echo "      - ${item}"
  done
  echo ""

  echo -e "    ${_BOLD}Dotfiles — ${dotfile_label} (${#LINKED_DOTFILES[@]})${_RESET}"
  for item in "${LINKED_DOTFILES[@]+"${LINKED_DOTFILES[@]}"}"; do
    echo "      - ${item}"
  done
  echo ""

  echo -e "    ${_BOLD}Dotfiles — skipped (${#SKIPPED_DOTFILES[@]})${_RESET}"
  for item in "${SKIPPED_DOTFILES[@]+"${SKIPPED_DOTFILES[@]}"}"; do
    echo "      - ${item}"
  done
  echo ""

  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo -e "    ${_BOLD}${_YELLOW}Warnings (${#WARNINGS[@]})${_RESET}"
    for item in "${WARNINGS[@]}"; do
      echo "      - ${item}"
    done
    echo ""
  fi
}

# _on_exit
# EXIT trap handler — sets RUN_FAILED if exit code is non-zero, then prints summary.
_on_exit() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    RUN_FAILED=true
  fi
  print_summary
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  parse_args "$@"
  trap '_on_exit' EXIT

  # Pre-flight guards
  require_not_root
  require_cmd python3
  require_cmd git

  # Header
  log_step "dotfiles provisioner"
  log_info "Profile:  ${PROFILE}"
  log_info "Repo:     ${SCRIPT_DIR}"
  log_info "Home:     ${HOME}"
  if [[ "$FORCE" == "true" ]]; then            log_info "Mode:     --force (will replace existing dotfiles)"; fi
  if [[ "$SKIP_DOTFILES" == "true" ]]; then    log_info "Mode:     --skip-dotfiles"; fi
  if [[ "$DOTFILES_ONLY" == "true" ]]; then    log_info "Mode:     --dotfiles-only"; fi
  if [[ "$DRY_RUN" == "true" ]]; then          log_info "Mode:     --dry-run (no changes will be made)"; fi
  if [[ "$VALIDATE_ONLY" == "true" ]]; then    log_info "Mode:     --validate-only"; fi
  if [[ "$NON_INTERACTIVE" == "true" ]]; then  log_info "Mode:     --non-interactive"; fi

  # Validate profile YAML structure (before loading or installing)
  log_step "Validating profile"
  validate_profiles "$PROFILE"
  if [[ "$VALIDATE_ONLY" == "true" ]]; then
    log_info "Validation passed"
    exit 0
  fi

  # Mark provisioning as started — summary will print from here on
  PROVISIONING_STARTED=true

  # Load and merge profile chain
  log_step "Loading profile"
  load_profile "$PROFILE"
  deduplicate_packages

  local chain_str
  chain_str=$(IFS=" → "; echo "${PROFILE_CHAIN[*]}")
  log_info "Profile chain:  ${chain_str}"

  local _total_pkgs=$(( ${#APT_PACKAGES[@]} + ${#SNAP_PACKAGES[@]} + ${#FLATPAK_PACKAGES[@]} + ${#DEB_PACKAGES[@]} + ${#CUSTOM_PACKAGES[@]} ))
  if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then     log_info "apt      (${#APT_PACKAGES[@]}): ${APT_PACKAGES[*]}"; fi
  if [[ ${#SNAP_PACKAGES[@]} -gt 0 ]]; then    log_info "snap     (${#SNAP_PACKAGES[@]}): ${SNAP_PACKAGES[*]}"; fi
  if [[ ${#FLATPAK_PACKAGES[@]} -gt 0 ]]; then log_info "flatpak  (${#FLATPAK_PACKAGES[@]}): ${FLATPAK_PACKAGES[*]}"; fi
  if [[ ${#DEB_PACKAGES[@]} -gt 0 ]]; then     log_info "deb      (${#DEB_PACKAGES[@]})"; fi
  if [[ ${#CUSTOM_PACKAGES[@]} -gt 0 ]]; then  log_info "custom   (${#CUSTOM_PACKAGES[@]})"; fi
  if [[ $_total_pkgs -eq 0 ]]; then            log_info "No packages declared in this profile chain"; fi

  # Install packages in order: apt → snap → flatpak → deb → custom
  if [[ "$DOTFILES_ONLY" != "true" ]]; then
    if [[ $_total_pkgs -eq 0 ]]; then
      log_info "Nothing to install"
    else
      if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then     install_apt_packages "${APT_PACKAGES[@]}"; fi
      if [[ ${#SNAP_PACKAGES[@]} -gt 0 ]]; then    install_snap_packages "${SNAP_PACKAGES[@]}"; fi
      if [[ ${#FLATPAK_PACKAGES[@]} -gt 0 ]]; then install_flatpak_packages "${FLATPAK_PACKAGES[@]}"; fi
      if [[ ${#DEB_PACKAGES[@]} -gt 0 ]]; then     install_deb_packages "${DEB_PACKAGES[@]}"; fi
      if [[ ${#CUSTOM_PACKAGES[@]} -gt 0 ]]; then  install_custom_packages "${CUSTOM_PACKAGES[@]}"; fi
    fi
  else
    log_info "Skipping package installation (--dotfiles-only)"
  fi

  # Apply dotfiles, then bootstrap git identity (identity depends on linked .gitconfig)
  if [[ "$SKIP_DOTFILES" != "true" ]]; then
    apply_dotfiles "$DOTFILES_DIR" "$HOME" "$FORCE"
    setup_git_identity
  else
    log_info "Skipping dotfiles (--skip-dotfiles)"
  fi
}

main "$@"
