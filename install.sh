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

# Global arrays populated by load_profile()
APT_PACKAGES=()
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
  --help               Show this help and exit

Profiles available: $(ls "${PROFILES_DIR}"/*.yaml 2>/dev/null | xargs -I{} basename {} .yaml | tr '\n' ' ')

Examples:
  ./install.sh                        # Apply base profile
  ./install.sh --profile dev          # Apply dev profile (includes base + desktop)
  ./install.sh --profile base --force # Apply base, replace conflicting dotfiles
  ./install.sh --dotfiles-only        # Only symlink dotfiles, skip packages

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

  # Collect apt packages from this profile
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && APT_PACKAGES+=("$pkg")
  done < <(yaml_get_list "$profile_file" "packages.apt")

  # Record in application order (after recursion = base first)
  PROFILE_CHAIN+=("$profile_name")
}

# deduplicate_packages
# Removes duplicates from APT_PACKAGES while preserving order.
deduplicate_packages() {
  local -A seen=()
  local result=()
  local pkg

  for pkg in "${APT_PACKAGES[@]+"${APT_PACKAGES[@]}"}"; do
    if [[ -z "${seen[$pkg]+set}" ]]; then
      seen["$pkg"]=1
      result+=("$pkg")
    fi
  done

  APT_PACKAGES=()
  if [[ ${#result[@]} -gt 0 ]]; then
    APT_PACKAGES=("${result[@]}")
  fi
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

  # Load and merge profile chain
  log_step "Loading profile"
  load_profile "$PROFILE"
  deduplicate_packages

  local chain_str
  chain_str=$(IFS=" → "; echo "${PROFILE_CHAIN[*]}")
  log_info "Profile chain:  ${chain_str}"

  if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then
    log_info "Apt packages (${#APT_PACKAGES[@]}): ${APT_PACKAGES[*]}"
  else
    log_info "No apt packages declared in this profile chain"
  fi

  # Install packages
  if [[ "$DOTFILES_ONLY" != "true" ]]; then
    if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then
      install_apt_packages "${APT_PACKAGES[@]}"
    else
      log_info "Nothing to install"
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
