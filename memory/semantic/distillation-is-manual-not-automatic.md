---
name: distillation-is-manual-not-automatic
type: semantic
description: nothing prompts an agent to distill a finished session into memory — it only happens if explicitly asked
confidence: high
source: observed 2026-07-22/23 — dotfiles' memory/ held only the two scaffold/demo entries despite real work (PR #16, #17) having already happened
created: 2026-07-23
last_verified: 2026-07-23
links: [distill-session-into-memory, stale-graph-ci-failure-2026-07-22]
---

The KB ships with a documented procedure for turning a session into memory
(`distill-session-into-memory`), but nothing in the workflow *triggers* that
procedure. `scaffold.sh` sets up the folders, templates, and CI lint, but an
agent has no standing instruction to run the distillation procedure at the
end of a session — it only happens if a human explicitly asks for it (as
happened here, after PR #16/#17 shipped with zero entries created despite a
real merge conflict and a real CI failure worth remembering).

Consequence: a scaffolded KB can look fully wired up (CI green, lint clean,
graph rendering) while actually being empty of real content indefinitely,
because "empty but valid" and "populated" are indistinguishable to the
tooling — `kb.py lint` has no way to flag "this repo has had N sessions of
work and 0 new entries."

What would close the gap: an explicit end-of-session checklist item (e.g. in
a repo's `AGENT.md` or top-level agent instructions) telling the agent to
run the distillation procedure before considering a chunk of work done,
rather than relying on the human to remember to ask. This entry exists to
name the gap; closing it structurally is a separate, not-yet-decided
follow-up.
