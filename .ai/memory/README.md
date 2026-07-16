# AI Memory System

This directory holds the project's persistent AI records: learned action permissions
and an end-to-end audit trail from user request to deployed code.

> **AI Assistants**: You are required to read and update these files as specified. See [DIRECTIVES.md](../DIRECTIVES.md) §3b for the mandatory rules.

Session logs and learnings files used to live here too. They were retired: AI-assistant
session context is handled by the assistant's own memory (e.g. Claude Code's built-in
auto memory), and reusable code gotchas belong in
[architecture/PATTERNS.md](../architecture/PATTERNS.md), which is the single source of
truth for patterns and anti-patterns. Do not recreate `SESSION_LOG.md` or `LEARNINGS.md`.

---

## Files

| File | Purpose | Read | Write |
|------|---------|------|-------|
| [AUTHORIZATIONS.md](AUTHORIZATIONS.md) | Base rules + learned action permissions | Before every gated action | When a new authorization is learned |
| [TRACEABILITY.md](TRACEABILITY.md) | Matrix linking requests → specs → ADRs → code → PRs | When implementing | When any link in the chain is established |

---

## When to Update Each File

### AUTHORIZATIONS.md
- **Read**: Before any gated action (see [DIRECTIVES.md](../DIRECTIVES.md) §3c for the categories and Decision Protocol)
- **Write**: Immediately after the user grants or denies a new permission (new AUTH-NNN row)

### TRACEABILITY.md
- **Read**: When starting work on a request, to check if related work exists
- **Write**: When any traceability link is established:
  - A user request is received
  - A spec is created or referenced
  - An ADR is created
  - Code is changed (files + commit/PR reference)
  - A PR is opened or merged

---

## Traceability Chain

Every unit of work should be traceable end-to-end:

```
User Request
    │
    ▼
Spec (specs/features/*.yaml)
    │
    ▼
ADR (if architectural decision made)
    │
    ▼
Implementation (files changed)
    │
    ▼
PR / Commit
    │
    ▼
TRACEABILITY.md row (the permanent record)
```

A row in TRACEABILITY.md is the single source of truth for this chain.
