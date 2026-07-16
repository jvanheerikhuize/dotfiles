---
name: implement-spec
description: Implement an approved feature spec (FEAT-NNNN) end to end — branch, code, smoke tests, ADRs, docs, conventional commit, PR. Use when asked to implement, start, or pick up a FEAT spec.
---

# Implement a feature spec

Workflow for taking a spec from `approved` to `implemented`. Stop and ask before
writing code if any gate fails.

## 1. Verify and load context

1. Confirm the spec's `status` is `approved` in `specs.config.yaml`. If not: stop,
   report the actual status, do not implement.
2. Read the spec file in full (`specs/features/FEAT-NNNN-*.yaml`) — every acceptance
   criterion, edge case, and error case.
3. Read `.ai/CONTEXT.md` (current state), `.ai/decisions/INDEX.md` (past decisions),
   and `.ai/memory/TRACEABILITY.md` (related work).
4. Flag spec ambiguities or blockers to the user **now**, before coding.

## 2. Branch

Create `feat/FEAT-NNNN-short-title` from up-to-date `main`. Never work on `main`.

## 3. Implement

- Code in `src/`, wired into `install.sh` if it's a new setup step (source the script,
  call its public function). Follow the shell-patterns rules (auto-loaded).
- Implement **all** acceptance criteria — no extras, no omissions.
- One smoke test scenario minimum per AC group, in `tests/smoke/tests/`, registered
  in `tests/smoke/run-tests.sh` (usage block too). Follow the smoke-tests rules.
- Verify: `bash -n` each changed script, then `bash tests/smoke/run-tests.sh`.

## 4. Record

- ADR for each qualifying decision (architectural, tech choice, security-relevant,
  hard to reverse, cross-cutting): use `.ai/decisions/template.md`, next number from
  `INDEX.md`, status `Accepted`, register in `INDEX.md` and bump "Next ADR number".
- Update `.ai/CONTEXT.md` / `.ai/architecture/ARCHITECTURE.md` / `.ai/architecture/PATTERNS.md`
  if components, entry points, flags, or patterns changed.
- Append a row to `.ai/memory/TRACEABILITY.md` (request → spec → ADR → files → PR).
- Set the spec and `specs.config.yaml` status to `implemented`.

## 5. Ship

- Conventional commit: `feat(FEAT-NNNN): Brief description`, body listing the ACs
  implemented.
- Push the branch and open a PR summarizing which ACs are satisfied and which files
  changed.
