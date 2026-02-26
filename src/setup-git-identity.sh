#!/usr/bin/env bash
# src/setup-git-identity.sh — Bootstrap git user identity on a fresh machine.
#
# Checks if git user.name and user.email are already configured globally.
# If not, prompts interactively and writes them to ~/.gitconfig.local, which
# is picked up via [include] path = ~/.gitconfig.local in dotfiles/.gitconfig.
#
# Called by install.sh after dotfiles are linked (FEAT-0008).
# Can also be run standalone: src/setup-git-identity.sh [--non-interactive]
#
# Environment variables (inherited from install.sh when sourced):
#   NON_INTERACTIVE  — if "true", skip prompts and emit a log_warn instead
#   DRY_RUN          — if "true", emit log_dry_run; make no changes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Defaults — may be overridden by the calling environment (install.sh) or by
# the standalone arg parser below.
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
GITCONFIG_LOCAL="${HOME}/.gitconfig.local"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Returns 0 if both user.name and user.email are already set globally.
_git_identity_configured() {
  local name email
  name=$(git config --global user.name 2>/dev/null || true)
  email=$(git config --global user.email 2>/dev/null || true)
  [[ -n "$name" && -n "$email" ]]
}

# Returns 0 if the email looks valid (contains '@' followed by at least one '.').
_valid_email() {
  local email="$1"
  [[ "$email" == *@*.* ]]
}

# Write a [user] stanza to ~/.gitconfig.local.
_write_gitconfig_local() {
  local name="$1"
  local email="$2"
  cat > "$GITCONFIG_LOCAL" <<EOF
[user]
	name = ${name}
	email = ${email}
EOF
  log_info "Git identity written to ${GITCONFIG_LOCAL}"
}

# Ensure ~/.gitconfig has an [include] pointing to GITCONFIG_LOCAL.
#
# When ~/.gitconfig is a symlink (e.g. managed by dotfiles.sh), git config
# cannot reliably follow [include] directives inside the symlink target when
# that target lives inside another git repository (git 2.34 / Ubuntu 22.04).
# Calling `git config --global include.path` reads the symlink target and
# re-writes ~/.gitconfig as a real file via rename(2), replacing the tilde
# path with the absolute path supplied here.  Subsequent `git config --global`
# calls read a real file and follow [include] correctly.
#
# If ~/.gitconfig is already a real file the call is still safe — it either
# replaces an existing include.path entry or adds a new one.
_register_gitconfig_include() {
  git config --global include.path "${GITCONFIG_LOCAL}"
  log_info "Include path registered: ${GITCONFIG_LOCAL}"
}

# ---------------------------------------------------------------------------
# Main setup function — called by install.sh (sourced) and standalone entry.
# ---------------------------------------------------------------------------
setup_git_identity() {
  log_step "Git identity bootstrap"

  # AC-002 / AC-004: identity already present — nothing to do.
  if _git_identity_configured; then
    local cur_name cur_email
    cur_name=$(git config --global user.name)
    cur_email=$(git config --global user.email)
    log_info "Git identity already configured: ${cur_name} <${cur_email}>"
    return 0
  fi

  # DRY_RUN: preview only; never write the file.
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_dry_run "Would prompt for git identity and write ${GITCONFIG_LOCAL}"
    return 0
  fi

  # AC-003: caller explicitly requested non-interactive mode.
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    log_warn "Git identity not configured — run src/setup-git-identity.sh manually"
    return 0
  fi

  # AC-001: prompt for name — re-prompt if empty; exit gracefully on EOF.
  local name=""
  while [[ -z "$name" ]]; do
    printf "  Enter your git name:  "
    if ! read -r name; then
      # stdin is closed (e.g. non-TTY Docker environment) — treat as non-interactive.
      log_warn "Git identity not configured — run src/setup-git-identity.sh manually"
      return 0
    fi
    if [[ -z "$name" ]]; then
      echo "  Name cannot be empty. Please try again."
    fi
  done

  # AC-001: prompt for email — re-prompt on invalid format; exit gracefully on EOF.
  local email=""
  while true; do
    printf "  Enter your git email: "
    if ! read -r email; then
      log_warn "Git identity not configured — run src/setup-git-identity.sh manually"
      return 0
    fi
    if _valid_email "$email"; then
      break
    else
      echo "  Invalid email (must contain '@' and '.'). Please try again."
    fi
  done

  _write_gitconfig_local "$name" "$email"
  _register_gitconfig_include
  log_info "git config user.name  = $(git config --file "${GITCONFIG_LOCAL}" user.name 2>/dev/null || echo '(pending)')"
  log_info "git config user.email = $(git config --file "${GITCONFIG_LOCAL}" user.email 2>/dev/null || echo '(pending)')"
}

# ---------------------------------------------------------------------------
# Standalone entrypoint — only runs when the script is executed directly,
# not when it is sourced by install.sh.
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --non-interactive)
        NON_INTERACTIVE=true
        shift
        ;;
      *)
        log_error "Unknown argument: '$1'. Usage: $(basename "$0") [--non-interactive]"
        ;;
    esac
  done

  setup_git_identity
fi
