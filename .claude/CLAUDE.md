# AI Coding Assistant Instructions

> This document provides context and guidelines for AI coding assistants when working with this repository.

## Quick Start

**Before doing anything, read these files for context:**
1. `.ai/DIRECTIVES.md` - Mandatory rules (read first — these override all defaults)
2. `.ai/CONTEXT.md` - Project overview and current state
3. `.ai/architecture/PATTERNS.md` - Code patterns to follow
4. `.ai/config.yaml` - AI behavior preferences

**At the start of every session, also read:**
- `.ai/memory/SESSION_LOG.md` - Most recent entry for open items and recent state
- `.ai/memory/LEARNINGS.md` - Accumulated gotchas and project knowledge
- `.ai/memory/TRACEABILITY.md` - Check if related work exists before starting

## Project Overview

This is a **bash provisioning system** for Ubuntu 22.04 that installs packages and applies dotfiles via symlinks. It is the **Stage 2** of a two-stage Ubuntu setup:
- Stage 1: Unattended OS install via `Autoinstall.yaml`
- Stage 2: This repo — tools, packages, and dotfiles applied by `./install.sh`

Features are implemented based on formal specifications in `specs/features/`. All changes require an approved spec before implementation.

### Key Principles
- **Spec-Driven**: All features start with a formal YAML spec — no ad-hoc additions
- **Idempotent**: Every operation is safe to run twice on the same machine
- **Bash-only**: No Python, Node, or Ruby for provisioning code — bash + python3 for YAML parsing only
- **Fail loudly**: Non-zero exits with clear errors; never silently skip failures
- **Minimal sudo**: Elevated only for individual package install commands

## Repository Structure

```
├── install.sh                  # Main entrypoint (arg parsing, orchestration)
├── profiles/                   # Declarative package manifests (YAML)
│   ├── base.yaml              # Core CLI tools (always applied)
│   ├── desktop.yaml           # GUI apps (extends base)
│   ├── server.yaml            # Headless tooling (extends base)
│   └── dev.yaml               # Full dev environment (extends desktop)
├── dotfiles/                   # Config files symlinked into $HOME
│   ├── .bashrc
│   ├── .bash_aliases
│   ├── .bash_profile
│   └── .gitconfig
├── src/                        # Provisioning helpers
│   ├── utils.sh               # Logging, guards, YAML helpers
│   ├── validate.sh            # Profile YAML validation (FEAT-0006)
│   ├── packages.sh            # apt/snap/flatpak/deb/custom installers
│   └── dotfiles.sh            # Symlink management
├── tests/
│   └── smoke/                 # Docker-based smoke tests (FEAT-0004)
│       ├── Dockerfile
│       ├── run-tests.sh
│       ├── helpers.sh
│       └── tests/
├── specs/                      # Implementation specifications
│   ├── features/              # Feature specs (YAML, FEAT-XXXX-*.yaml)
│   └── schemas/               # JSON schemas for spec validation
├── scripts/                    # Template tooling only (spec ingestion)
├── .github/
│   └── workflows/
│       └── smoke-tests.yml    # CI: runs smoke tests on every PR
├── .ai/                        # AI context and documentation
│   ├── DIRECTIVES.md          # Mandatory AI rules (read first)
│   ├── CONTEXT.md             # Master context
│   ├── config.yaml            # AI behavior configuration
│   ├── architecture/          # ARCHITECTURE.md, PATTERNS.md
│   ├── decisions/             # ADRs (README, INDEX, template)
│   ├── memory/                # SESSION_LOG, LEARNINGS, TRACEABILITY, AUTHORIZATIONS
│   └── specs/                 # SPEC.md (product spec)
├── docs/
│   └── runbooks/              # Operational runbooks
│       └── template-sync.md   # How to sync future template updates
└── specs.config.yaml          # Central spec registry
```

## Context Hierarchy

When you need information, follow this hierarchy:

| Question | Where to Look |
|----------|---------------|
| What rules must I follow? | `.ai/DIRECTIVES.md` |
| What does this project do? | `.ai/CONTEXT.md` → `.ai/specs/SPEC.md` |
| How is it built? | `.ai/architecture/ARCHITECTURE.md` |
| What patterns should I follow? | `.ai/architecture/PATTERNS.md` |
| Why was X decided? | `.ai/decisions/INDEX.md` → `ADR-NNN-*.md` |
| What have I learned before? | `.ai/memory/LEARNINGS.md` |
| What work has been done? | `.ai/memory/TRACEABILITY.md` |
| What feature should I implement? | `specs/features/*.yaml` |
| What's pending/approved? | `specs.config.yaml` |

## Spec-Based Development Workflow

1. **Specification First**: All features start with a formal spec in `specs/features/`
2. **Review & Approval**: Specs go through review before implementation (status: `approved`)
3. **Branch**: Create a feature branch `FEAT-XXXX-short-title`
4. **Implement**: Follow patterns, implement all acceptance criteria, update `.ai` docs
5. **PR**: Create a PR for human review

## When Implementing Specs

### DO:
- Read `.ai/DIRECTIVES.md` and `.ai/CONTEXT.md` first
- Read the full spec before writing a single line of code
- Follow patterns in `.ai/architecture/PATTERNS.md`
- Implement ALL acceptance criteria
- Update `.ai/CONTEXT.md`, `ARCHITECTURE.md`, and `PATTERNS.md` before committing
- Update spec status to `implemented` in both the YAML and `specs.config.yaml`

### DON'T:
- Add features not in the spec
- Hardcode package lists in shell scripts — use `profiles/*.yaml`
- Commit directly to `main` — always use a feature branch
- Skip or suppress tests
- Place provisioning code in `scripts/` (template tooling only)

## Spec File Format

### Feature Specs (`specs/features/FEAT-XXXX-*.yaml`)
- Follow the schema in `specs/schemas/feature-spec.schema.json`
- Must include: `metadata`, `description`, `acceptance_criteria`
- Use Gherkin-style (Given/When/Then) for acceptance criteria
- Status flow: `draft` → `review` → `approved` → `implemented`

## Code Conventions

Read `.ai/architecture/PATTERNS.md` for full details. Key principles:

1. `#!/usr/bin/env bash` + `set -euo pipefail` in every script
2. All output via `log_info` / `log_warn` / `log_error` / `log_dry_run` from `src/utils.sh`
3. Named functions with `local` variables — no inline logic, no global side effects
4. Check state before acting — every operation must be idempotent
5. `if [[ cond ]]; then cmd; fi` — never `[[ cond ]] && cmd` under `set -e`

## Testing Requirements

For each acceptance criterion in a spec:
1. Create a smoke test in `tests/smoke/tests/`
2. Register the scenario in `tests/smoke/run-tests.sh`
3. Cover: happy path, error cases, and idempotency (second run safe)

## Commit Messages

Follow conventional commits format:
```
feat(FEAT-XXXX): Brief description

- Implemented AC-001, AC-002, AC-003
- Added smoke tests for all criteria

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

## Working with specs.config.yaml

The central configuration tracks all specs:
- Only implement specs with `status: approved`
- Update `status` to `implemented` after completion
- Check `priority` to determine implementation order

## Important Files to Read

Before implementing any spec, read:
1. `.ai/DIRECTIVES.md` - Mandatory rules
2. `.ai/CONTEXT.md` - Current project state
3. `.ai/memory/SESSION_LOG.md` - Most recent session for open items
4. `.ai/memory/LEARNINGS.md` - Known gotchas
5. `.ai/architecture/PATTERNS.md` - Code patterns
6. The spec file itself (thoroughly)
7. `specs.config.yaml` for context
8. Related existing code
9. Existing tests for patterns
