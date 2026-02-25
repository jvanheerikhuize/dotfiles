# AI Memory System

This directory is the AI's persistent memory for this project. It serves two purposes:

1. **Persistent memory** — knowledge accumulated across sessions that would otherwise be lost
2. **End-to-end traceability** — a complete audit trail from user request to deployed code

> **AI Assistants**: You are required to read and update these files as specified. See [DIRECTIVES.md](../DIRECTIVES.md) §3b for the mandatory rules.

---

## Files

| File | Purpose | Read | Write |
|------|---------|------|-------|
| [AUTHORIZATIONS.md](AUTHORIZATIONS.md) | Base rules + learned action permissions | Before every gated action | When a new authorization is learned |
| [SESSION_LOG.md](SESSION_LOG.md) | Chronological log of every AI session | Start of session | End of session |
| [LEARNINGS.md](LEARNINGS.md) | Accumulated project knowledge and gotchas | Start of session | When something non-obvious is discovered |
| [TRACEABILITY.md](TRACEABILITY.md) | Matrix linking requests → specs → ADRs → code → PRs | When implementing | When any link in the chain is established |

---

## When to Update Each File

### SESSION_LOG.md
- **Read**: At the start of every session to understand what was done previously and any open items left behind
- **Write**: At the end of every session with a structured summary (see template inside the file)

### LEARNINGS.md
- **Read**: Before touching any existing code
- **Write**: When you discover something non-obvious — a gotcha, an undocumented constraint, a pattern that diverges from what you'd expect, or domain knowledge that took investigation to uncover

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
