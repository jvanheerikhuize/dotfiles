# Traceability Matrix

End-to-end audit trail linking every user request to the spec, architectural decisions, code changes, and PR that fulfilled it.

> **AI Assistants**: Update this file whenever any link in the chain is established — do not wait until the work is complete. A partial row is better than no row.

---

## How to Add a Row

Use the next sequential TR-NNN ID. Fill in what you know; leave unknowns as `—`.

```markdown
| TR-NNN | [Brief request title] | [Spec file or —] | [ADR-NNN or —] | [Files changed] | [PR # or commit or —] | [Status] |
```

**Status values**: `In Progress` | `Implemented` | `Merged` | `Superseded` | `Abandoned`

---

## Matrix

| ID | Request | Spec | ADR | Key Files Changed | PR / Commit | Status |
|----|---------|------|-----|-------------------|-------------|--------|
| TR-001 | Core provisioning engine: install.sh, apt packages, profile inheritance, dotfile symlinking | [FEAT-0001](../../specs/features/FEAT-0001-core-provisioning-engine.yaml) | — | `install.sh`, `src/utils.sh`, `src/packages.sh`, `src/dotfiles.sh`, `profiles/base.yaml` | [PR #1](https://github.com/jvanheerikhuize/dotfiles/pull/1) | Merged |
| TR-002 | Multi-type package support: snap, flatpak, deb URL, custom script | [FEAT-0002](../../specs/features/FEAT-0002-multi-type-package-support.yaml) | — | `src/packages.sh`, `profiles/` | [PR #2](https://github.com/jvanheerikhuize/dotfiles/pull/2) | Merged |
| TR-003 | Base shell dotfiles: .bashrc, .bash_aliases, .bash_profile, .gitconfig | [FEAT-0003](../../specs/features/FEAT-0003-base-shell-dotfiles.yaml) | — | `dotfiles/.bashrc`, `dotfiles/.bash_aliases`, `dotfiles/.bash_profile`, `dotfiles/.gitconfig` | [PR #3](https://github.com/jvanheerikhuize/dotfiles/pull/3) | Merged |
| TR-004 | Docker-based smoke test suite | [FEAT-0004](../../specs/features/FEAT-0004-smoke-test-suite.yaml) | — | `tests/smoke/Dockerfile`, `tests/smoke/run-tests.sh`, `tests/smoke/helpers.sh`, `tests/smoke/tests/` | [PR #4](https://github.com/jvanheerikhuize/dotfiles/pull/4) | Merged |
| TR-005 | --dry-run mode: preview installs and symlinks without executing | [FEAT-0005](../../specs/features/FEAT-0005-dry-run-mode.yaml) | — | `install.sh`, `src/packages.sh`, `src/dotfiles.sh`, `src/utils.sh`, `tests/smoke/tests/test-base-dry-run.sh` | [PR #5](https://github.com/jvanheerikhuize/dotfiles/pull/5) | Merged |
| TR-006 | Profile YAML validation: validate_profiles() + --validate-only flag | [FEAT-0006](../../specs/features/FEAT-0006-profile-yaml-validation.yaml) | — | `src/validate.sh`, `install.sh`, `tests/smoke/tests/test-validate-only.sh`, `tests/smoke/tests/test-validate-invalid.sh` | [PR #6](https://github.com/jvanheerikhuize/dotfiles/pull/6) | Merged |
| TR-007 | AI governance system: DIRECTIVES.md, memory system, ADR infrastructure, template-sync runbook | [FEAT-0015](../../specs/features/FEAT-0015-ai-governance-system.yaml) | — | `.ai/DIRECTIVES.md`, `.ai/memory/`, `.ai/decisions/README.md`, `.ai/decisions/INDEX.md`, `docs/runbooks/template-sync.md`, `.claude/CLAUDE.md` | [PR #7](https://github.com/jvanheerikhuize/dotfiles/pull/7) | In Progress |
| TR-008 | Git identity bootstrap: prompt for name/email after dotfiles; write ~/.gitconfig.local | [FEAT-0008](../../specs/features/FEAT-0008-git-identity-bootstrap.yaml) | — | `src/setup-git-identity.sh`, `dotfiles/.gitconfig`, `install.sh`, `tests/smoke/tests/test-git-identity-*.sh` | — | Implemented |

---

**Next TR ID: 009**

---

## How to Read This Table

- **ID**: Unique trace identifier. Reference this in commit messages, PRs, and session logs.
- **Request**: The original user request or issue that initiated the work.
- **Spec**: The feature spec that formalises the request (link to `specs/features/*.yaml`).
- **ADR**: Any architectural decision made during implementation (link to `.ai/decisions/ADR-NNN-*.md`).
- **Key Files Changed**: The most significant files modified — not exhaustive, but enough to find the change.
- **PR / Commit**: The Git reference that delivered the change.
- **Status**: Current state of this trace.

## Cross-References

- Full decision rationale: [.ai/decisions/INDEX.md](../decisions/INDEX.md)
- Session-by-session history: [SESSION_LOG.md](SESSION_LOG.md)
- Accumulated knowledge: [LEARNINGS.md](LEARNINGS.md)
