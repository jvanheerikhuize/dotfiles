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

1. **Read LEARNINGS.md before touching existing code** — Before modifying any file in `src/`, read `.ai/memory/LEARNINGS.md` in full. It documents accumulated gotchas and hard-won patterns. Skipping this step risks re-introducing known bugs.
2. **Update architecture docs before committing** — If your change adds, removes, or renames a component, entry point, function, or pattern, update `.ai/CONTEXT.md`, `.ai/architecture/ARCHITECTURE.md`, and `.ai/architecture/PATTERNS.md` **before** the commit. These files must reflect the current state of the repo, not a past state.
3. **Create an ADR for every qualifying decision** — Whenever you make a decision that is architectural, a technology choice, security-relevant, hard to reverse, or cross-cutting, create an ADR using the template at `.ai/decisions/template.md` and register it in `.ai/decisions/INDEX.md` in the **same session** as the decision. Do not defer.

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
- Do NOT commit directly to `main` or `master` — all changes must go through a feature branch + PR.
- Do NOT implement a spec whose `status` is not `approved` in `specs.config.yaml`.
- Do NOT hardcode package names in scripts — all package lists belong in `profiles/*.yaml`.
- Do NOT use `[[ cond ]] && cmd` as a standalone statement — it triggers `errexit` under `set -e`; use `if/then` instead.
- Do NOT write output with `echo` directly — all user-facing output must go through `log_info`, `log_warn`, `log_error`, `log_step`, or `log_dry_run` from `src/utils.sh`.

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

### Pre-implementation checks

- [ ] Confirm the spec `status` is `approved` in `specs.config.yaml` before writing any code
- [ ] Read `.ai/CONTEXT.md` to confirm current project state
- [ ] Read `.ai/memory/LEARNINGS.md` in full before modifying any existing file in `src/`
- [ ] Check `.ai/decisions/INDEX.md` to understand past decisions before acting
- [ ] Check `.ai/memory/TRACEABILITY.md` to see if related work already exists

### Pre-commit checks

- [ ] Create an ADR for any decision matching the trigger list (§3a) — do this **before** committing; skipping creates untracked architectural debt
- [ ] Update `.ai/CONTEXT.md`, `.ai/architecture/ARCHITECTURE.md`, and `.ai/architecture/PATTERNS.md` if any component, entry point, flag, or code pattern changed — skipping leaves future AI sessions working from stale context
- [ ] Append a new row to `.ai/memory/TRACEABILITY.md` for each implementation link established this session

### End-of-session checks

- [ ] Append a new entry to `.ai/memory/SESSION_LOG.md`
- [ ] Verify all TRACEABILITY.md rows for this session are complete (Request → Spec → Branch/PR → Status)

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

1. **Safety** — Never compromise system safety, security, or data integrity; never commit credentials or bypass safety checks.
2. **Spec compliance** — Implement exactly what the approved spec requires; no extras, no omissions, no scope creep.
3. **Correctness** — Code must be correct before it is clean or performant; failing tests are never acceptable.
4. **Idempotency** — Every install/setup function must be safe to run twice without side effects.
5. **Readability** — Prefer clear, explicit Bash over clever one-liners; future maintainers are the intended audience.

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

- Flag ambiguities or blockers in a spec **before** starting implementation — raise them immediately, not after writing code.
- When referencing code, always cite the file path and line number.
- Summarize all changes made at the end of a session, including which acceptance criteria were satisfied and which files were modified.
- If a user instruction conflicts with a directive in this file, flag the conflict explicitly before proceeding — do not silently resolve it.

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

- **Never use `[[ cond ]] && cmd` as a statement** under `set -e` — when the condition is false, bash returns exit code 1 which triggers `errexit`. Always use `if [[ cond ]]; then cmd; fi` instead.
- **Always use `return 0`** (not bare `return`) in non-interactive shell guards (e.g., `[[ $- == *i* ]] || return 0`). A bare `return` inherits the exit code of the failed test expression, which propagates through `.bash_profile` and breaks `bash --login -c exit`.
- **All output must go through the logging functions** from `src/utils.sh`: `log_info`, `log_warn`, `log_error`, `log_step`, `log_dry_run`. Never call `echo` directly in scripts.
- **Never hardcode package names in scripts** — all package lists belong in `profiles/*.yaml`. Scripts must remain profile-agnostic.
- **`openssh-client`** (not `ssh`) is the correct apt package name for SSH client tools (`ssh-keygen`, `ssh-copy-id`, `ssh`). This matters in both profiles and smoke test Dockerfiles.

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Last Updated | 2026-02-26 |
| Owner | Jerry van Heerikhuize |
| Review Frequency | On every major project change |
