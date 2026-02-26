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

<!-- Entries below, newest at top. Use the template above. -->
