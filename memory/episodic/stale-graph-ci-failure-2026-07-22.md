---
name: stale-graph-ci-failure-2026-07-22
type: episodic
description: kb-lint.yml failed after syncing visualize.py because the committed graph wasn't regenerated
confidence: high
source: dotfiles PR #16 (sync) and PR #17 (fix), knowledge-base PR #11 (doc fix)
created: 2026-07-23
last_verified: 2026-07-23
links: [regenerate-graph-after-visualize-sync]
---

PR #16 synced `scripts/kb.py`/`scripts/visualize.py` from the upstream
knowledge-base repo, resolving a real merge conflict in `kb.py` along the
way. After merging, `kb-lint.yml` failed on both the PR check and the
merge-triggered push, at the "Fail if generated graph is out of date" step.

Root cause: the synced `visualize.py` now emits `<br/>` instead of `\n` for
mermaid label line breaks. The committed `.kb/generated/graph.md` and
`graph.mmd` still had the old `\n` output, so CI's diff check
(`git diff --exit-code` against freshly generated output) failed — even
though nothing in `memory/`'s actual content had changed.

Fixed via PR #17: ran `python3 scripts/visualize.py` and committed the
regenerated graph files. `lint-and-visualize` passed immediately after.

What should change next time: a `visualize.py` sync must always be followed
by regenerating and committing the graph, even if no `memory/` entries were
touched — the generator's *output format* can change independently of the
knowledge base's content. See `regenerate-graph-after-visualize-sync`. This
gap was also documented upstream in knowledge-base's README (PR #11) so
other consumer repos don't repeat it.
