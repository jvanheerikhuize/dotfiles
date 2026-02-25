# Runbook: Integration Issues

> **Last Updated:** 2025-01-19
> **Owner:** Platform Team
> **Review Frequency:** Quarterly

## Overview

This runbook covers troubleshooting issues with external service integrations including Microsoft Teams, Azure DevOps, Slack, Discord, and other connected services. Use this when notifications aren't being delivered or project management sync isn't working.

## Prerequisites

- [ ] Access to GitHub repository secrets
- [ ] Admin access to integrated services (Teams, Azure DevOps, Slack, etc.)
- [ ] `curl` and `jq` installed locally
- [ ] Access to `specs.config.yaml`

## Symptoms

- Notifications not appearing in Teams/Slack/Discord
- Work items not created in Azure DevOps/Jira
- Webhook errors in workflow logs
- Integration-related error notifications
- Status sync not working between systems

## Impact Assessment

| Severity | Criteria | Response Time |
|----------|----------|---------------|
| SEV4 | Single integration down | Next business day |
| SEV3 | Multiple integrations down | 1 hour |
| SEV2 | Critical integration down (e.g., incident alerts) | 15 minutes |
| SEV1 | All integrations down | Immediate |

## Diagnostic Steps

### Step 1: Identify Affected Integration

Check workflow logs for integration-specific errors:

```bash
# View recent workflow runs
gh run list --workflow notify-integrations.yml --limit 5

# View logs for failed run
gh run view <run-id> --log
```

### Step 2: Verify Configuration

```bash
# Check if integration is enabled
yq e '.integrations.<service>.enabled' specs.config.yaml

# Example for Teams
yq e '.integrations.teams.enabled' specs.config.yaml
```

### Step 3: Check Secrets

1. Go to **Settings > Secrets and variables > Actions**
2. Verify required secrets exist for the integration
3. Check secret names match exactly (case-sensitive)

## Resolution Steps

---

### Microsoft Teams Issues

#### Symptoms
- No notifications in Teams channel
- Error: `400 Bad Request` or `404 Not Found`

#### T1: Verify Webhook URL

```bash
# Test Teams webhook manually
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    "summary": "Test",
    "sections": [{"activityTitle": "Test Message"}]
  }' \
  "$TEAMS_WEBHOOK_URL"
```

**Expected:** `1` (success) or empty response
**If error:** Webhook URL may be invalid or expired

#### T2: Regenerate Webhook

1. In Teams, go to the channel
2. Click `...` > **Connectors**
3. Find **Incoming Webhook** > **Configure**
4. Create new webhook or copy existing URL
5. Update `TEAMS_WEBHOOK_URL` secret in GitHub

#### T3: Check Message Format

```yaml
# In specs.config.yaml, verify:
integrations:
  teams:
    enabled: true
    use_adaptive_cards: true  # or false for simple format
```

---

### Azure DevOps Issues

#### Symptoms
- Work items not created/updated
- Error: `401 Unauthorized` or `403 Forbidden`

#### A1: Verify PAT Token

```bash
# Test Azure DevOps connection
curl -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$AZURE_DEVOPS_ORG/_apis/projects?api-version=7.0"
```

**Expected:** JSON with project list
**If 401:** PAT is invalid or expired

#### A2: Check PAT Permissions

Required PAT scopes:
- **Work Items:** Read & Write
- **Code:** Read (if linking to repos)
- **Project and Team:** Read

To regenerate:
1. Go to Azure DevOps > **User Settings** > **Personal Access Tokens**
2. Create new token with required scopes
3. Update `AZURE_DEVOPS_PAT` secret in GitHub

#### A3: Verify Configuration

```yaml
# In specs.config.yaml
integrations:
  azure_devops:
    enabled: true
    organization: "your-org"      # Must match exactly
    project: "your-project"       # Must match exactly
    work_item_type: "User Story"  # Must exist in project
```

#### A4: Check Area/Iteration Paths

```bash
# List available area paths
curl -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJECT/_apis/wit/classificationnodes/areas?api-version=7.0"

# List available iteration paths
curl -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJECT/_apis/wit/classificationnodes/iterations?api-version=7.0"
```

---

### Slack Issues

#### Symptoms
- No messages in Slack channel
- Error: `invalid_payload` or `channel_not_found`

#### S1: Test Webhook

```bash
# Test Slack webhook
curl -X POST -H "Content-Type: application/json" \
  --data '{"text": "Test message from spec automation"}' \
  "$SLACK_WEBHOOK_URL"
```

**Expected:** `ok`
**If error:** Check webhook URL and channel settings

#### S2: Regenerate Webhook

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Select your app > **Incoming Webhooks**
3. Add new webhook to workspace
4. Select target channel
5. Update `SLACK_WEBHOOK_URL` secret in GitHub

#### S3: Check Channel Permissions

- Webhook must be created for the specific channel
- Bot must be invited to private channels
- Channel name in config is for reference only (webhook determines target)

---

### Discord Issues

#### Symptoms
- No messages in Discord channel
- Error: `Unknown Webhook` or `Invalid Webhook Token`

#### D1: Test Webhook

```bash
# Test Discord webhook
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "content": "Test message",
    "embeds": [{"title": "Test", "description": "Test embed"}]
  }' \
  "$DISCORD_WEBHOOK_URL"
```

**Expected:** Empty response with 204 status
**If error:** Webhook may be deleted

#### D2: Regenerate Webhook

1. In Discord, go to **Server Settings** > **Integrations** > **Webhooks**
2. Create new webhook or edit existing
3. Copy webhook URL
4. Update `DISCORD_WEBHOOK_URL` secret in GitHub

---

### PagerDuty Issues

#### Symptoms
- Alerts not triggering
- Error in workflow logs related to PagerDuty

#### P1: Test Events API

```bash
# Test PagerDuty Events API
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "routing_key": "'$PAGERDUTY_ROUTING_KEY'",
    "event_action": "trigger",
    "dedup_key": "test-event",
    "payload": {
      "summary": "Test alert",
      "severity": "info",
      "source": "test"
    }
  }' \
  "https://events.pagerduty.com/v2/enqueue"
```

**Expected:** JSON with `status: "success"`

#### P2: Check Routing Key

1. Go to PagerDuty > **Services** > Your Service > **Integrations**
2. Find **Events API v2** integration
3. Copy **Integration Key** (routing key)
4. Update `PAGERDUTY_ROUTING_KEY` secret

#### P3: Verify Alert Conditions

```yaml
# In specs.config.yaml
integrations:
  pagerduty:
    enabled: true
    alert_on:
      - "implementation_failed"  # Only alerts on these events
    severity: "warning"          # Must be: critical, error, warning, info
```

---

### Opsgenie Issues

#### Symptoms
- Alerts not appearing in Opsgenie

#### O1: Test API

```bash
# Test Opsgenie API
curl -X POST "https://api.opsgenie.com/v2/alerts" \
  -H "Content-Type: application/json" \
  -H "Authorization: GenieKey $OPSGENIE_API_KEY" \
  --data '{
    "message": "Test alert",
    "priority": "P5"
  }'
```

**Expected:** JSON with `result: "Request will be processed"`

#### O2: Check API Key Permissions

1. Go to Opsgenie > **Settings** > **API key management**
2. Verify key has **Create and Update** access
3. Regenerate if necessary

---

### Generic Webhook Issues

#### Symptoms
- Custom webhooks not receiving data
- Signature validation failures

#### W1: Test Endpoint

```bash
# Test webhook endpoint
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $WEBHOOK_TOKEN" \
  --data '{"event": "test", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' \
  "https://your-endpoint.com/webhook"
```

#### W2: Check HMAC Signature

If using secret for HMAC:
```bash
# Generate expected signature
PAYLOAD='{"event":"test"}'
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | awk '{print $2}')
echo "sha256=$SIGNATURE"
```

---

## Common Error Reference

| Error | Integration | Cause | Solution |
|-------|-------------|-------|----------|
| `401 Unauthorized` | Any | Invalid credentials | Regenerate token/key |
| `403 Forbidden` | Any | Insufficient permissions | Check scopes/permissions |
| `404 Not Found` | Teams/Slack | Webhook deleted | Regenerate webhook |
| `429 Too Many Requests` | Any | Rate limited | Implement backoff, check rate_limit config |
| `invalid_payload` | Slack | Malformed message | Check message format |
| `channel_not_found` | Slack | Wrong channel | Recreate webhook for correct channel |

## Rollback Procedure

If an integration change caused issues:

1. **Disable integration temporarily:**
   ```yaml
   # In specs.config.yaml
   integrations:
     teams:
       enabled: false  # Disable while troubleshooting
   ```

2. **Revert configuration:**
   ```bash
   git log --oneline specs.config.yaml
   git checkout <commit-sha> -- specs.config.yaml
   git commit -m "fix: Revert integration config"
   git push
   ```

## Escalation

| Condition | Escalate To | Contact |
|-----------|-------------|---------|
| Credentials compromised | Security Team | #security |
| Service-side outage | No escalation | Check service status page |
| Persistent failures | Platform Lead | #platform-support |

## Post-Incident

After resolving:

- [ ] Document which integration failed and why
- [ ] Rotate any potentially compromised credentials
- [ ] Add monitoring for the specific failure mode
- [ ] Consider adding integration health checks
- [ ] Update this runbook with new scenarios

## Service Status Pages

- **Microsoft Teams:** [status.office.com](https://status.office.com)
- **Azure DevOps:** [status.dev.azure.com](https://status.dev.azure.com)
- **Slack:** [status.slack.com](https://status.slack.com)
- **Discord:** [discordstatus.com](https://discordstatus.com)
- **PagerDuty:** [status.pagerduty.com](https://status.pagerduty.com)
- **Opsgenie:** [status.opsgenie.com](https://status.opsgenie.com)
- **GitHub:** [githubstatus.com](https://githubstatus.com)

## Related Runbooks

- [Workflow Troubleshooting](workflow-troubleshooting.md)
- [Spec Ingestion Failure](spec-ingestion-failure.md)
- [Incident Response](incident-response.md)

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2025-01-19 | Template | Initial version |
