---
name: regenerate-graph-after-visualize-sync
type: procedural
description: after syncing scripts/visualize.py from upstream, always regenerate and commit the graph
confidence: high
source: memory/episodic/stale-graph-ci-failure-2026-07-22.md
created: 2026-07-23
last_verified: 2026-07-23
links: [stale-graph-ci-failure-2026-07-22]
---

1. Whenever `scripts/kb.py` or `scripts/visualize.py` is synced from the
   upstream knowledge-base repo (per its README's "Keeping a scaffolded
   copy in sync" section), run `python3 scripts/visualize.py` immediately
   afterward — even if no `memory/` entries changed.
2. `git add memory/_generated/graph.md memory/_generated/graph.mmd` and
   commit them in the same PR as the sync.
3. This matters because `visualize.py`'s output *format* can change
   independently of the knowledge base's content (e.g. a mermaid label
   line-break tweak), and `kb-lint.yml`'s staleness check diffs the
   committed graph against freshly generated output — a content-only sync
   can leave the graph stale and fail CI downstream.
