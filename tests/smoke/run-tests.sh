#!/usr/bin/env bash
# Smoke test runner for the dotfiles provisioner.
# Builds a clean Ubuntu 22.04 Docker image from the repo and runs each scenario.
#
# Usage: tests/smoke/run-tests.sh [--profile PROFILE] [--use-cache] [--help]
#
# Options:
#   --profile PROFILE   Run only scenarios associated with PROFILE (e.g. base)
#   --use-cache         Allow Docker layer caching (faster during development)
#   --help              Show this help and exit
#
# Exit code: 0 if all scenarios pass, 1 if any fail.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

IMAGE_NAME="dotfiles-smoke-test"
NO_CACHE_FLAG="--no-cache"   # default: rebuild from scratch
PROFILE_FILTER=""             # empty = run all scenarios

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF

Usage: $(basename "$0") [options]

Options:
  --profile PROFILE   Run only scenarios for the given profile (e.g. base)
  --use-cache         Allow Docker layer caching (faster for development)
  --help              Show this help and exit

Scenarios:
  help                  install.sh --help exits 0
  unknown-profile       Unknown --profile name exits non-zero
  base-apt              All base profile apt packages are installed       [profile: base]
  base-dotfiles         Dotfile symlinks are created in \$HOME            [profile: base]
  base-bash-login       bash --login exits 0; aliases available           [profile: base]
  base-idempotency      Second run of install.sh exits 0                  [profile: base]
  base-dry-run          --dry-run makes no changes and exits 0            [profile: base]

EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { echo "ERROR: --profile requires an argument" >&2; exit 1; }
      PROFILE_FILTER="$2"
      shift 2
      ;;
    --use-cache)
      NO_CACHE_FLAG=""
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: '$1'" >&2
      usage
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Scenario registry
# Format: "name|profile|test_script"
# profile is "all" for scenarios that are not profile-specific.
# ---------------------------------------------------------------------------
SCENARIO_DEFS=(
  "help|all|test-help.sh"
  "unknown-profile|all|test-unknown-profile.sh"
  "base-apt|base|test-base-apt.sh"
  "base-dotfiles|base|test-base-dotfiles.sh"
  "base-bash-login|base|test-base-bash-login.sh"
  "base-idempotency|base|test-base-idempotency.sh"
  "base-dry-run|base|test-base-dry-run.sh"
)

# ---------------------------------------------------------------------------
# Build Docker image
# ---------------------------------------------------------------------------
echo ""
echo "==> Building Docker image: ${IMAGE_NAME}"
echo "    Context: ${REPO_ROOT}"
echo "    Dockerfile: ${SCRIPT_DIR}/Dockerfile"
[[ -n "$NO_CACHE_FLAG" ]] && echo "    Cache: disabled (use --use-cache for faster dev builds)"

# shellcheck disable=SC2086
docker build \
  ${NO_CACHE_FLAG} \
  --tag "${IMAGE_NAME}" \
  --file "${SCRIPT_DIR}/Dockerfile" \
  "${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Run scenarios
# ---------------------------------------------------------------------------
PASS=0
FAIL=0
SKIP=0

run_scenario() {
  local name="$1"
  local script="$2"
  local test_path="/home/testuser/dotfiles/tests/smoke/tests/${script}"

  echo ""
  echo "--- Scenario: ${name} ---"

  if docker run --rm "${IMAGE_NAME}" bash "${test_path}"; then
    PASS=$((PASS + 1))
    echo "  => PASSED"
  else
    FAIL=$((FAIL + 1))
    echo "  => FAILED"
  fi
}

for def in "${SCENARIO_DEFS[@]}"; do
  IFS='|' read -r name profile script <<< "$def"

  # Apply --profile filter: skip scenarios that don't match
  if [[ -n "$PROFILE_FILTER" ]]; then
    if [[ "$profile" != "$PROFILE_FILTER" && "$profile" != "all" ]]; then
      SKIP=$((SKIP + 1))
      continue
    fi
  fi

  run_scenario "$name" "$script"
done

# ---------------------------------------------------------------------------
# Clean up the image to avoid leaving artifacts on the host (AC constraint)
# ---------------------------------------------------------------------------
echo ""
echo "==> Removing Docker image: ${IMAGE_NAME}"
docker image rm "${IMAGE_NAME}" &>/dev/null || true

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "==> Smoke test summary"
echo "    Passed:  ${PASS}"
echo "    Failed:  ${FAIL}"
[[ $SKIP -gt 0 ]] && echo "    Skipped: ${SKIP}"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "RESULT: FAILED (${FAIL} scenario(s) failed)"
  exit 1
else
  echo "RESULT: PASSED"
  exit 0
fi
