# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records — lightweight documents that capture **why** significant decisions were made, not just what was done.

> **AI Assistants**: You are required to create an ADR here whenever you make a decision that falls under the [trigger conditions](#when-to-create-an-adr) below. Do not skip this step.

---

## When to Create an ADR

Create an ADR for any decision that is:

- **Architectural** — affects the overall structure, patterns, or design of the system
- **Hard to reverse** — would be costly or disruptive to undo later
- **Non-obvious** — future contributors (human or AI) would reasonably ask "why did we do it this way?"
- **Cross-cutting** — affects more than one module, layer, or team
- **Technology choices** — introducing or replacing a dependency, tool, or framework
- **Security-relevant** — changes to auth, secrets handling, data access, or trust boundaries

You do **not** need an ADR for:
- Routine bug fixes
- Style or formatting changes
- Obvious, easily-reversed implementation details

---

## How to Create an ADR

1. Copy `template.md` and name it `ADR-NNN-short-title.md` (e.g., `ADR-002-use-postgres.md`)
2. Use the next sequential number from [INDEX.md](INDEX.md)
3. Fill in all sections — leave none blank
4. Set status to `Proposed` initially; update to `Accepted` once the decision is confirmed
5. Add a row to [INDEX.md](INDEX.md)

### Naming Convention

```
ADR-NNN-kebab-case-title.md

Examples:
  ADR-001-add-ai-directives-system.md
  ADR-002-use-postgres-over-mysql.md
  ADR-003-deprecate-rest-in-favour-of-graphql.md
```

---

## ADR Lifecycle

```
Proposed → Accepted → (Deprecated | Superseded by ADR-NNN)
```

| Status | Meaning |
|--------|---------|
| Proposed | Decision is under consideration |
| Accepted | Decision has been made and is active |
| Deprecated | Decision is no longer relevant but kept for history |
| Superseded | Replaced by a newer ADR (link to it) |

---

## Files in This Directory

| File | Purpose |
|------|---------|
| [README.md](README.md) | This guide |
| [INDEX.md](INDEX.md) | Living index of all ADRs |
| [template.md](template.md) | Blank template to copy |
| `ADR-NNN-*.md` | Individual decision records |
