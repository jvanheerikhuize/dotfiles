---
paths:
  - "tests/**/*.sh"
---

# Smoke test patterns (tests/smoke/)

Full detail: `.ai/architecture/PATTERNS.md` §12. Tests run in Docker (ubuntu:22.04)
via `bash tests/smoke/run-tests.sh`; new scenarios must be registered there.

## Header — differs from src/ scripts

```bash
#!/usr/bin/env bash
# Scenario: brief description.
# Verifies: AC-NNN from FEAT-XXXX
set -uo pipefail   # NOT -e — tests must continue past failures and report

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/../helpers.sh"
```

## Helpers (from helpers.sh)

`_pass` / `_fail`, `assert_file_perms <path> <octal>`,
`assert_file_contains <path> <substring>`,
`assert_output_contains <substring> <command...>`, and `finish` (summary + exit code) last.

## Standard install.sh invocation

```bash
printf "Test User\ntest@example.com\n" \
  | NON_INTERACTIVE=true bash "${REPO_ROOT}/install.sh" \
    --profile base --dotfiles-only --force --non-interactive &>/dev/null
```

Always pass `--force`: Ubuntu's `useradd -m` pre-creates `/etc/skel` copies in `$HOME`.
