---
paths:
  - "specs/**"
  - "specs.config.yaml"
---

# Spec files

- Feature specs live in `specs/features/FEAT-NNNN-*.yaml` and must validate against
  `specs/schemas/feature-spec.schema.json`: metadata, description, acceptance_criteria.
- Acceptance criteria use Gherkin style (Given/When/Then), IDs `AC-NNN`.
- `specs.config.yaml` is the registry. Only specs with `status: approved` may be
  implemented; update the status to `implemented` after completion (same change set).
- API specs (`specs/api/*.yaml`) follow OpenAPI 3.1 with complete request/response
  and error schemas.
- Never edit an approved spec's acceptance criteria while implementing it — flag
  ambiguities to the user first (see `.ai/DIRECTIVES.md` §5).
