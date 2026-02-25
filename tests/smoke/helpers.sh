#!/usr/bin/env bash
# Shared assertion helpers for smoke tests.
# Source this file from individual test scripts — do not execute directly.
#
# Usage in a test script:
#   source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"
#   assert_cmd_success "curl is installed" command -v curl
#   assert_pkg_installed curl
#   assert_symlink ~/.bashrc /home/testuser/dotfiles/dotfiles/.bashrc
#   finish    # prints summary and exits 0/1

PASS=0
FAIL=0

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------
_pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
_fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

# ---------------------------------------------------------------------------
# Public assertions
# ---------------------------------------------------------------------------

# assert_cmd_success <description> <command> [args...]
# Passes if <command> exits 0, fails otherwise.
assert_cmd_success() {
  local desc="$1"; shift
  if "$@" &>/dev/null 2>&1; then
    _pass "$desc"
  else
    _fail "$desc"
  fi
}

# assert_cmd_fails <description> <command> [args...]
# Passes if <command> exits non-zero, fails if it exits 0.
assert_cmd_fails() {
  local desc="$1"; shift
  if ! "$@" &>/dev/null 2>&1; then
    _pass "$desc"
  else
    _fail "$desc"
  fi
}

# assert_pkg_installed <package>
# Passes if dpkg reports the package as installed.
assert_pkg_installed() {
  local pkg="$1"
  assert_cmd_success "Package installed: ${pkg}" dpkg -s "$pkg"
}

# assert_file_exists <path>
# Passes if the path exists (file or directory).
assert_file_exists() {
  local path="$1"
  assert_cmd_success "File exists: ${path}" test -e "$path"
}

# assert_symlink <link_path> <expected_target>
# Passes if <link_path> is a symlink pointing to <expected_target>.
assert_symlink() {
  local link="$1"
  local target="$2"
  local actual_target
  actual_target=$(readlink "$link" 2>/dev/null || echo "")

  if [[ -L "$link" && "$actual_target" == "$target" ]]; then
    _pass "Symlink: ${link} -> ${target}"
  else
    _fail "Symlink: ${link} -> ${target} (got: ${actual_target:-not a symlink})"
  fi
}

# assert_git_config <key> <expected_value>
# Passes if `git config --global <key>` returns <expected_value>.
assert_git_config() {
  local key="$1"
  local expected="$2"
  local actual
  actual=$(git config --global "$key" 2>/dev/null || echo "")
  if [[ "$actual" == "$expected" ]]; then
    _pass "git config ${key} = ${expected}"
  else
    _fail "git config ${key}: expected '${expected}', got '${actual}'"
  fi
}

# ---------------------------------------------------------------------------
# finish
# Prints a results summary and exits 0 (all passed) or 1 (any failed).
# Always call this at the end of a test script.
# ---------------------------------------------------------------------------
finish() {
  echo ""
  echo "  Results: ${PASS} passed, ${FAIL} failed"
  if [[ $FAIL -eq 0 ]]; then exit 0; else exit 1; fi
}
