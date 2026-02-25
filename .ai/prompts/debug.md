# Debug Prompt Template

> Use this prompt when asking AI to help debug an issue.

---

## Prompt

```
I need help debugging an issue.

## Project Context
- Architecture: `.ai/architecture/ARCHITECTURE.md`
- Known issues: Check `.ai/CONTEXT.md` section 2

## Problem Description
**What should happen:**
[Expected behavior]

**What actually happens:**
[Actual behavior]

**Error message (if any):**
```
[Paste error message/stack trace]
```

## Reproduction Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Environment
- Environment: [development/staging/production]
- Version/commit: [git commit or version]
- Relevant config: [any relevant configuration]

## What I've Tried
- [Attempt 1 and result]
- [Attempt 2 and result]

## Relevant Code
[Paste relevant code snippets or reference files]

## Request
Please:
1. Identify the likely root cause
2. Explain why this is happening
3. Suggest a fix with code
4. Recommend any preventive measures

## Data Flow
Help me trace the data flow:
- Entry point: [where does the request/data enter]
- Expected path: [how should it flow]
- Where it fails: [best guess]
```

---

## Usage Notes

1. **Include error messages** - Full stack traces are invaluable
2. **Show what you've tried** - Avoids suggesting already-failed approaches
3. **Provide reproduction steps** - Helps verify the fix works
4. **Include environment details** - Issues often depend on environment
