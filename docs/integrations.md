# Integrations Guide

This guide explains how to configure integrations with external services for the spec-based development system.

## Overview

The spec ingestion system supports integrations with:

| Category | Services |
|----------|----------|
| **Communication** | Slack, Microsoft Teams, Discord, Email |
| **Project Management** | Jira, Linear, Azure DevOps, GitHub Projects |
| **Incident Management** | PagerDuty, Opsgenie |
| **Observability** | Datadog, New Relic, Sentry |
| **Custom** | Webhooks |

## Quick Setup

1. Choose your integrations in `specs.config.yaml`
2. Add required secrets to GitHub repository
3. Enable the integration (`enabled: true`)
4. Test with a sample spec

---

## Communication Integrations

### Slack

Send notifications to Slack channels when specs are processed.

#### Setup

1. **Create Slack App:**
   - Go to [api.slack.com/apps](https://api.slack.com/apps)
   - Click "Create New App" → "From scratch"
   - Name: "Spec Bot" (or your preference)
   - Select your workspace

2. **Enable Incoming Webhooks:**
   - Go to "Incoming Webhooks"
   - Toggle "Activate Incoming Webhooks" to On
   - Click "Add New Webhook to Workspace"
   - Select the channel (e.g., #engineering)
   - Copy the webhook URL

3. **Add GitHub Secret:**
   - Repository Settings → Secrets → Actions
   - Add `SLACK_WEBHOOK_URL` with the webhook URL

4. **Configure in specs.config.yaml:**
   ```yaml
   integrations:
     slack:
       enabled: true
       channel: "#engineering"
       notify_on:
         - "spec_approved"
         - "implementation_completed"
         - "implementation_failed"
       mention_on_failure: ["@channel"]
   ```

#### Message Examples

**Implementation Started:**
```
🚀 Spec Implementation Started
• ID: FEAT-0001
• Title: User Authentication
• Branch: spec/feat-0001
```

**Implementation Completed:**
```
✅ Spec Implementation Completed
• ID: FEAT-0001
• Title: User Authentication
• PR: #42
• Review requested from: @team
```

**Implementation Failed:**
```
❌ Spec Implementation Failed
• ID: FEAT-0001
• Title: User Authentication
• Error: Schema validation failed
• Logs: [View Details]
```

---

### Microsoft Teams

Send notifications to Microsoft Teams channels.

#### Setup

1. **Create Incoming Webhook:**
   - In Teams, go to the channel
   - Click "..." → "Connectors"
   - Find "Incoming Webhook" → Configure
   - Name: "Spec Bot"
   - Copy the webhook URL

2. **Add GitHub Secret:**
   - Add `TEAMS_WEBHOOK_URL`

3. **Configure:**
   ```yaml
   integrations:
     teams:
       enabled: true
       notify_on:
         - "implementation_completed"
         - "implementation_failed"
       use_adaptive_cards: true
   ```

#### Adaptive Card Format

When `use_adaptive_cards: true`, notifications use rich formatting with:
- Color-coded headers (green for success, red for failure)
- Structured data display
- Action buttons (View PR, View Spec)

---

### Discord

Send notifications to Discord channels.

#### Setup

1. **Create Webhook:**
   - Server Settings → Integrations → Webhooks
   - Create Webhook
   - Select channel
   - Copy webhook URL

2. **Add GitHub Secret:**
   - Add `DISCORD_WEBHOOK_URL`

3. **Configure:**
   ```yaml
   integrations:
     discord:
       enabled: true
       notify_on:
         - "implementation_completed"
         - "implementation_failed"
       username: "Spec Bot"
       avatar_url: "https://example.com/bot-avatar.png"
   ```

---

### Email

Send email notifications via SMTP.

#### Setup

1. **Add GitHub Secrets:**
   - `SMTP_HOST` - SMTP server hostname
   - `SMTP_USER` - SMTP username
   - `SMTP_PASSWORD` - SMTP password

2. **Configure:**
   ```yaml
   integrations:
     email:
       enabled: true
       smtp:
         host: "smtp.example.com"
         port: 587
         secure: true
       from: "specs@example.com"
       recipients:
         implementation_failed:
           - "oncall@example.com"
         pr_created:
           - "reviewers@example.com"
   ```

---

## Project Management Integrations

### Jira

Sync specifications with Jira issues.

#### Setup

1. **Create API Token:**
   - Go to [id.atlassian.com/manage/api-tokens](https://id.atlassian.com/manage/api-tokens)
   - Create API token

2. **Add GitHub Secrets:**
   - `JIRA_BASE_URL` - e.g., `https://your-domain.atlassian.net`
   - `JIRA_EMAIL` - Your Atlassian email
   - `JIRA_API_TOKEN` - The API token

3. **Find Transition IDs:**
   ```bash
   # Get transitions for an issue
   curl -u email:token \
     "https://your-domain.atlassian.net/rest/api/3/issue/PROJ-1/transitions"
   ```

4. **Configure:**
   ```yaml
   integrations:
     jira:
       enabled: true
       base_url: "https://your-domain.atlassian.net"
       project_key: "PROJ"
       issue_type: "Story"
       transition_on_approve: "21"  # "In Progress" transition ID
       transition_on_implement: "31"  # "Done" transition ID
       field_mappings:
         spec_id: "customfield_10001"
         acceptance_criteria: "customfield_10002"
   ```

#### Features

- **Auto-create issues:** Creates Jira issue when spec is created
- **Status sync:** Updates Jira status when spec status changes
- **Link to PR:** Adds PR link to Jira issue
- **Subtasks:** Optionally creates subtasks for each acceptance criterion

---

### Linear

Sync specifications with Linear issues.

#### Setup

1. **Create API Key:**
   - Linear Settings → API → Create key

2. **Find Team ID:**
   - Linear Settings → Teams → Copy team ID from URL

3. **Add GitHub Secret:**
   - `LINEAR_API_KEY`

4. **Configure:**
   ```yaml
   integrations:
     linear:
       enabled: true
       team_id: "TEAM_ID"
       labels:
         - "spec"
         - "automated"
       state_mappings:
         draft: "Backlog"
         review: "In Review"
         approved: "Todo"
         implemented: "Done"
   ```

---

### Azure DevOps

Sync with Azure DevOps work items.

#### Setup

1. **Create Personal Access Token:**
   - Azure DevOps → User Settings → Personal Access Tokens
   - Create with "Work Items: Read & Write" scope

2. **Add GitHub Secrets:**
   - `AZURE_DEVOPS_ORG` - Organization name
   - `AZURE_DEVOPS_PROJECT` - Project name
   - `AZURE_DEVOPS_PAT` - Personal Access Token

3. **Configure:**
   ```yaml
   integrations:
     azure_devops:
       enabled: true
       organization: "your-org"
       project: "your-project"
       work_item_type: "User Story"
       area_path: "your-project\\Team"
       iteration_path: "your-project\\Sprint 1"
   ```

---

### GitHub Projects

Add specs to GitHub Projects (v2).

#### Setup

1. **Find Project Number:**
   - Go to your project
   - Number is in the URL: `github.com/orgs/ORG/projects/NUMBER`

2. **Configure:**
   ```yaml
   integrations:
     github_projects:
       enabled: true
       project_number: 1
       status_field: "Status"
       status_mappings:
         draft: "Backlog"
         review: "In Review"
         approved: "Ready"
         implemented: "Done"
   ```

---

## Incident Management Integrations

### PagerDuty

Alert on-call when implementations fail.

#### Setup

1. **Create Integration:**
   - PagerDuty → Services → Your Service → Integrations
   - Add "Events API v2" integration
   - Copy the routing key

2. **Add GitHub Secret:**
   - `PAGERDUTY_ROUTING_KEY`

3. **Configure:**
   ```yaml
   integrations:
     pagerduty:
       enabled: true
       alert_on:
         - "implementation_failed"
       severity: "warning"  # critical, error, warning, info
   ```

#### Alert Behavior

- **SEV1 specs:** `severity: critical` - Pages immediately
- **Regular specs:** `severity: warning` - Creates incident but may not page

---

### Opsgenie

Send alerts via Opsgenie.

#### Setup

1. **Create API Integration:**
   - Opsgenie → Teams → Your Team → Integrations
   - Add "API" integration
   - Copy API key

2. **Add GitHub Secret:**
   - `OPSGENIE_API_KEY`

3. **Configure:**
   ```yaml
   integrations:
     opsgenie:
       enabled: true
       alert_on:
         - "implementation_failed"
       priority: "P3"
       tags:
         - "spec-automation"
         - "ci-cd"
   ```

---

## Observability Integrations

### Datadog

Send metrics and events to Datadog.

#### Setup

1. **Get API Keys:**
   - Datadog → Organization Settings → API Keys
   - Create or copy API key and App key

2. **Add GitHub Secrets:**
   - `DATADOG_API_KEY`
   - `DATADOG_APP_KEY`

3. **Configure:**
   ```yaml
   integrations:
     datadog:
       enabled: true
       site: "datadoghq.com"
       send_metrics: true
       metric_prefix: "spec_ingestion"
       send_events: true
       event_tags:
         - "team:platform"
         - "env:production"
   ```

#### Metrics Sent

| Metric | Type | Description |
|--------|------|-------------|
| `spec_ingestion.processed` | Counter | Specs processed |
| `spec_ingestion.success` | Counter | Successful implementations |
| `spec_ingestion.failure` | Counter | Failed implementations |
| `spec_ingestion.duration` | Gauge | Processing duration (seconds) |

---

### New Relic

Send custom events to New Relic.

#### Setup

1. **Get API Key:**
   - New Relic → API Keys → Create key (Ingest - License)

2. **Add GitHub Secret:**
   - `NEW_RELIC_API_KEY`

3. **Configure:**
   ```yaml
   integrations:
     new_relic:
       enabled: true
       account_id: "1234567"
       event_type: "SpecIngestion"
   ```

#### Querying Events

```sql
SELECT * FROM SpecIngestion
WHERE spec_id = 'FEAT-0001'
SINCE 1 day ago
```

---

### Sentry

Report errors to Sentry.

#### Setup

1. **Get DSN:**
   - Sentry → Project Settings → Client Keys (DSN)

2. **Add GitHub Secret:**
   - `SENTRY_DSN`

3. **Configure:**
   ```yaml
   integrations:
     sentry:
       enabled: true
       environment: "production"
       report_on:
         - "implementation_failed"
         - "validation_failed"
   ```

---

## Custom Webhooks

Send notifications to any HTTP endpoint.

#### Setup

```yaml
integrations:
  webhooks:
    enabled: true
    endpoints:
      - name: "internal-system"
        url: "https://internal.example.com/spec-webhook"
        events:
          - "spec_approved"
          - "implementation_completed"
        headers:
          Authorization: "Bearer ${WEBHOOK_TOKEN}"
        retry_count: 3

      - name: "analytics"
        url: "https://analytics.example.com/events"
        events:
          - "implementation_completed"
        # HMAC signature verification
        secret: "${WEBHOOK_SECRET_ANALYTICS}"
```

#### Payload Format

```json
{
  "event": "implementation_completed",
  "timestamp": "2025-01-19T12:00:00Z",
  "spec": {
    "id": "FEAT-0001",
    "title": "User Authentication",
    "file": "specs/features/FEAT-0001.yaml",
    "status": "implemented"
  },
  "pr": {
    "number": 42,
    "url": "https://github.com/org/repo/pull/42"
  },
  "repository": {
    "owner": "org",
    "name": "repo"
  }
}
```

#### HMAC Verification

If `secret` is provided, requests include `X-Signature-256` header:

```python
import hmac
import hashlib

def verify_signature(payload, signature, secret):
    expected = hmac.new(
        secret.encode(),
        payload.encode(),
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature)
```

---

## Notification Events

| Event | Description | Triggered When |
|-------|-------------|----------------|
| `spec_created` | New spec file added | Spec file committed |
| `spec_approved` | Spec status → approved | Status changes in file |
| `implementation_started` | AI begins work | Workflow starts |
| `implementation_completed` | AI finishes successfully | PR created |
| `implementation_failed` | AI or validation fails | Workflow fails |
| `pr_created` | Pull request opened | After implementation |
| `pr_merged` | Pull request merged | PR merge event |
| `validation_failed` | Schema validation fails | During validation step |

---

## Secrets Reference

| Secret Name | Used By | Description |
|-------------|---------|-------------|
| `ANTHROPIC_API_KEY` | Core | Claude Code API key |
| `SLACK_WEBHOOK_URL` | Slack | Incoming webhook URL |
| `TEAMS_WEBHOOK_URL` | Teams | Incoming webhook URL |
| `DISCORD_WEBHOOK_URL` | Discord | Webhook URL |
| `JIRA_BASE_URL` | Jira | Atlassian domain |
| `JIRA_EMAIL` | Jira | User email |
| `JIRA_API_TOKEN` | Jira | API token |
| `LINEAR_API_KEY` | Linear | API key |
| `AZURE_DEVOPS_ORG` | Azure DevOps | Organization name |
| `AZURE_DEVOPS_PROJECT` | Azure DevOps | Project name |
| `AZURE_DEVOPS_PAT` | Azure DevOps | Personal access token |
| `PAGERDUTY_ROUTING_KEY` | PagerDuty | Events API routing key |
| `OPSGENIE_API_KEY` | Opsgenie | API key |
| `DATADOG_API_KEY` | Datadog | API key |
| `DATADOG_APP_KEY` | Datadog | Application key |
| `NEW_RELIC_API_KEY` | New Relic | Ingest license key |
| `SENTRY_DSN` | Sentry | Data source name |
| `SMTP_HOST` | Email | SMTP server |
| `SMTP_USER` | Email | SMTP username |
| `SMTP_PASSWORD` | Email | SMTP password |

---

## Troubleshooting

### Notifications Not Sending

1. **Check integration is enabled:**
   ```yaml
   slack:
     enabled: true  # Must be true
   ```

2. **Verify secrets are set:**
   - Go to Settings → Secrets → Actions
   - Ensure secret exists and is named correctly

3. **Check workflow logs:**
   - Look for integration-related errors in Actions logs

4. **Test webhook manually:**
   ```bash
   curl -X POST -H "Content-Type: application/json" \
     -d '{"text": "Test message"}' \
     "$SLACK_WEBHOOK_URL"
   ```

### Jira Sync Issues

1. **Check permissions:**
   - API token user must have project access
   - Verify "Create Issues" permission

2. **Validate transition IDs:**
   - IDs are numeric (e.g., "21", not "In Progress")
   - Get correct IDs from API

3. **Check custom field IDs:**
   - Custom fields use IDs like `customfield_10001`
   - Verify in Jira Admin → Custom Fields

### Rate Limiting

If hitting rate limits:

```yaml
notifications:
  rate_limit:
    max_per_hour: 30  # Reduce if needed
    max_per_day: 100
```

---

## Related Documentation

- [Spec-Based Development Guide](spec-based-development.md)
- [Runbooks](runbooks/)
- [Configuration Reference](../specs.config.yaml)
