# dotfiles provisioner

Bash-driven Stage 2 provisioner for Ubuntu 22.04. `./install.sh` installs packages
(apt/snap/flatpak/deb/custom), symlinks dotfiles, and bootstraps git identity + SSH key,
all driven by declarative YAML profiles in `profiles/` (inheritance via `extends:`,
base ← desktop ← dev, base ← server).

## Commands

```bash
bash install.sh --profile base --dry-run   # preview a run (always safe)
bash -n <file>                             # syntax-check a script
bash tests/smoke/run-tests.sh              # smoke tests (Docker, ubuntu:22.04)
```

`install.sh` flags: `--profile <name>` (required), `--skip-dotfiles`, `--dotfiles-only`,
`--force`, `--dry-run`, `--validate-only`, `--non-interactive`, `--quiet`, `--help`.

## Hard rules

- Only implement specs whose `status` is `approved` in `specs.config.yaml`. No scope creep:
  implement exactly the acceptance criteria, nothing extra.
- Never commit to `main`/`master` — feature branch + PR, always.
- Implementation code goes in `src/`, never `scripts/` (template tooling only).
- Create an ADR in `.ai/decisions/` (same session, register in `INDEX.md`) for any
  architectural, hard-to-reverse, security-relevant, or cross-cutting decision.
- Priority when rules conflict: safety > spec compliance > correctness > idempotency > readability.
- Commits: conventional format, e.g. `feat(FEAT-0009): Brief description`.

## Where things live

- Project state, key files, current spec status: `.ai/CONTEXT.md`
- Architecture and data flow: `.ai/architecture/ARCHITECTURE.md`
- Bash patterns (loaded automatically via `.claude/rules/` when editing scripts): `.ai/architecture/PATTERNS.md`
- Past decisions: `.ai/decisions/INDEX.md`
- Gated-action permissions: `.ai/memory/AUTHORIZATIONS.md` (follow its Decision Protocol)
- Request → spec → PR audit trail: `.ai/memory/TRACEABILITY.md` (append a row per implementation)
- Full directives: `.ai/DIRECTIVES.md`
