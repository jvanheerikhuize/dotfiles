# Session Log

Chronological record of every AI session. Each entry captures what was requested, what was done, and what was left open — so the next session starts with full context.

> **AI Assistants**:
> - **Start of session**: Read the most recent entry to understand open items and recent state
> - **End of session**: Append a new entry using the template below
> - Never edit past entries; only append

---

## Entry Template

Copy this block and fill it in at the end of each session:

```markdown
## [YYYY-MM-DD] Session NNN

**AI**: [Model name, e.g. Claude Sonnet 4.6]
**Requested by**: [human | automation | spec-ingestion]
**Summary**: [1–2 sentence description of what this session accomplished]

### Requests
- [What the user asked for, verbatim or paraphrased]

### Changes Made
| File | Change |
|------|--------|
| `path/to/file.md` | Created / Updated / Deleted — brief reason |

### Decisions Made
- [ADR-NNN](../decisions/ADR-NNN-title.md): [One-line summary]

### Traceability
- Trace IDs updated in [TRACEABILITY.md](TRACEABILITY.md): [TR-NNN, ...]
- Specs referenced: [specs/features/feature-name.yaml, ...]
- PR / Commit: [link or hash]

### Open Items
- [ ] [Something left unfinished or that needs follow-up next session]
```

---

## Log

## [2026-02-25] Session 001

**AI**: Claude Sonnet 4.6
**Requested by**: human
**Summary**: Bootstrapped the entire dotfiles provisioning system from scratch, implementing FEAT-0001 through FEAT-0006 across multiple context windows.

### Requests
- Implement FEAT-0001: Core provisioning engine (install.sh, apt packages, profile inheritance, dotfile symlinking)
- Implement FEAT-0002: Multi-type package support (snap, flatpak, deb URL, custom script)
- Implement FEAT-0003: Base shell dotfiles (.bashrc, .bash_aliases, .bash_profile, .gitconfig)
- Implement FEAT-0004: Docker-based smoke test suite
- Implement FEAT-0005: --dry-run mode (DRY_RUN variable gates all mutations)
- Implement FEAT-0006: Profile YAML validation (validate_profiles() + --validate-only flag)

### Changes Made
| File | Change |
|------|--------|
| `install.sh` | Created — main entrypoint; arg parsing, profile loading, orchestration |
| `src/utils.sh` | Created — log_info/warn/error/dry_run/step, require_cmd, yaml_get helpers |
| `src/packages.sh` | Created — apt/snap/flatpak/deb/custom install functions with DRY_RUN gating |
| `src/dotfiles.sh` | Created — symlink creation with collision handling and DRY_RUN gating |
| `src/validate.sh` | Created — validate_profiles() python3 heredoc; checks keys, extends, circular refs, list types |
| `profiles/base.yaml` | Created — base profile with core apt packages |
| `profiles/desktop.yaml` | Created — extends base; GUI/desktop packages |
| `profiles/server.yaml` | Created — extends base; server/headless packages |
| `profiles/dev.yaml` | Created — extends desktop; full developer environment |
| `dotfiles/.bashrc` | Created — prompt, history, colour, sources .bash_aliases |
| `dotfiles/.bash_aliases` | Created — ll/la, grep, git shortcuts, navigation aliases |
| `dotfiles/.bash_profile` | Created — login shell; sources .bashrc |
| `dotfiles/.gitconfig` | Created — core git settings and aliases (no identity) |
| `tests/smoke/Dockerfile` | Created — Ubuntu 22.04 with sudo+git+python3; non-root testuser |
| `tests/smoke/run-tests.sh` | Created — image build, scenario runner, pass/fail reporting |
| `tests/smoke/helpers.sh` | Created — assert_* functions |
| `tests/smoke/tests/` | Created — 9 test scripts covering all key scenarios |
| `.ai/CONTEXT.md` | Updated after each FEAT implementation |
| `.ai/architecture/ARCHITECTURE.md` | Updated after each FEAT implementation |
| `.ai/architecture/PATTERNS.md` | Updated after each FEAT implementation |
| `specs/features/FEAT-000[1-6]-*.yaml` | Updated status to "implemented" |
| `specs.config.yaml` | Updated FEAT-0001 through FEAT-0006 status to "implemented" |

### Decisions Made
- No ADRs created (ADR infrastructure not yet in place)

### Traceability
- Trace IDs: TR-001 through TR-006 (see TRACEABILITY.md)
- Specs referenced: FEAT-0001 through FEAT-0006
- PRs: #1 (FEAT-0001), #2 (FEAT-0002), #3 (FEAT-0003), #4 (FEAT-0004), #5 (FEAT-0005), #6 (FEAT-0006)

### Open Items
- [ ] FEAT-0007 through FEAT-0014 remain as draft specs
- [ ] FEAT-0015 (this governance system) is in progress on branch FEAT-0015-ai-governance-system

## [2026-02-26] Session 002

**AI**: Claude Sonnet 4.6
**Requested by**: human
**Summary**: Created FEAT-0015 spec to adopt AI governance system from the upstream template repository, then implemented it: DIRECTIVES.md, .ai/memory/ system, .ai/decisions/ ADR infrastructure, template-sync runbook.

### Requests
- "I updated your template repository can you create a high prio feature to adopt these changes in this repository?"
- "prepare to implement FEAT-0015"
- "go"

### Changes Made
| File | Change |
|------|--------|
| `specs/features/FEAT-0015-ai-governance-system.yaml` | Created — high-priority draft spec |
| `specs.config.yaml` | Updated — registered FEAT-0015 |
| `.ai/DIRECTIVES.md` | Created — mandatory AI rules, all 6 sections filled in for this project |
| `.ai/memory/README.md` | Created — memory system overview |
| `.ai/memory/AUTHORIZATIONS.md` | Created — base rules + empty learned auths table |
| `.ai/memory/SESSION_LOG.md` | Created — this file; backfilled Session 001 |
| `.ai/memory/LEARNINGS.md` | Created — seeded with key gotchas from MEMORY.md |
| `.ai/memory/TRACEABILITY.md` | Created — TR-001 through TR-006 backfilled |
| `.ai/decisions/README.md` | Created — ADR guide |
| `.ai/decisions/INDEX.md` | Created — empty ADR index |
| `docs/runbooks/template-sync.md` | Created — three sync approaches documented |
| `.claude/CLAUDE.md` | Updated — DIRECTIVES.md added to Quick Start |
| `.ai/prompts/create-repository.md` | Deleted — template meta-prompt, irrelevant to this project |
| `specs/features/FEAT-0015-ai-governance-system.yaml` | Updated status to "implemented" |
| `specs.config.yaml` | Updated FEAT-0015 status to "implemented" |

### Decisions Made
- No ADRs created (governance system adoption is documentation only; no architectural decisions)

### Traceability
- Trace IDs: TR-007 (see TRACEABILITY.md)
- Specs referenced: specs/features/FEAT-0015-ai-governance-system.yaml
- PR: #7

### Open Items
- [ ] FEAT-0008 through FEAT-0014 remain as draft specs (v1.1 and v1.2 backlog)

## [2026-02-26] Session 003

**AI**: Claude Sonnet 4.6
**Requested by**: human
**Summary**: Prepared and implemented FEAT-0008 (git identity bootstrap) on branch FEAT-0008-git-identity-bootstrap.

### Requests
- "can you prepare to create FEAT-0008" — analysis, plan, ambiguity flags
- "no" / "i confirm your assumption in the ambiguity" — --dotfiles-only still runs identity; only --skip-dotfiles skips it
- "can you create a branch for FEAT-0008"
- "go" — implement

### Changes Made
| File | Change |
|------|--------|
| `src/setup-git-identity.sh` | Created — identity bootstrap; EOF detection for non-TTY Docker |
| `dotfiles/.gitconfig` | Updated — added [include] path = ~/.gitconfig.local (AC-005) |
| `install.sh` | Updated — --non-interactive flag; source + call setup_git_identity after apply_dotfiles |
| `tests/smoke/tests/test-git-identity-fresh.sh` | Created — AC-001 |
| `tests/smoke/tests/test-git-identity-idempotent.sh` | Created — AC-002 + AC-004 |
| `tests/smoke/tests/test-git-identity-non-interactive.sh` | Created — AC-003 |
| `tests/smoke/tests/test-git-identity-standalone.sh` | Created — AC-006 |
| `tests/smoke/run-tests.sh` | Updated — registered 4 new scenarios |
| `specs/features/FEAT-0008-git-identity-bootstrap.yaml` | Updated — status: implemented |
| `specs.config.yaml` | Updated — FEAT-0008 status: implemented |
| `.ai/CONTEXT.md` | Updated — FEAT-0008 in active work and recent changes |
| `.ai/architecture/ARCHITECTURE.md` | Updated — component diagram, smoke test list, revision history v1.7.0 |
| `.ai/architecture/PATTERNS.md` | Updated — --non-interactive in arg parsing; new §18 git identity pattern |
| `.ai/memory/TRACEABILITY.md` | Updated — TR-008 status: Implemented |
| `specs/api/_template.openapi.yaml` | Deleted — manually removed by user (unused template) |

### Decisions Made
- No ADRs created (no architectural decisions; all patterns follow established conventions)

### Traceability
- Trace IDs updated: TR-008
- Specs referenced: specs/features/FEAT-0008-git-identity-bootstrap.yaml
- Branch: FEAT-0008-git-identity-bootstrap | Commit: c302b57

### Open Items
- [ ] FEAT-0008 PR needs to be created and merged
- [ ] FEAT-0009 through FEAT-0014 remain as draft specs (v1.1 and v1.2 backlog)
