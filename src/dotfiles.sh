#!/usr/bin/env bash
# Dotfile symlink management.
# Source this file; do not execute directly.
set -euo pipefail

# Guard: source utils.sh only when not already loaded (i.e. when run standalone)
if ! declare -f log_info &>/dev/null; then
  _DOT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${_DOT_SCRIPT_DIR}/utils.sh"
fi

# ---------------------------------------------------------------------------
# link_dotfile <src> <dest> <force>
#
# Creates a symlink at <dest> pointing to <src>.
#
# Collision behaviour:
#   dest does not exist          → create symlink
#   dest is already correct      → skip (idempotent)
#   dest is a wrong symlink      → warn+skip | --force: replace
#   dest is a regular file/dir   → warn+skip | --force: backup (.bak) + replace
#   dest is an untouched /etc/skel copy (e.g. a fresh ~/.bashrc)
#                                → backup (.bak) + replace, no --force needed
# ---------------------------------------------------------------------------
link_dotfile() {
  local src="$1"    # absolute path inside the repo
  local dest="$2"   # absolute path inside $HOME
  local force="$3"  # "true" | "false"

  # Already correctly linked — nothing to do
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log_dry_run "Already linked correctly: ${dest} (skip)"
    else
      log_info "Already linked: ${dest}"
    fi
    SKIPPED_DOTFILES+=("${dest} (already linked)")
    return 0
  fi

  # A regular file identical to its /etc/skel original is the distro default,
  # not user content: replace it (with backup) as if --force were given.
  local skel="${SKEL_DIR:-/etc/skel}/${dest#"$HOME"/}"
  if [[ -f "$dest" && ! -L "$dest" && -f "$skel" ]] && cmp -s "$dest" "$skel"; then
    log_info "Replacing distro default: ${dest} (identical to ${skel})"
    force="true"
  fi

  # Destination exists (file, directory, or wrong symlink)
  if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
    if [[ "$force" != "true" ]]; then
      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_dry_run "Would skip: ${dest} — file exists (use --force to replace)"
      else
        log_warn "Skipping: ${dest} — already exists (use --force to replace)"
        WARNINGS+=("${dest} — already exists, not linked (use --force to replace)")
      fi
      SKIPPED_DOTFILES+=("${dest} (already exists — use --force to replace)")
      return 0
    fi
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log_dry_run "Would link: ${dest} → ${src} (replacing existing with backup)"
      LINKED_DOTFILES+=("$dest")
      return 0
    fi
    # --force: back up then replace
    mv "$dest" "${dest}.bak"
    log_info "Backed up: ${dest} → ${dest}.bak"
  else
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log_dry_run "Would link: ${dest} → ${src}"
      LINKED_DOTFILES+=("$dest")
      return 0
    fi
  fi

  # Create parent directory if it doesn't exist
  mkdir -p "$(dirname "$dest")"

  ln -sf "$src" "$dest"
  log_info "Linked: ${dest} → ${src}"
  LINKED_DOTFILES+=("$dest")
}

# ---------------------------------------------------------------------------
# apply_dotfiles <dotfiles_dir> <home_dir> <force>
#
# Iterates every file in <dotfiles_dir> (excluding .gitkeep) and symlinks
# it into <home_dir>, preserving subdirectory structure.
# ---------------------------------------------------------------------------
apply_dotfiles() {
  local dotfiles_dir="$1"
  local home_dir="$2"
  local force="$3"

  log_step "Applying dotfiles"

  # Count linkable files (excluding .gitkeep)
  local count
  count=$(find "$dotfiles_dir" -not -name '.gitkeep' -type f | wc -l)

  if [[ "$count" -eq 0 ]]; then
    log_info "No dotfiles to link (dotfiles/ is empty)"
    return 0
  fi

  # Iterate over all files in dotfiles/, preserving directory structure
  while IFS= read -r -d '' file; do
    local relative="${file#"${dotfiles_dir}/"}"
    local dest="${home_dir}/${relative}"
    link_dotfile "$file" "$dest" "$force"
  done < <(find "$dotfiles_dir" -not -name '.gitkeep' -type f -print0)
}

# ---------------------------------------------------------------------------
# apply_gnome_settings <dconf_ini>
#
# Loads GNOME settings (dock, tiling, theme) with `dconf load /`.
# Skips quietly when the file is missing or dconf is not available.
# ---------------------------------------------------------------------------
apply_gnome_settings() {
  local ini="$1"

  if [[ ! -f "$ini" ]]; then
    return 0
  fi
  if ! command -v dconf &>/dev/null; then
    log_warn "dconf not found — skipping GNOME settings"
    return 0
  fi

  log_step "Applying GNOME settings"
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_dry_run "Would load GNOME settings from ${ini}"
    return 0
  fi

  if dconf load / < "$ini"; then
    log_info "Loaded GNOME settings from ${ini}"
  else
    log_warn "dconf load failed for ${ini} (no graphical session?)"
    WARNINGS+=("GNOME settings not applied — run: dconf load / < ${ini}")
  fi
}
