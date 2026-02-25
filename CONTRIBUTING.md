# Contributing Guide

Thank you for your interest in contributing! This repository follows a **spec-based development** workflow where features are defined through formal specifications before implementation.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Writing Specifications](#writing-specifications)
- [Code Standards](#code-standards)
- [Pull Request Process](#pull-request-process)

## Getting Started

### Prerequisites

- Git
- Your language-specific toolchain
- [yq](https://github.com/mikefarah/yq) (for YAML processing)
- [Claude Code CLI](https://github.com/anthropics/claude-code) (optional, for local spec processing)

### Setup

1. Fork and clone the repository
2. Install dependencies for your language/framework
3. Review the existing specifications in `specs/`

## Development Workflow

This project uses **Specification-Driven Development (SDD)**:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Write Spec │ ──▶ │   Review    │ ──▶ │  Implement  │ ──▶ │   Merge     │
│   (Draft)   │     │  (Approve)  │     │   (Code)    │     │    (PR)     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### 1. Propose a Feature

Before writing code, create a specification:

1. Copy `specs/features/_template.yaml` to `specs/features/FEAT-XXXX-your-feature.yaml`
2. Fill out all required sections
3. Submit a PR with your spec for review

### 2. Spec Review

- Specs are reviewed by the architecture team
- Acceptance criteria must be clear and testable
- Technical requirements must be feasible
- Once approved, status changes to `approved`

### 3. Implementation

Implementation can happen in two ways:

**Automated (via Claude Code):**
- Approved specs in `specs.config.yaml` with `auto_implement: true` are processed automatically
- Creates a feature branch and PR

**Manual:**
- Create a feature branch: `git checkout -b spec/FEAT-XXXX`
- Implement all acceptance criteria
- Write tests for each criterion
- Submit PR referencing the spec

### 4. Code Review & Merge

- All acceptance criteria must pass
- Tests must pass
- Code review approval required
- Spec status updated to `implemented`

## Writing Specifications

### Feature Specs

Location: `specs/features/`

```yaml
metadata:
  id: "FEAT-0001"           # Unique identifier
  title: "Feature Name"      # Short title
  version: "1.0.0"          # Spec version
  status: "draft"           # draft → review → approved → implemented
  priority: "medium"        # critical | high | medium | low

description:
  summary: "One-line description"
  problem_statement: "What problem does this solve?"
  proposed_solution: "How does it solve the problem?"

acceptance_criteria:
  - id: "AC-001"
    given: "Precondition"
    when: "Action"
    then: "Expected result"
```

### Acceptance Criteria Guidelines

Write clear, testable criteria using Gherkin format:

**Good:**
```yaml
- id: "AC-001"
  given: "A user is logged in with valid credentials"
  when: "They click the 'Export' button"
  then: "A CSV file downloads containing their data"
```

**Bad:**
```yaml
- id: "AC-001"
  given: "User exists"
  when: "They do export"
  then: "It works"
```

### API Specs

Location: `specs/api/`

Use OpenAPI 3.1 format. See `specs/api/_template.openapi.yaml` for reference.

## Code Standards

### General Principles

1. **Follow existing patterns** - Match the codebase style
2. **Keep it simple** - Implement what the spec requires, nothing more
3. **Test everything** - Each acceptance criterion needs tests
4. **Document decisions** - If spec is ambiguous, document your interpretation

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(FEAT-0001): Add user export functionality

- Implement CSV export for user data
- Add tests for AC-001, AC-002, AC-003

Closes #123
```

Types:
- `feat`: New feature (from spec)
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions/changes
- `refactor`: Code refactoring
- `chore`: Maintenance tasks

### Branch Naming

```
spec/FEAT-0001           # Feature implementation
spec/API-0001            # API implementation
fix/issue-123            # Bug fixes
docs/update-readme       # Documentation
```

## Pull Request Process

### For Specifications

1. Create spec file following the template
2. Validate against schema: `scripts/ingest-spec.sh --validate specs/features/your-spec.yaml`
3. Open PR with title: `spec(FEAT-XXXX): Your Feature Title`
4. Request review from architecture team
5. Address feedback and iterate

### For Implementation

1. Reference the spec in PR description
2. Include checklist of acceptance criteria
3. Ensure all tests pass
4. Request review from code owners

### PR Template

```markdown
## Specification
Implements: `specs/features/FEAT-XXXX.yaml`

## Acceptance Criteria
- [ ] AC-001: Description
- [ ] AC-002: Description

## Testing
- [ ] Unit tests added
- [ ] Integration tests added
- [ ] All tests passing

## Checklist
- [ ] Code follows project conventions
- [ ] Self-review completed
- [ ] Documentation updated (if needed)
```

## Questions?

- Check existing specs for examples
- Review closed PRs for patterns
- Open a discussion for clarification
