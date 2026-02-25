# Master Prompt: Create Enterprise Spec-Based Development Repository

> Use this prompt with any AI coding assistant to recreate the complete spec-driven development template repository.

---

## Prompt

Create an enterprise-ready, industry-standard GitHub repository template for **Specification-Driven Development (SDD)** with AI-assisted implementation. The repository must be:

1. **Language-Agnostic**: Works with any programming language
2. **Platform-Agnostic**: Supports Windows, macOS, and Linux
3. **AI-Agnostic**: Works with any AI coding assistant (Claude, Aider, Copilot, Cody, GPT, etc.)

### Core Requirements

#### 1. Specification System
Create a formal specification system with:
- Feature spec template in YAML format (`specs/features/_template.yaml`)
- JSON Schema for validation (`specs/schemas/feature-spec.schema.json`)
- OpenAPI 3.1 template for APIs (`specs/api/_template.openapi.yaml`)
- Central configuration registry (`specs.config.yaml`)
- Gherkin-style acceptance criteria (Given/When/Then)
- Spec lifecycle: draft → review → approved → implemented → deprecated

#### 2. Cross-Platform Automation Scripts
Create scripts that:
- Auto-detect available AI CLI (Claude, Aider, Copilot, Cody, GPT)
- Support custom AI CLI via environment variable
- Work on Unix (Bash) AND Windows (PowerShell)
- Validate specs against JSON schemas
- Build prompts from specs for AI implementation
- Support dry-run mode and verbose output

Files to create:
- `scripts/ingest-spec.sh` (Bash)
- `scripts/Invoke-SpecIngestion.ps1` (PowerShell)

#### 3. GitHub Actions Workflows
Create workflows that:
- Support multiple runner OS (ubuntu-latest, windows-latest, macos-latest)
- Auto-detect and install appropriate AI CLI
- Process specs on push, manual dispatch, schedule, and PR approval
- Validate specs before processing
- Create feature branches and PRs automatically
- Send notifications to integrations

Files to create:
- `.github/workflows/spec-ingestion.yml`
- `.github/workflows/validate-specs.yml`
- `.github/workflows/notify-integrations.yml`

#### 4. AI Context System
Create a `.ai/` directory with structured context for any AI assistant:
- `CONTEXT.md` - Master context file (project overview)
- `config.yaml` - AI behavior configuration with multi-tool support
- `specs/SPEC.md` - Product specification template
- `architecture/ARCHITECTURE.md` - System architecture template
- `architecture/PATTERNS.md` - Code patterns and conventions
- `decisions/template.md` - Architecture Decision Record template
- `prompts/implementation.md` - Reusable implementation prompt
- `prompts/review.md` - Code review prompt
- `prompts/debug.md` - Debugging prompt

#### 5. GitHub Templates
Create comprehensive issue and PR templates:
- Bug report (with component selection)
- Feature request (with category and complexity)
- Spec review request
- Incident report (with severity levels)
- Documentation request
- Integration request
- Pull request template (comprehensive)
- `config.yml` for issue template chooser

#### 6. Operational Runbooks
Create runbooks in `docs/runbooks/`:
- `_template.md` - Runbook template
- `incident-response.md` - Production incident handling
- `spec-ingestion-failure.md` - Troubleshooting automation
- `workflow-troubleshooting.md` - GitHub Actions debugging
- `integration-issues.md` - Integration connectivity fixes
- `cross-platform-setup.md` - Environment setup for all platforms

#### 7. Integrations Configuration
In `specs.config.yaml`, include integration settings for:

**Communication:**
- Microsoft Teams (with Adaptive Cards)
- Slack
- Discord
- Email (SMTP)

**Project Management:**
- Azure DevOps (work items)
- GitHub Projects
- Linear
- Jira

**Incident Management:**
- PagerDuty
- Opsgenie

**Observability:**
- Datadog
- New Relic
- Sentry

**Custom:**
- Generic webhooks with HMAC signing

Create `docs/integrations.md` with setup instructions for each.

#### 8. Supporting Files
- `.claude/CLAUDE.md` - AI instructions (works with other tools too)
- `.claude/settings.json` - Claude Code settings
- `CODEOWNERS` - Code ownership (with placeholder teams)
- `CONTRIBUTING.md` - Contribution guidelines
- `SECURITY.md` - Security policy
- `LICENSE` - MIT License
- `.editorconfig` - Editor configuration
- `.gitignore` - Git ignore patterns
- `README.md` - Comprehensive documentation

### Design Principles

1. **Spec-First**: All features require formal specifications before implementation
2. **Automated Validation**: JSON schemas validate all specs
3. **AI-Assisted**: AI CLIs implement approved specs automatically
4. **Human Review**: All AI-generated code requires human review via PR
5. **Cross-Platform**: Everything works on Windows, macOS, and Linux
6. **Tool-Agnostic**: No vendor lock-in to specific AI tools
7. **Enterprise-Ready**: Integrations, runbooks, security policies

### Environment Variables

Support these environment variables:
- `AI_CLI` - Force specific AI CLI (auto, claude, aider, copilot, cody, gpt, custom)
- `AI_CLI_COMMAND` - Custom CLI command when AI_CLI=custom
- `ANTHROPIC_API_KEY` - Claude API key
- `OPENAI_API_KEY` - OpenAI/Aider API key
- `GITHUB_TOKEN` - GitHub Copilot token
- `SRC_ACCESS_TOKEN` - Sourcegraph Cody token
- `AI_MODEL` - Model to use (provider-specific)
- `DRY_RUN` - Validation only mode
- `VERBOSE` - Detailed output

### Quality Standards

- All YAML files must be valid
- All scripts must include help/usage information
- All documentation must have clear structure
- All templates must include TODO comments for customization
- Placeholder values should be obvious (your-org, example.com)
- Code should be production-ready, not just examples

---

## Expected Output Structure

```
├── .ai/
│   ├── CONTEXT.md
│   ├── README.md
│   ├── config.yaml
│   ├── specs/SPEC.md
│   ├── architecture/
│   │   ├── ARCHITECTURE.md
│   │   └── PATTERNS.md
│   ├── decisions/template.md
│   └── prompts/
│       ├── implementation.md
│       ├── review.md
│       ├── debug.md
│       └── create-repository.md
├── .claude/
│   ├── CLAUDE.md
│   └── settings.json
├── .github/
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug-report.yaml
│   │   ├── config.yml
│   │   ├── documentation.yaml
│   │   ├── feature-request.yaml
│   │   ├── incident-report.yaml
│   │   ├── integration-request.yaml
│   │   └── spec-review.yaml
│   ├── pull_request_template.md
│   └── workflows/
│       ├── notify-integrations.yml
│       ├── spec-ingestion.yml
│       └── validate-specs.yml
├── docs/
│   ├── integrations.md
│   ├── spec-based-development.md
│   └── runbooks/
│       ├── README.md
│       ├── _template.md
│       ├── cross-platform-setup.md
│       ├── incident-response.md
│       ├── integration-issues.md
│       ├── spec-ingestion-failure.md
│       └── workflow-troubleshooting.md
├── scripts/
│   ├── ingest-spec.sh
│   └── Invoke-SpecIngestion.ps1
├── specs/
│   ├── api/_template.openapi.yaml
│   ├── features/_template.yaml
│   └── schemas/feature-spec.schema.json
├── .editorconfig
├── .gitignore
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── SECURITY.md
└── specs.config.yaml
```

---

## Usage Notes

This prompt can be used with:
- **Claude Code**: `claude "$(cat .ai/prompts/create-repository.md)"`
- **Aider**: `aider --message "$(cat .ai/prompts/create-repository.md)"`
- **Any AI Chat**: Copy and paste the prompt content

The resulting repository will be immediately usable for spec-driven development with any AI coding assistant on any platform.
