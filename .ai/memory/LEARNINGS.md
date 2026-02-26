# AI Learnings

Accumulated project knowledge built up across sessions. This is the AI's long-term memory about this specific codebase — things that are not obvious from reading files alone.

> **AI Assistants**:
> - **Read** this file before touching any existing code
> - **Write** here when you discover something non-obvious: a gotcha, an undocumented constraint, a pattern that diverges from what you'd expect, or domain knowledge that took investigation to uncover
> - Keep entries concise; link to files/ADRs where relevant
> - Never delete entries — mark outdated ones with `[OUTDATED as of YYYY-MM-DD]` instead

---

## How to Add a Learning

Append under the relevant category. Format:

```markdown
### [Short title]
**Discovered**: YYYY-MM-DD | **Session**: NNN | **Relevant files**: `path/to/file`

[What you learned. Be specific enough that a future AI with no session history can act on this.]
```

---

## Codebase Gotchas

### `[[ cond ]] && cmd` triggers errexit under `set -e`
**Discovered**: 2026-02-25 | **Session**: 001 | **Relevant files**: `src/packages.sh`, `src/dotfiles.sh`, `install.sh`

Under `set -euo pipefail`, the expression `[[ false ]] && cmd` returns exit code 1 (from the failed `[[` test), which triggers `errexit` and kills the script. Always use `if [[ cond ]]; then cmd; fi` instead. This bit us in early implementations of the dry-run and dotfile linking logic.

### `return 0` not bare `return` in dotfile non-interactive guards
**Discovered**: 2026-02-25 | **Session**: 001 | **Relevant files**: `dotfiles/.bashrc`, `dotfiles/.bash_profile`

Dotfiles like `.bashrc` use a non-interactive guard at the top:
```bash
[[ $- == *i* ]] || return 0   # CORRECT
[[ $- == *i* ]] || return     # WRONG
```
A bare `return` inherits the exit code of the failed `[[ $- == *i* ]]` test (exit code 1). When `.bash_profile` sources `.bashrc`, that exit code 1 propagates out and causes `bash --login -c exit` to exit non-zero, breaking the smoke test `test-base-bash-login.sh`.

### Smoke tests that link dotfiles must use `--force`
**Discovered**: 2026-02-25 | **Session**: 001 | **Relevant files**: `tests/smoke/tests/test-base-dotfiles.sh`, `tests/smoke/Dockerfile`

Ubuntu's `useradd -m` copies `/etc/skel` files (`.bashrc`, `.bash_profile`, `.profile`) into the new user's `$HOME` before provisioning runs. Without `--force`, `install.sh` sees these pre-existing regular files and skips symlinking (warns instead). Smoke tests must pass `--force` to replace them. This affects any test that asserts symlinks are created.

---

## Patterns and Conventions

### python3 heredoc for YAML parsing
**Discovered**: 2026-02-25 | **Session**: 001 | **Relevant files**: `src/validate.sh`, `install.sh`

All YAML parsing uses `python3 - <<'PYEOF' ... PYEOF` inline heredocs rather than a separate `.py` file. python3 is guaranteed present on Ubuntu 22.04. The heredoc receives arguments via `sys.argv` (e.g. profiles directory, profile name). This keeps the codebase purely bash + python3 with zero installed dependencies.

### Validation runs before profile loading
**Discovered**: 2026-02-25 | **Session**: 001 | **Relevant files**: `install.sh`, `src/validate.sh`

`validate_profiles()` is called before `load_profile()` in `main()`. This is intentional: `validate_profiles()` walks the extends chain structurally (checking keys, list types, circular refs) while `load_profile()` does the actual merge. Running validation first ensures a structurally invalid profile never triggers partial provisioning.

---

## Domain Knowledge

### Profile inheritance is additive only
**Discovered**: 2026-02-25 | **Session**: 001 | **Relevant files**: `profiles/`, `install.sh`

The `extends:` key merges parent package lists before child lists (base-first). Packages are deduplicated within each type. There is no way to remove a package from a parent via inheritance — child profiles can only add, never subtract.

### Package install order is fixed
**Discovered**: 2026-02-25 | **Session**: 001 | **Relevant files**: `src/packages.sh`

Within a provisioning run, types are always installed in this order: apt → snap → flatpak → deb → custom. This is intentional because apt is the most common and may be required by others (e.g. flatpak itself is apt-installed if missing).

---

## Anti-Patterns (Do Not Repeat)

### Hardcoding package names in shell scripts
Any package that belongs in a profile must go in `profiles/*.yaml`, not in `install.sh` or `src/packages.sh`. The entire point of the YAML manifest is to separate policy (what to install) from mechanism (how to install).

### Running `sudo apt-get update` unconditionally
The `sudo apt-get update -qq` in `install_apt_packages()` is gated on `${DRY_RUN:-false}`. It should not be run in dry-run mode, and ideally only once per run — not once per package.

---

## Integration and Environment Notes

### Ubuntu 22.04 skel files
`/etc/skel` on Ubuntu 22.04 contains `.bashrc`, `.bash_profile`, and `.profile`. Any smoke test running as a fresh user will have these files as regular files in `$HOME` before `install.sh` runs. See the `--force` gotcha above.

### Docker smoke test isolation
Each smoke test scenario runs in a fresh `docker run --rm` container from the same image. The image is built once per `run-tests.sh` invocation. `--no-cache` is used by default; pass `--use-cache` during development to speed up iterative testing.

---

## Security Notes

*No security issues found to date. All secrets handling is explicitly out-of-scope for this repo.*
