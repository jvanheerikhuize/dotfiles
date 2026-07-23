# Contributing Guide

This repository uses **Specification-Driven Development (SDD)** — all changes to provisioning behaviour start with a formal spec before any code is written.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Writing Specifications](#writing-specifications)
- [Code Standards](#code-standards)
- [Pull Request Process](#pull-request-process)

## Getting Started

### Prerequisites

- Ubuntu 22.04+
- bash 5.x
- git
- python3 (for YAML parsing — present by default on Ubuntu 22.04)
- Docker (optional, for smoke testing)

### Setup

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh --profile base
```

## Development Workflow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Write Spec │ ──▶ │   Review    │ ──▶ │  Implement  │ ──▶ │   Merge     │
│   (Draft)   │     │  (Approve)  │     │   (Code)    │     │    (PR)     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### 1. Propose a Change

Before writing any shell scripts or modifying profile YAMLs, create a specification:

1. Copy `specs/features/_template.yaml` to `specs/features/FEAT-XXXX-your-feature.yaml`
2. Fill out all required sections (metadata, description, acceptance_criteria)
3. Submit a PR with only the spec for review

### 2. Spec Review

- Acceptance criteria must be clear, specific, and testable
- Technical requirements must be achievable in bash on Ubuntu 22.04
- Once approved, `status` changes to `approved` in both the spec file and `specs.config.yaml`

### 3. Implementation

Create a feature branch and implement all acceptance criteria:

```bash
git checkout -b spec/FEAT-XXXX
# implement the spec
# write/update tests
git push -u origin spec/FEAT-XXXX
# open PR
```

### 4. Code Review & Merge

- All acceptance criteria verified
- Tests passing (smoke test in Docker at minimum)
- Code follows patterns in `.ai/architecture/PATTERNS.md`
- Spec status updated to `implemented` after merge

## Writing Specifications

Location: `specs/features/FEAT-XXXX-description.yaml`

```yaml
metadata:
  id: "FEAT-0002"
  title: "Multi-Type Package Support"
  version: "1.0.0"
  status: "draft"         # draft → review → approved → implemented
  priority: "high"        # critical | high | medium | low

description:
  summary: "One or two sentence description."
  problem_statement: "What problem does this solve?"
  proposed_solution: "How does it solve the problem?"

acceptance_criteria:
  - id: "AC-001"
    given: "A profile YAML with a snap package listed"
    when: "./install.sh --profile base is run"
    then: "The snap package is installed via snap install"
```

### Acceptance Criteria Guidelines

Write concrete, testable criteria. Good:

```yaml
- id: "AC-001"
  given: "A clean Ubuntu 22.04 system with profiles/base.yaml listing 'curl' under apt"
  when: "./install.sh --profile base is run"
  then: "curl is installed and 'curl --version' exits 0"
```

Bad (too vague):

```yaml
- id: "AC-001"
  given: "A machine"
  when: "Script runs"
  then: "It works"
```

## Code Standards

All code must follow `.ai/architecture/PATTERNS.md`. Key rules:

1. **`set -euo pipefail`** in every script — no exceptions
2. **Named functions** — no inline logic at the script body level
3. **`local` variables** — never mutate globals inside functions
4. **Idempotency** — check state before acting; safe to run twice
5. **`log_info` / `log_warn` / `log_error`** — never bare `echo`
6. **Package lists in YAML** — never hardcode packages in shell scripts

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(FEAT-0002): Add snap and flatpak package type support

- Implement install_snap_package() in src/packages.sh
- Implement install_flatpak_package() in src/packages.sh
- Add snap/flatpak lists to profile YAML schema
- Tests: AC-001 through AC-004

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`

### Branch Naming

```
spec/FEAT-0002        # Feature implementation
fix/dotfile-symlink   # Bug fixes
docs/update-readme    # Documentation only
```

## Pull Request Process

### For Specifications (spec PR)

1. Create the spec YAML file
2. Open PR with title: `spec(FEAT-XXXX): Your Feature Title`
3. Request review — discussion happens on the PR

### For Implementations (code PR)

1. Reference the spec: `Implements: specs/features/FEAT-XXXX-...yaml`
2. Include acceptance criteria checklist
3. Confirm smoke test passes

PR description template:

```markdown
## Specification
Implements: `specs/features/FEAT-XXXX-description.yaml`

## Acceptance Criteria
- [ ] AC-001: Description
- [ ] AC-002: Description

## Testing
- [ ] Smoke test: `docker run ... ./install.sh --profile base` passes
- [ ] Idempotency: second run exits 0

## Checklist
- [ ] Follows patterns in .ai/architecture/PATTERNS.md
- [ ] set -euo pipefail in all modified scripts
- [ ] No hardcoded package lists in shell scripts
```
