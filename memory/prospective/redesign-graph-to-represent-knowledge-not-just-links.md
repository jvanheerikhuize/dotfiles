---
name: redesign-graph-to-represent-knowledge-not-just-links
type: prospective
description: redesign .kb/generated/graph so it represents the consuming repo's actual knowledge, not just which entries link to which
confidence: unverified
source: user request, 2026-07-23 — after reviewing PR #18's distillation entries
created: 2026-07-23
last_verified: 2026-07-23
links: [distillation-is-manual-not-automatic]
due: 2026-07-24
---

`scripts/visualize.py` currently renders a *change graph*: nodes are entry
slugs, edges are `links:` frontmatter references between them. That shows
structure (what points to what) but not content — it doesn't tell you what
the repo actually knows, at a glance.

User wants the graph to represent the consuming repo's knowledge instead —
i.e. something closer to a concept/topic map of what's been learned, not
just a citation graph of entry-to-entry references.

Open questions to resolve before implementing:
- What should nodes represent if not entries — topics/tags extracted from
  entries? Types (semantic/episodic/procedural/...) as clusters?
- Does this replace the existing link graph or sit alongside it as a second
  view?
- Is this specific to dotfiles' `memory/`, or should it go back upstream
  into `knowledge-base`'s `scripts/visualize.py` so every scaffolded copy
  benefits (consistent with how the stale-graph fix was upstreamed via
  knowledge-base PR #11)?

Follow up on this the next time work resumes on the KB.
