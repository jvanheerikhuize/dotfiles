# Template Sync Runbook

How to receive updates from the upstream template repository into a project that was created from it.

> **Context**: Repositories created via GitHub's "Use this template" button are independent copies — they have no automatic upstream link. This runbook covers how to pull template improvements (new `.ai/` governance files, updated scripts, revised docs) into your project without overwriting your project-specific content.
>
> **Upstream template**: `jvanheerikhuize/ai-template-repository`

---

## Choose Your Approach

| Approach | Best for | Conflict handling |
|----------|----------|-------------------|
| [Upstream remote (git merge)](#option-a-upstream-remote-git-merge) | Teams wanting full control over what to accept | Manual — you review every conflict |
| [Selective file copy](#option-b-selective-file-copy) | Teams who only want specific files updated | Manual — you pick what to copy |
| [GitHub Actions sync](#option-c-github-actions-automation) | Teams who want automated PR proposals | Automatic PR — you review and merge |

---

## Option A: Upstream Remote (git merge)

Add the template repo as a named remote, then merge or cherry-pick selectively.

### One-time setup

```bash
git remote add template git@github.com:jvanheerikhuize/ai-template-repository.git
git fetch template
```

### Sync template changes

```bash
# See what changed in the template since you last synced
git log HEAD..template/main --oneline

# Option 1: Merge the entire template (then resolve conflicts)
git merge template/main --allow-unrelated-histories

# Option 2: Cherry-pick specific commits
git cherry-pick <commit-hash>

# Option 3: Merge only specific paths (e.g. .ai/ governance files)
git checkout template/main -- .ai/DIRECTIVES.md
git checkout template/main -- .ai/decisions/README.md
git checkout template/main -- .ai/decisions/template.md
git checkout template/main -- .ai/memory/README.md
```

### What to keep vs. what to take

| Path | Action |
|------|--------|
| `.ai/DIRECTIVES.md` | Take from template (unless you've customised sections 1–2, 4–6) |
| `.ai/decisions/README.md` | Take from template |
| `.ai/decisions/template.md` | Take from template |
| `.ai/decisions/INDEX.md` | **Keep yours** — this is your project's ADR index |
| `.ai/decisions/ADR-*.md` | **Keep yours** — these are your project's decisions |
| `.ai/memory/README.md` | Take from template |
| `.ai/memory/AUTHORIZATIONS.md` | **Merge carefully** — take updated base rules from template, keep your Learned Authorizations rows |
| `.ai/memory/SESSION_LOG.md` | Take template instructions section only; **keep your log entries** |
| `.ai/memory/TRACEABILITY.md` | Take template instructions section only; **keep your matrix rows** |
| `.ai/memory/LEARNINGS.md` | Take template instructions section only; **keep your learnings** |
| `.ai/config.yaml` | Merge — take structural changes, keep your project values |
| `.ai/CONTEXT.md` | **Keep yours** — this is your project's context |
| `.ai/architecture/PATTERNS.md` | Merge — take template improvements, keep your project patterns |
| `scripts/` | Take from template |
| `docs/` | Take from template (runbooks, etc.) |
| `README.md` | Merge — take structural improvements, keep your project description |

---

## Option B: Selective File Copy

No git remote needed. Manually download and apply specific files.

```bash
# Download a specific file from the template using gh CLI
gh api repos/jvanheerikhuize/ai-template-repository/contents/.ai/DIRECTIVES.md \
  --jq '.content' | base64 -d > .ai/DIRECTIVES.md

# Or fetch multiple files
for file in \
  ".ai/decisions/README.md" \
  ".ai/decisions/template.md" \
  ".ai/memory/README.md"; do
  gh api "repos/jvanheerikhuize/ai-template-repository/contents/${file}" \
    --jq '.content' | base64 -d > "${file}"
done
```

Use this when you only want to pull a small number of specific files (e.g. a new runbook or a DIRECTIVES.md update).

---

## Option C: GitHub Actions Automation

Add this workflow to your project to receive automated sync PRs whenever the template is updated.

Create `.github/workflows/sync-template.yml`:

```yaml
name: Sync from template

on:
  schedule:
    - cron: '0 9 * * 1'   # Every Monday at 09:00 UTC
  workflow_dispatch:       # Allow manual trigger

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Sync from template
        uses: AndreasAugustin/actions-template-sync@v2
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          source_repo_path: jvanheerikhuize/ai-template-repository
          upstream_branch: main
          pr_title: "chore: sync updates from template repository"
          pr_labels: template-sync
```

This creates a PR with all template changes. Review and merge selectively — the "What to keep vs. what to take" table above applies here too.

---

## Conflict Resolution Tips

### `.ai/memory/AUTHORIZATIONS.md`
- Take the template's updated base rules (Never Allowed, Always Allowed, Always Ask sections)
- Keep your own Learned Authorizations rows (AUTH-NNN entries)

### `.ai/DIRECTIVES.md`
- Take all new sections added by the template
- Keep any content you've filled in (sections 1, 2, 4, 5, 6 are yours to own)
- Sections 3a, 3b, 3c are template-managed — always take the template version

### `README.md`
- Take structural updates to the structure tree, AI Context System section, and repo overview
- Keep your project name, description, quick start commands, and contact info

---

## Checking What Changed

```bash
# One-time: add the template remote if not already added
git remote add template git@github.com:jvanheerikhuize/ai-template-repository.git

# Compare your .ai/ folder with the template's current state
git fetch template
git diff HEAD template/main -- .ai/

# See only files that differ
git diff --name-only HEAD template/main -- .ai/
```
