# AI Context Directory

This directory contains structured documentation optimized for AI assistants (Claude, GPT, Copilot, etc.) to understand and work with this codebase effectively.

## Directory Structure

```
.ai/
├── README.md              # This file
├── CONTEXT.md             # Master context file (start here)
├── config.yaml            # AI behavior configuration
│
├── specs/                 # Product specifications
│   ├── SPEC.md           # Current product specification
│   └── features/         # Feature-specific specs
│
├── architecture/          # Technical architecture
│   ├── ARCHITECTURE.md   # System architecture overview
│   ├── PATTERNS.md       # Code patterns and conventions
│   └── diagrams/         # Architecture diagrams (Mermaid, etc.)
│
├── decisions/            # Architecture Decision Records (ADRs)
│   └── template.md       # ADR template
│
└── prompts/              # Reusable prompt templates
    └── templates/        # Common prompt patterns
```

## How AI Tools Use This

### Claude Code
Claude Code automatically reads `.claude/CLAUDE.md` which references this directory. The `CONTEXT.md` file serves as the entry point.

### Other AI Tools
Point your AI assistant to `.ai/CONTEXT.md` for full project context, or specific files as needed:
- **Product questions** → `specs/SPEC.md`
- **Technical questions** → `architecture/ARCHITECTURE.md`
- **Why decisions** → `decisions/`

## Maintenance

1. **Keep CONTEXT.md updated** - It's the master index
2. **Version specs** - Update version numbers when specs change
3. **Document decisions** - Create ADRs for significant choices
4. **Review quarterly** - Ensure docs match reality
