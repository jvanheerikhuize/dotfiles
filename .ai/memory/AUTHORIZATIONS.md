# AI Authorization Registry

The AI's persistent authorization policy for this project. Contains two layers:

1. **Base Rules** (user-configured) — static policies set by the project owner. Edit these directly.
2. **Learned Authorizations** (AI-accumulated) — generalizations the AI has learned from specific approvals or denials during sessions.

> **AI Assistants**: Read this file at the start of every session. Follow the [Decision Protocol](#decision-protocol) before taking any [Gated Action](#gated-action-categories). When you learn a new authorization, append it to the [Learned Authorizations](#learned-authorizations) table immediately — do not defer.

---

## Decision Protocol

Before taking any Gated Action, run through this decision tree in order:

```
1. Is the action explicitly listed in Base Rules → NEVER ALLOWED?
   YES → Refuse. Explain why. Do not ask for override.
   NO  → continue

2. Is the action explicitly listed in Base Rules → ALWAYS ALLOWED?
   YES → Proceed without asking.
   NO  → continue

3. Is there a Learned Authorization that covers this action?
   YES, status=granted → Proceed. Note the AUTH-NNN you relied on.
   YES, status=denied  → Refuse. Cite the AUTH-NNN.
   NO  → continue

4. Ask the user for permission for this specific action.
   DENIED → Record as AUTH-NNN with scope=specific, status=denied. Stop.
   GRANTED → continue

5. Ask the generalization follow-up question:
   "You've approved [specific action]. Should I remember this as a general rule
    for [action category], or was this a one-time exception?"
   Options: "General rule" | "One-time only" | "Only for [narrower scope the user specifies]"

6. Record the result as AUTH-NNN in Learned Authorizations with the appropriate scope.
   Proceed.
```

**Important**:
- Steps 1 and 2 are absolute — they cannot be overridden by learned authorizations or user requests in-session.
- Step 5 must always be asked after a specific grant, even if it feels obvious. This is what builds the persistent policy.
- If a user says "just do it" without answering step 5, record scope=`session` (not persisted across sessions).

---

## Gated Action Categories

These are the action types that always require a decision protocol check:

| Category | Examples |
|----------|---------|
| `delete-files` | Remove individual files |
| `delete-directories` | Remove directories (any depth) |
| `overwrite-uncommitted` | Overwrite files with uncommitted local changes |
| `git-commit` | Create any git commit |
| `git-push` | Push to any remote branch |
| `git-force` | Force push, reset --hard, rebase with overwrite |
| `git-branch-delete` | Delete a local or remote branch |
| `dependency-add` | Add a new package/library dependency |
| `dependency-remove` | Remove a package/library dependency |
| `config-modify` | Edit configuration files (CI/CD, env, build) |
| `security-sensitive` | Touch auth, crypto, secrets handling, or permissions code |
| `external-call` | Make API calls, send webhooks, post to external services |
| `test-bypass` | Skip, suppress, or delete tests to make something pass |

---

## Base Rules

> **Instructions for project owners**: Fill in the sections below. These rules are absolute and cannot be overridden by learned authorizations or in-session user requests.

### Never Allowed
<!-- Actions the AI must always refuse, regardless of user requests -->
<!-- Format: - [category]: [description of what is banned] -->

- `git-force`: Never force push to `main` or `master`
- `test-bypass`: Never delete, skip, or suppress tests to make a build pass
- `security-sensitive`: Never commit credentials, tokens, or secrets to any file
- <!-- Add more never-allowed rules here -->

### Always Allowed (No Confirmation Needed)
<!-- Actions the AI may take freely without asking -->
<!-- Format: - [category]: [description of what is always permitted] -->

- `delete-files`: Delete files inside `.ai/memory/` and `.ai/decisions/` (AI-maintained files)
- <!-- Add more always-allowed rules here -->

### Always Ask (Regardless of Learned Authorizations)
<!-- Actions that must always be confirmed, even if a general learned authorization exists -->
<!-- Format: - [category]: [description of when to always ask] -->

- `git-push`: Always confirm before pushing to any remote
- `git-force`: Always confirm before any force operation (applies even if not in Never Allowed above)
- `external-call`: Always confirm before contacting external services
- <!-- Add more always-ask rules here -->

---

## Learned Authorizations

Authorizations the AI has learned from specific user approvals or denials. Appended automatically by the AI during sessions.

> **AI Assistants**:
> - Append new rows; never edit or delete existing rows
> - If a rule is superseded, add a new row with `status=supersedes AUTH-NNN` in the Notes column
> - Use the next sequential AUTH-NNN from the table below

| ID | Category | Scope | Status | Date | Session | Origin | Notes |
|----|----------|-------|--------|------|---------|--------|-------|

---

**Next AUTH number: 001**
