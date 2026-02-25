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

1. **Read context first** — Before taking any action, read `.ai/CONTEXT.md` to confirm the current project state. Do not rely on memory alone.
2. **Spec approval required** — Do not implement any feature unless its status is `approved` in `specs.config.yaml`. `draft` and `review` specs must not be implemented without explicit user instruction.
3. **Update .ai docs before committing** — After implementing any spec, update `.ai/CONTEXT.md`, `.ai/architecture/ARCHITECTURE.md`, and `.ai/architecture/PATTERNS.md` to reflect the changes before creating the commit.
4. **Idempotency is non-negotiable** — Every operation in `install.sh`, `src/packages.sh`, and `src/dotfiles.sh` must be safe to run twice on the same machine without side effects.
5. **Fail loudly** — Always exit non-zero and print a clear error message on failure. Never silently swallow errors or skip steps without logging.
6. **Minimal sudo** — Elevate only for the individual commands that require it (package installs). Never run the whole script as root.

---

## 2. Forbidden Actions

Actions that must **never** be taken, under any circumstances:

- Do NOT commit directly to `main` or `master` — all changes go through a feature branch and PR.
- Do NOT place implementation code in `scripts/` — that directory contains template tooling only (spec ingestion scripts). All provisioning code goes in `src/` or `install.sh`.
- Do NOT hardcode package lists in shell scripts — package lists always live in `profiles/*.yaml`.
- Do NOT commit credentials, tokens, API keys, or passwords anywhere in the repository.
- Do NOT add `curl | bash` or any un-checksummed script execution to profiles or source files.
- Do NOT modify system-level config files (`/etc/fstab`, `/etc/sudoers`, etc.) — scope is `$HOME` only.
- Do NOT use `--no-verify` to bypass git hooks, or delete/suppress tests to make a build pass.

---

## 3. Required Checks Before Acting

Before making **any** change, verify all of the following:

- [ ] Read `.ai/CONTEXT.md` to confirm current project state and which specs are in progress.
- [ ] Check `.ai/decisions/INDEX.md` to understand past decisions before acting.
- [ ] Confirm the relevant spec is `approved` in `specs.config.yaml` (or user has explicitly instructed implementation of a draft).
- [ ] Read `.ai/architecture/PATTERNS.md` before generating any bash code.
- [ ] Check `.ai/memory/LEARNINGS.md` for known gotchas before touching existing code.

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

1. **Security** — Never compromise security (no secrets, no unsafe evals, no bypassed auth) for any other goal.
2. **Correctness** — Code must be correct and idempotent before it is clean or fast.
3. **Spec compliance** — Match the spec exactly; implement all acceptance criteria and nothing beyond.
4. **Existing patterns** — Follow `.ai/architecture/PATTERNS.md`; match the style of surrounding code.
5. **Simplicity** — Prefer the simpler solution when multiple correct approaches exist.

---

## 5. Communication Rules

- Always cite the file and line number (or section) when referencing existing code or docs.
- Flag ambiguities or conflicts in a spec **before** implementing, not after.
- When a task is blocked (failing test, missing file, unclear requirement), stop and ask — do not brute-force past it.
- At the end of every implementation session, summarise: files changed, acceptance criteria covered, any open items.
- If a user instruction contradicts a directive in this file, name the conflict explicitly before proceeding.

---

## 6. Domain-Specific Rules

Rules that apply specifically to this project's bash provisioning stack:

- **Bash only** — All provisioning logic is bash. No Python, Ruby, or Node scripts in `src/` or `install.sh`.
- **`set -euo pipefail`** — Every script must have this at the top. No exceptions.
- **`[[ cond ]] && cmd` is banned under `set -e`** — Use `if [[ cond ]]; then cmd; fi` instead. `[[ false ]] && cmd` returns exit code 1 and triggers `errexit`.
- **`return 0` not bare `return` in dotfiles** — Non-interactive guards in `.bashrc` etc. must use `return 0`; a bare `return` inherits the exit code of the failed `[[ ]]` test, which propagates through `.bash_profile` and breaks `bash --login`.
- **`--force` in symlink smoke tests** — Smoke tests that exercise dotfile linking must pass `--force` because Ubuntu's `useradd -m` pre-creates `/etc/skel` copies of `.bashrc` etc. in `$HOME`.
- **YAML for all config** — Package lists and profile definitions always go in `profiles/*.yaml`. Never hardcode them in shell.
- **python3 for YAML parsing** — Use inline python3 heredocs (python3 is present on Ubuntu 22.04 by default). No external YAML tools.
- **Dry-run gating** — All mutating operations (package installs, symlink creation, file moves) must check `${DRY_RUN:-false}` and use `log_dry_run` instead of executing when true.

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Last Updated | 2026-02-26 |
| Owner | Jerry |
| Review Frequency | On every major project change |
