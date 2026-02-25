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
# ---------------------------------------------------------------------------
link_dotfile() {
  local src="$1"    # absolute path inside the repo
  local dest="$2"   # absolute path inside $HOME
  local force="$3"  # "true" | "false"

  # Already correctly linked — nothing to do
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    log_info "Already linked: ${dest}"
    return 0
  fi

  # Destination exists (file, directory, or wrong symlink)
  if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
    if [[ "$force" != "true" ]]; then
      log_warn "Skipping: ${dest} — already exists (use --force to replace)"
      return 0
    fi
    # --force: back up then replace
    mv "$dest" "${dest}.bak"
    log_info "Backed up: ${dest} → ${dest}.bak"
  fi

  # Create parent directory if it doesn't exist
  mkdir -p "$(dirname "$dest")"

  ln -sf "$src" "$dest"
  log_info "Linked: ${dest} → ${src}"
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
    log_info "No dotfiles to link (dotfiles/ is empty — populated in FEAT-0003)"
    return 0
  fi

  # Iterate over all files in dotfiles/, preserving directory structure
  while IFS= read -r -d '' file; do
    local relative="${file#"${dotfiles_dir}/"}"
    local dest="${home_dir}/${relative}"
    link_dotfile "$file" "$dest" "$force"
  done < <(find "$dotfiles_dir" -not -name '.gitkeep' -type f -print0)
}
