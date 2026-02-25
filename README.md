# Enterprise Spec-Based Development Template

A **language-agnostic**, **platform-agnostic**, **AI-agnostic** repository template for **Specification-Driven Development (SDD)** with automated AI-assisted implementation.

## Overview

This template provides a structured approach to software development where features are formally specified before implementation. It includes:

- Formal specification templates and JSON schemas
- Cross-platform automation scripts (Bash & PowerShell)
- Support for multiple AI CLIs (Claude, Aider, Copilot, Cody, and more)
- Multi-platform GitHub Actions workflows (Ubuntu, Windows, macOS)
- Enterprise integrations (Microsoft Teams, Azure DevOps, Slack, and more)
- Operational runbooks and incident response procedures
- Rich GitHub issue and PR templates

### Key Principles

| Principle | Description |
|-----------|-------------|
| **AI-Agnostic** | Works with Claude Code, Aider, GitHub Copilot, Cody, or any AI CLI |
| **Platform-Agnostic** | Supports Windows, macOS, and Linux |
| **Language-Agnostic** | Adaptable to any programming language |
| **Spec-Driven** | Formal specifications before implementation |

## Quick Start

### 1. Use This Template

Click "Use this template" on GitHub or clone and reinitialize:

```bash
# Bash/Unix
git clone https://github.com/jvanheerikhuize/spec-driven-development-template.git my-project
cd my-project
rm -rf .git && git init
```

```powershell
# PowerShell/Windows
git clone https://github.com/jvanheerikhuize/spec-driven-development-template.git my-project
cd my-project
Remove-Item -Recurse -Force .git
git init
```

### 2. Configure Secrets

Add these secrets to your GitHub repository (Settings → Secrets → Actions):

| Secret | Required | Description |
|--------|----------|-------------|
| `ANTHROPIC_API_KEY` | Varies* | API key for Claude Code |
| `OPENAI_API_KEY` | Varies* | API key for Aider/OpenAI |
| `GITHUB_TOKEN` | Auto | For GitHub Copilot (automatic) |
| `TEAMS_WEBHOOK_URL` | No | Microsoft Teams notifications |
| `AZURE_DEVOPS_PAT` | No | Azure DevOps integration |
| `SLACK_WEBHOOK_URL` | No | Slack notifications |

*At least one AI API key is required. See [Integrations Guide](docs/integrations.md) for the complete secrets reference.

### 3. Customize

1. Update `CODEOWNERS` with your team structure
2. Configure AI preferences in `.ai/config.yaml`
3. Configure integrations in `specs.config.yaml`
4. Review and customize issue templates in `.github/ISSUE_TEMPLATE/`

## Repository Structure

```
├── .ai/                            # AI Context System (works with any AI tool)
│   ├── CONTEXT.md                 # Master context (AI starts here)
│   ├── config.yaml                # AI behavior configuration
│   ├── specs/
│   │   └── SPEC.md               # Product specification template
│   ├── architecture/
│   │   ├── ARCHITECTURE.md       # System architecture
│   │   └── PATTERNS.md           # Code patterns & conventions
│   ├── decisions/                 # Architecture Decision Records
│   └── prompts/                   # Reusable prompt templates
│
├── specs/                          # Implementation Specifications
│   ├── features/                   # Feature specs (YAML)
│   │   └── _template.yaml         # Feature template
│   ├── api/                        # API specs (OpenAPI 3.1)
│   │   └── _template.openapi.yaml # OpenAPI template
│   └── schemas/                    # JSON schemas
│       └── feature-spec.schema.json
│
├── scripts/                        # Cross-Platform Automation
│   ├── ingest-spec.sh             # Bash/Unix script
│   └── Invoke-SpecIngestion.ps1   # PowerShell script
│
├── .github/
│   ├── workflows/
│   │   ├── spec-ingestion.yml     # Main automation (multi-platform)
│   │   ├── validate-specs.yml     # Spec validation
│   │   └── notify-integrations.yml # Notification dispatch
│   ├── ISSUE_TEMPLATE/            # Issue templates (6 templates)
│   ├── pull_request_template.md
│   └── CODEOWNERS
│
├── .claude/                        # Claude Code configuration
│   ├── settings.json
│   └── CLAUDE.md                  # AI instructions (works with other tools)
│
├── docs/
│   ├── spec-based-development.md  # SDD guide with rationale
│   ├── integrations.md            # Integration setup guide
│   └── runbooks/                  # Operational runbooks
│       ├── incident-response.md
│       ├── spec-ingestion-failure.md
│       ├── workflow-troubleshooting.md
│       ├── integration-issues.md
│       └── cross-platform-setup.md
│
├── specs.config.yaml              # Central spec registry & integrations
├── CONTRIBUTING.md
├── SECURITY.md
└── README.md
```

## Supported AI CLIs

The automation scripts and workflows auto-detect and support multiple AI coding assistants:

| AI CLI | Install | API Key | Best For |
|--------|---------|---------|----------|
| **Claude Code** | `npm i -g @anthropic-ai/claude-code` | `ANTHROPIC_API_KEY` | Full-featured agentic coding |
| **Aider** | `pip install aider-chat` | `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` | Git-integrated pair programming |
| **GitHub Copilot** | `gh extension install github/gh-copilot` | `GITHUB_TOKEN` | Suggestions and explanations |
| **Cody** | See [Sourcegraph docs](https://sourcegraph.com/docs/cody) | `SRC_ACCESS_TOKEN` | Codebase-aware assistance |
| **OpenAI GPT** | `pip install openai` | `OPENAI_API_KEY` | Direct GPT interactions |
| **Custom** | Set `AI_CLI_COMMAND` | `AI_API_KEY` | Enterprise or specialized tools |

## How It Works

### The Spec-Based Development Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    SPECIFICATION PHASE                          │
├─────────────────────────────────────────────────────────────────┤
│  1. Create spec from template                                   │
│  2. Define acceptance criteria (Given/When/Then)                │
│  3. Submit for review                                           │
│  4. Iterate until approved                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   IMPLEMENTATION PHASE                          │
├─────────────────────────────────────────────────────────────────┤
│  Option A: Automated via AI CLI                                 │
│  • Add to specs.config.yaml with auto_implement: true           │
│  • Workflow auto-detects available AI CLI                       │
│  • Creates feature branch and PR automatically                  │
│                                                                 │
│  Option B: Manual Implementation                                │
│  • Create feature branch: spec/FEAT-XXXX                        │
│  • Implement all acceptance criteria                            │
│  • Write tests, submit PR                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     REVIEW & MERGE                              │
├─────────────────────────────────────────────────────────────────┤
│  • Code review by team                                          │
│  • All acceptance criteria verified                             │
│  • Tests passing                                                │
│  • Merge and update spec status to 'implemented'                │
└─────────────────────────────────────────────────────────────────┘
```

### Local Development

#### Bash/Unix (macOS, Linux)

```bash
# Process a single spec (auto-detects AI CLI)
./scripts/ingest-spec.sh specs/features/FEAT-0001.yaml

# Use specific AI CLI
AI_CLI=aider ./scripts/ingest-spec.sh specs/features/FEAT-0001.yaml

# Validate without implementing
./scripts/ingest-spec.sh --validate specs/features/FEAT-0001.yaml

# Process all approved specs from config
./scripts/ingest-spec.sh --config

# Dry run (preview what would happen)
DRY_RUN=true ./scripts/ingest-spec.sh specs/features/FEAT-0001.yaml
```

#### PowerShell (Windows, Cross-Platform)

```powershell
# Process a single spec (auto-detects AI CLI)
./scripts/Invoke-SpecIngestion.ps1 -SpecFile specs/features/FEAT-0001.yaml

# Use specific AI CLI
./scripts/Invoke-SpecIngestion.ps1 -SpecFile specs/features/FEAT-0001.yaml -AiCli aider

# Validate without implementing
./scripts/Invoke-SpecIngestion.ps1 -Validate -ValidateFile specs/features/FEAT-0001.yaml

# Process all approved specs from config
./scripts/Invoke-SpecIngestion.ps1 -Config

# Dry run
./scripts/Invoke-SpecIngestion.ps1 -SpecFile specs/features/FEAT-0001.yaml -DryRun
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `AI_CLI` | No | Force specific AI CLI (auto-detected if not set) |
| `AI_CLI_COMMAND` | No | Custom CLI command when `AI_CLI=custom` |
| `ANTHROPIC_API_KEY` | Varies | API key for Claude |
| `OPENAI_API_KEY` | Varies | API key for OpenAI/Aider |
| `AI_MODEL` | No | Model to use (provider-specific) |
| `DRY_RUN` | No | Set to "true" for validation only |
| `VERBOSE` | No | Set to "true" for detailed output |

## Writing Specifications

### Feature Spec Example

```yaml
metadata:
  id: "FEAT-0001"
  title: "User Authentication"
  version: "1.0.0"
  status: "draft"
  priority: "high"

description:
  summary: |
    Implement user authentication with email/password.

  problem_statement: |
    Users cannot currently access protected resources.

  proposed_solution: |
    Add login/logout functionality with session management.

acceptance_criteria:
  - id: "AC-001"
    given: "A user with valid credentials"
    when: "They submit the login form"
    then: "They are authenticated and redirected to dashboard"

  - id: "AC-002"
    given: "An authenticated user"
    when: "They click logout"
    then: "Their session is ended and they see the login page"
```

See [specs/features/_template.yaml](specs/features/_template.yaml) for the complete template.

## Integrations

This template supports extensive integrations with enterprise tools. Configure them in `specs.config.yaml`.

### Microsoft Ecosystem

| Integration | Description | Secrets Required |
|-------------|-------------|------------------|
| **Microsoft Teams** | Adaptive Cards notifications | `TEAMS_WEBHOOK_URL` |
| **Azure DevOps** | Work item sync, status updates | `AZURE_DEVOPS_*` |
| **GitHub Projects** | Native project boards | None (uses `GITHUB_TOKEN`) |

### Communication

| Integration | Description | Secret Required |
|-------------|-------------|-----------------|
| **Slack** | Channel notifications | `SLACK_WEBHOOK_URL` |
| **Discord** | Embedded messages | `DISCORD_WEBHOOK_URL` |
| **Email** | SMTP alerts | `SMTP_*` |

### Incident Management

| Integration | Description | Secret Required |
|-------------|-------------|-----------------|
| **PagerDuty** | On-call alerts | `PAGERDUTY_ROUTING_KEY` |
| **Opsgenie** | Alert management | `OPSGENIE_API_KEY` |

See [docs/integrations.md](docs/integrations.md) for complete setup instructions.

## AI Context System

The `.ai/` directory provides structured context for **any** AI coding assistant:

```
.ai/
├── CONTEXT.md          # Start here - project overview & current state
├── config.yaml         # AI behavior preferences & tool settings
├── specs/SPEC.md       # Product specification (WHAT to build)
├── architecture/
│   ├── ARCHITECTURE.md # System design (HOW it's built)
│   └── PATTERNS.md     # Code conventions (HOW to write code)
├── decisions/          # ADRs (WHY decisions were made)
└── prompts/            # Reusable prompt templates
```

### How AI Tools Use This

| Tool | Entry Point | Configuration |
|------|-------------|---------------|
| Claude Code | `.claude/CLAUDE.md` | Auto-loaded |
| Aider | `.ai/CONTEXT.md` | Pass with `--read` |
| GitHub Copilot | `.ai/CONTEXT.md` | Workspace context |
| Cursor | `.ai/` directory | Indexed automatically |
| Cody | `.ai/CONTEXT.md` | Embeddings |
| Continue | `.ai/` directory | Via `.continue/` config |

## Operational Runbooks

The `docs/runbooks/` directory contains operational procedures:

- [Cross-Platform Setup](docs/runbooks/cross-platform-setup.md) - Environment setup for all platforms
- [Incident Response](docs/runbooks/incident-response.md) - Production incident handling
- [Spec Ingestion Failure](docs/runbooks/spec-ingestion-failure.md) - Troubleshooting automation failures
- [Workflow Troubleshooting](docs/runbooks/workflow-troubleshooting.md) - Debug GitHub Actions issues
- [Integration Issues](docs/runbooks/integration-issues.md) - Fix integration connectivity

## GitHub Actions Workflows

| Workflow | Trigger | Platform Support | Purpose |
|----------|---------|------------------|---------|
| `spec-ingestion.yml` | Push, manual, schedule | Ubuntu, Windows, macOS | Main spec processing |
| `validate-specs.yml` | Pull request | Ubuntu | Validate spec files |
| `notify-integrations.yml` | Called by workflows | Ubuntu | Send notifications |

## Documentation

- [Spec-Based Development Guide](docs/spec-based-development.md) - Detailed workflow guide with rationale
- [Integrations Guide](docs/integrations.md) - Complete integration setup instructions
- [Cross-Platform Setup](docs/runbooks/cross-platform-setup.md) - Environment setup guide
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute
- [Security Policy](SECURITY.md) - Reporting vulnerabilities
- [AI Context Guide](.ai/README.md) - AI documentation system

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author & Contributors

**Created by:** Jerry van Heerikhuize ([@jvanheerikhuize](https://github.com/jvanheerikhuize))

**Contributors:**
- AI Assistants (Claude, Aider, Copilot) - AI pair programming

## Acknowledgments

- Designed for use with any AI coding assistant
- Inspired by specification-driven development best practices
- OpenAPI templates based on [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0)

---

<p align="center">
  Built for spec-driven development with AI assistance
</p>
