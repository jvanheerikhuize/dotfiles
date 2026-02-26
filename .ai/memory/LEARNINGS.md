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

<!-- Things that are easy to get wrong in this specific codebase -->

### SCRIPT_DIR clobbering in install.sh when sourcing setup-*.sh scripts
**Discovered**: 2026-02-26 | **Session**: 001 | **Relevant files**: `install.sh`, `src/setup-git-identity.sh`, `src/setup-ssh.sh`

`src/setup-git-identity.sh` and `src/setup-ssh.sh` both define `SCRIPT_DIR` at global scope so they can be run standalone. When `install.sh` sources them, their `SCRIPT_DIR` assignment overwrites the value install.sh set at the top. Any `source "${SCRIPT_DIR}/src/..."` call appearing **after** one of these sourced scripts resolves to `src/src/...` and fails silently as a missing file.

**Fix**: `install.sh` captures the repo root in `_INSTALL_ROOT` immediately after setting `SCRIPT_DIR`, before any source call. All source calls and path variables use `_INSTALL_ROOT`. Any new `setup-*.sh` script added to install.sh must be sourced via `_INSTALL_ROOT`, not `SCRIPT_DIR`.

---

## Patterns and Conventions

<!-- Patterns in use that diverge from common defaults, or that are project-specific -->

*No entries yet.*

---

## Domain Knowledge

<!-- Business rules, domain terms, or constraints that are not obvious from reading code -->

*No entries yet.*

---

## Anti-Patterns (Do Not Repeat)

<!-- Things that were tried and failed, or explicitly rejected — with reasons -->

*No entries yet.*

---

## Integration and Environment Notes

<!-- Quirks about CI/CD, tooling, environment setup, or external dependencies -->

*No entries yet.*

---

## Security Notes

<!-- Security-relevant constraints or past issues — treat with care -->

*No entries yet.*
