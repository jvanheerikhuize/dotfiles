#!/usr/bin/env bash
# src/setup-ssh.sh — Bootstrap an ed25519 SSH keypair on a fresh machine.
#
# Checks if ~/.ssh/id_ed25519 already exists — if so, skips generation.
# Creates ~/.ssh/ with mode 700 if absent, generates the keypair, sets
# permissions, writes a minimal ~/.ssh/config if none exists, then prints
# the public key with instructions to add it to GitHub/GitLab.
#
# Called by install.sh after packages are installed.
# Can also be run standalone: src/setup-ssh.sh [--non-interactive]
#
# Environment variables (inherited from install.sh when sourced):
#   NON_INTERACTIVE  — if "true", use -N '' (no passphrase) + emit log_warn
#   DRY_RUN          — if "true", emit log_dry_run; make no changes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Defaults — may be overridden by the calling environment (install.sh).
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
DRY_RUN="${DRY_RUN:-false}"

SSH_DIR="${HOME}/.ssh"
KEY_PATH="${SSH_DIR}/id_ed25519"
PUB_PATH="${SSH_DIR}/id_ed25519.pub"
CONFIG_PATH="${SSH_DIR}/config"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Ensure ~/.ssh/ exists with mode 700.
_ensure_ssh_dir() {
  if [[ ! -d "$SSH_DIR" ]]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    log_info "Created ${SSH_DIR} (mode 700)"
  fi
}

# Generate the ed25519 keypair.
# $1 — passphrase flag: "-N ''" for no passphrase, or empty to let ssh-keygen prompt.
_generate_keypair() {
  local comment
  comment="$(whoami)@$(hostname)"

  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    # AC-006: no passphrase in non-interactive mode.
    ssh-keygen -t ed25519 -C "$comment" -f "$KEY_PATH" -N '' -q
    log_warn "SSH key generated without passphrase (non-interactive mode)"
  else
    # Interactive: let ssh-keygen prompt the user for an optional passphrase.
    ssh-keygen -t ed25519 -C "$comment" -f "$KEY_PATH"
  fi

  chmod 600 "$KEY_PATH"
  chmod 644 "$PUB_PATH"
  log_info "Generated ${KEY_PATH} (comment: ${comment})"
  log_info "Permissions: private=600, public=644"
}

# Write a minimal ~/.ssh/config if one does not exist.
_write_ssh_config() {
  if [[ -f "$CONFIG_PATH" ]]; then
    log_info "SSH config already exists, skipping: ${CONFIG_PATH}"
    return 0
  fi

  cat > "$CONFIG_PATH" <<'EOF'
Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
EOF
  chmod 600 "$CONFIG_PATH"
  log_info "Wrote ${CONFIG_PATH} (mode 600)"
}

# Print the public key with clear instructions.
_print_public_key() {
  echo ""
  echo "==> Your SSH public key (add this to GitHub/GitLab):"
  cat "$PUB_PATH"
  echo ""
  log_info "GitHub: https://github.com/settings/ssh/new"
}

# ---------------------------------------------------------------------------
# Main setup function — called by install.sh (sourced) and standalone entry.
# ---------------------------------------------------------------------------
setup_ssh_key() {
  log_step "SSH key setup"

  # DRY_RUN: preview only; make no changes.
  if [[ "$DRY_RUN" == "true" ]]; then
    log_dry_run "Would generate ${KEY_PATH} and ${PUB_PATH}"
    log_dry_run "Would write ${CONFIG_PATH} if absent"
    return 0
  fi

  # AC-001 / AC-002: generate keypair if absent; skip with log if already present.
  # key_generated tracks whether to print the public key at the end (AC-005).
  local key_generated=false
  if [[ -f "$KEY_PATH" ]]; then
    log_info "SSH key already exists: ${KEY_PATH}"
  else
    _ensure_ssh_dir
    _generate_keypair
    key_generated=true
  fi

  # AC-003 / AC-004: config check always runs, independent of key generation.
  # Ensures ~/.ssh/config exists even on re-runs.
  _write_ssh_config

  # AC-005: print public key only when freshly generated.
  if [[ "$key_generated" == "true" ]]; then
    _print_public_key
  fi
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

  setup_ssh_key
fi
