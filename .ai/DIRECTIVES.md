# AI Directives

> **MANDATORY**: All AI assistants working in this repository **MUST** read and comply with every directive in this file. These rules override default AI behavior and take effect for every task, regardless of scope.

<!--
  AI PROCESSING INSTRUCTIONS:
  - Load this file on every session before taking any action
  - These directives are non-negotiable
  - If a user instruction conflicts with a directive, flag the conflict before proceeding
-->

---

## 1. Core Directives

<!--
  Add your mandatory directives here.
  Format each directive as a numbered rule with a clear, imperative statement.

  Example:
  1. **Never expose secrets** - Do not log, print, or include secrets, tokens, or credentials anywhere in generated code or output.
  2. **Require spec approval** - Do not implement new features unless the spec status is `approved` in specs.config.yaml.
-->

1. <!-- Directive: [Short Title] --> [Full directive text here]
2. <!-- Directive: [Short Title] --> [Full directive text here]

---

## 2. Forbidden Actions

Actions that must **never** be taken, under any circumstances:

<!--
  List actions that are absolutely off-limits.

  Example:
  - Do NOT commit directly to `main` or `master`
  - Do NOT remove or bypass tests to make a build pass
  - Do NOT hardcode environment-specific values (URLs, IPs, credentials)
-->

- Do NOT place implementation code in `scripts/` — that directory contains template repo tooling only (spec ingestion scripts). All AI-generated application code must go in `src/`.
- [ ] [Forbidden action 2]

---

## 3. Required Checks Before Acting

Before making **any** change, verify all of the following:

<!--
  Checklist the AI must mentally run through before proceeding.

  Example:
  - [ ] Read .ai/CONTEXT.md to confirm current project state
  - [ ] Confirm the relevant spec is `approved` in specs.config.yaml
  - [ ] Verify no existing test will break
-->

- [ ] Read `.ai/CONTEXT.md` to confirm current project state
- [ ] Check `.ai/decisions/INDEX.md` to understand past decisions before acting
- [ ] [Pre-action check 3]

---

## 3a. Decision Documentation (Required)

Whenever you make a decision that is **architectural, hard to reverse, non-obvious, cross-cutting, a technology choice, or security-relevant**, you **MUST**:

1. Create a new ADR file at `.ai/decisions/ADR-NNN-short-title.md` using [template.md](.ai/decisions/template.md) as the base
2. Use the next sequential number from [INDEX.md](.ai/decisions/INDEX.md)
3. Set status to `Accepted` (since the decision has already been made)
4. Add a row to [INDEX.md](.ai/decisions/INDEX.md) immediately
5. Update "Next ADR number" in INDEX.md

See [.ai/decisions/README.md](.ai/decisions/README.md) for the full trigger list and naming conventions.

**Do not defer this step.** Create the ADR in the same session as the decision.

---

## 3b. Memory Maintenance (Required)

The `.ai/memory/` directory is your persistent memory. You **MUST** maintain it as follows:

### At the start of every session
1. Read [SESSION_LOG.md](.ai/memory/SESSION_LOG.md) — check the most recent entry for open items and recent state
2. Read [LEARNINGS.md](.ai/memory/LEARNINGS.md) — absorb accumulated project knowledge before acting
3. Read [TRACEABILITY.md](.ai/memory/TRACEABILITY.md) — check if related work exists before starting

### During a session
- Append to [TRACEABILITY.md](.ai/memory/TRACEABILITY.md) as each link in the chain is established (do not batch at the end)
- Append to [LEARNINGS.md](.ai/memory/LEARNINGS.md) whenever you discover something non-obvious

### At the end of every session
1. Append a new entry to [SESSION_LOG.md](.ai/memory/SESSION_LOG.md) using the template at the top of that file
2. Verify TRACEABILITY.md rows are complete for all work done this session

See [.ai/memory/README.md](.ai/memory/README.md) for the full traceability chain and update triggers.

**Do not skip memory updates.** They are the mechanism by which context survives across sessions.

---

## 3c. Authorization Check (Required Before Gated Actions)

Before taking any **Gated Action** (see category list below), you **MUST** consult [AUTHORIZATIONS.md](.ai/memory/AUTHORIZATIONS.md) and follow its Decision Protocol exactly.

### Gated Action Categories (always require a check)
- Deleting files or directories
- Overwriting uncommitted changes
- Any git operation: commit, push, force, reset, branch deletion
- Adding or removing dependencies
- Modifying CI/CD, env, or build config files
- Touching security-sensitive code (auth, crypto, secrets)
- Making external API calls or sending webhooks
- Skipping, suppressing, or deleting tests

### The Decision Protocol (abbreviated)
1. **Check Base Rules → Never Allowed** — if matched, refuse. Non-negotiable.
2. **Check Base Rules → Always Allowed** — if matched, proceed freely.
3. **Check Learned Authorizations** — if a matching AUTH-NNN exists, follow its status (granted/denied).
4. **No rule found → Ask** for specific permission.
5. **After a grant → Ask the generalization follow-up**:
   > "You've approved [specific action]. Should I treat this as a general rule for [action category], or was this a one-time exception?"
   Accept: "General rule" | "One-time only" | "Only for [narrower scope]"
6. **Record the result** as a new AUTH-NNN row in [AUTHORIZATIONS.md](.ai/memory/AUTHORIZATIONS.md) immediately.

### Key Rules
- Steps 1 and 2 are absolute — learned authorizations and in-session user requests cannot override them.
- Step 5 must **always** be asked after a specific grant, even when it feels obvious.
- If a user says "just do it" without answering step 5, record `scope=session` (expires at end of session, not persisted).
- Always cite the AUTH-NNN or Base Rule you relied on when taking a gated action.

See [AUTHORIZATIONS.md](.ai/memory/AUTHORIZATIONS.md) for the full decision tree, category definitions, and the Learned Authorizations table.

---

## 4. Priority Hierarchy

When directives, user instructions, or constraints conflict, resolve them in this order:

<!--
  Define what wins when rules collide.

  Example:
  1. Security — Never compromise security for any other goal
  2. Correctness — Code must be correct before it is clean
  3. Spec compliance — Match the spec exactly; no extras
  4. Performance — Optimize only when measurably necessary
  5. Readability — Prefer clear code as a tiebreaker
-->

1. [Highest priority]
2. [Second priority]
3. [Third priority]

---

## 5. Communication Rules

How the AI must communicate with the team:

<!--
  Define expected communication behaviors.

  Example:
  - Always cite the file and line number when referencing code
  - Flag ambiguities in specs before implementing, not after
  - Summarize every change set at the end of a session
-->

- [Communication rule 1]
- [Communication rule 2]

---

## 6. Domain-Specific Rules

Rules that apply specifically to this project's domain or stack:

<!--
  Add rules unique to your domain, tech stack, or business context.

  Example:
  - All monetary values must use integer cents, never floats
  - All timestamps must be stored and transmitted as UTC ISO-8601
  - PII fields must be marked and never logged
-->

- [Domain rule 1]
- [Domain rule 2]

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Last Updated | YYYY-MM-DD |
| Owner | [Team/Person] |
| Review Frequency | On every major project change |
