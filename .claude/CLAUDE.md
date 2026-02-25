# AI Coding Assistant Instructions

> This document provides context and guidelines for AI coding assistants when working with this repository.
> Works with: Claude Code, GitHub Copilot, Cursor, Aider, Cody, Continue, and other AI tools.

## Quick Start

**Before doing anything, read these files for context:**
1. `.ai/CONTEXT.md` - Project overview and current state
2. `.ai/architecture/PATTERNS.md` - Code patterns to follow
3. `.ai/config.yaml` - AI behavior preferences

## Project Overview

This is a **language-agnostic, platform-agnostic template repository** designed for **spec-based development** with AI assistant integration. Features are implemented based on formal specifications rather than ad-hoc requests.

### Key Principles
- **AI-Agnostic**: Works with any AI coding assistant
- **Platform-Agnostic**: Supports Windows, macOS, and Linux
- **Language-Agnostic**: Adaptable to any programming language
- **Spec-Driven**: Formal specifications before implementation

## Repository Structure

```
├── .ai/                      # AI context and documentation
│   ├── CONTEXT.md           # Master context file (START HERE)
│   ├── config.yaml          # AI behavior configuration
│   ├── specs/               # Product specifications
│   │   └── SPEC.md         # Product specification template
│   ├── architecture/        # Technical documentation
│   │   ├── ARCHITECTURE.md # System architecture
│   │   └── PATTERNS.md     # Code patterns and conventions
│   ├── decisions/           # Architecture Decision Records
│   └── prompts/             # Reusable prompt templates
│
├── specs/                    # Implementation specifications
│   ├── features/            # Feature specs (YAML)
│   ├── api/                 # API specs (OpenAPI)
│   └── schemas/             # JSON schemas for validation
│
├── scripts/                  # Automation scripts (cross-platform)
│   ├── ingest-spec.sh       # Bash/Unix script
│   └── Invoke-SpecIngestion.ps1  # PowerShell script
│
├── .github/
│   ├── workflows/           # CI/CD workflows
│   │   ├── spec-ingestion.yml
│   │   ├── validate-specs.yml
│   │   └── notify-integrations.yml
│   └── ISSUE_TEMPLATE/      # Issue templates
│
├── docs/
│   ├── spec-based-development.md
│   ├── integrations.md
│   └── runbooks/            # Operational procedures
│
├── specs.config.yaml        # Central spec registry & config
├── .claude/                 # Claude Code configuration
└── .cursorrules             # Cursor IDE rules (optional)
```

## Context Hierarchy

When you need information, follow this hierarchy:

| Question | Where to Look |
|----------|---------------|
| What does this project do? | `.ai/CONTEXT.md` → `.ai/specs/SPEC.md` |
| How is it built? | `.ai/architecture/ARCHITECTURE.md` |
| What patterns should I follow? | `.ai/architecture/PATTERNS.md` |
| Why was X decided? | `.ai/decisions/` |
| What feature should I implement? | `specs/features/*.yaml` |
| What's the API contract? | `specs/api/*.yaml` |
| What's pending/approved? | `specs.config.yaml` |

## Spec-Based Development Workflow

1. **Specification First**: All features start with a formal spec in `specs/features/`
2. **Review & Approval**: Specs go through review before implementation
3. **AI-Assisted Implementation**: Approved specs trigger AI implementation
4. **PR Creation**: Implementation creates a PR for human review

## When Implementing Specs

### DO:
- Read `.ai/CONTEXT.md` first for project context
- Read and understand the entire spec before coding
- Follow patterns in `.ai/architecture/PATTERNS.md`
- Implement ALL acceptance criteria
- Create appropriate tests for each acceptance criterion
- Keep implementations minimal and focused on the spec
- Document any decisions made when spec is ambiguous

### DON'T:
- Add features not in the spec
- Over-engineer solutions
- Skip acceptance criteria
- Ignore existing code patterns
- Make breaking changes without spec approval
- Modify security-related code without explicit request

## Spec File Formats

### Feature Specs (`specs/features/*.yaml`)
- Follow the schema in `specs/schemas/feature-spec.schema.json`
- Must include: metadata, description, acceptance_criteria
- Use Gherkin-style (Given/When/Then) for acceptance criteria

### API Specs (`specs/api/*.yaml`)
- Follow OpenAPI 3.1 specification
- Include complete request/response schemas
- Document error responses

## Code Conventions

Read `.ai/architecture/PATTERNS.md` for detailed patterns. Key principles:

1. **Match existing style** - If code exists, match its patterns
2. **Standard tooling** - Use language-standard formatters/linters
3. **Clear naming** - Self-documenting names over comments
4. **Test coverage** - Tests for all acceptance criteria
5. **Minimal changes** - Only change what the spec requires

## Testing Requirements

For each acceptance criterion in a spec:
1. Create at least one test case
2. Cover the happy path (Given/When/Then)
3. Cover edge cases if specified
4. Cover error cases if specified

## Commit Messages

Follow conventional commits format:
```
feat(FEAT-0001): Brief description

- Implemented acceptance criteria AC-001, AC-002
- Added tests for all criteria

Co-Authored-By: [AI Assistant Name] <noreply@example.com>
```

## Working with specs.config.yaml

The central configuration tracks all specs:
- Check `specifications` array for pending work
- Respect `status` field (only implement `approved` specs)
- Update status to `implemented` after completion

## Important Files to Read

Before implementing any spec, read:
1. `.ai/CONTEXT.md` - Current project state
2. `.ai/architecture/PATTERNS.md` - Code patterns
3. The spec file itself (thoroughly)
4. `specs.config.yaml` for context
5. Related existing code
6. Existing tests for patterns

## AI Configuration

Check `.ai/config.yaml` for:
- Code generation preferences
- Testing requirements
- Behavior settings
- Domain-specific terminology
- AI tool integration settings

## Cross-Platform Considerations

When generating code or commands:
- Provide both Bash and PowerShell alternatives where applicable
- Use cross-platform path separators or abstract them
- Consider Windows, macOS, and Linux compatibility
- Reference appropriate scripts based on platform context
