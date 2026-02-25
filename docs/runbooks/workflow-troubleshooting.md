# Runbook: Workflow Troubleshooting

> **Last Updated:** 2025-01-19
> **Owner:** Platform Team
> **Review Frequency:** Quarterly

## Overview

This runbook covers troubleshooting GitHub Actions workflow issues including failures, stuck runs, and configuration problems. Use this when CI/CD pipelines are not behaving as expected.

## Prerequisites

- [ ] Access to GitHub repository
- [ ] Ability to view GitHub Actions logs
- [ ] Repository admin access (for workflow management)
- [ ] `gh` CLI installed locally

## Symptoms

- Workflows not triggering on expected events
- Workflows stuck in "Queued" or "In Progress" state
- Jobs failing with unclear errors
- Workflow runs completing but not producing expected results
- Notifications not being sent

## Impact Assessment

| Severity | Criteria | Response Time |
|----------|----------|---------------|
| SEV1 | All workflows broken | Immediate |
| SEV2 | Critical workflow failing | 15 minutes |
| SEV3 | Non-critical workflow failing | 1 hour |
| SEV4 | Minor workflow issues | Next business day |

## Diagnostic Steps

### Step 1: Check Workflow Status

```bash
# List recent workflow runs
gh run list --limit 10

# Check specific workflow
gh run list --workflow spec-ingestion.yml --limit 5
```

**If no runs appear:** Go to [Workflow Not Triggering](#scenario-a-workflow-not-triggering)
**If runs fail:** Go to [Workflow Execution Failure](#scenario-b-workflow-execution-failure)
**If runs stuck:** Go to [Workflow Stuck](#scenario-c-workflow-stuck)

### Step 2: View Workflow Logs

```bash
# View logs for a specific run
gh run view <run-id> --log

# View failed jobs only
gh run view <run-id> --log-failed
```

### Step 3: Check Workflow Configuration

```bash
# Validate workflow YAML syntax
yq e '.' .github/workflows/spec-ingestion.yml

# List all workflows
ls -la .github/workflows/
```

## Resolution Steps

### Scenario A: Workflow Not Triggering

**Symptoms:** Expected workflow doesn't run after push/PR/manual trigger

#### A1: Check Workflow File Location

```bash
# Workflows must be in .github/workflows/
ls .github/workflows/

# Verify file has .yml or .yaml extension
# Verify file is on the default branch (main)
```

#### A2: Check Trigger Configuration

```yaml
# Common trigger issues in workflow file:
on:
  push:
    branches:
      - main        # Only triggers on main branch
    paths:
      - "specs/**"  # Only triggers when these paths change

  workflow_dispatch:  # Must be present for manual triggers
```

**Fix:**
1. Ensure triggers match your use case
2. Verify branch names are correct
3. Check path patterns match actual file paths

#### A3: Check Workflow Is Enabled

1. Go to **Actions** tab in repository
2. Click on the workflow name in left sidebar
3. If disabled, click "Enable workflow" button

```bash
# Enable workflow via CLI
gh workflow enable spec-ingestion.yml
```

#### A4: Check Repository Permissions

1. Go to **Settings > Actions > General**
2. Verify "Actions permissions" allows workflow to run
3. Check "Workflow permissions" has required access

### Scenario B: Workflow Execution Failure

**Symptoms:** Workflow triggers but jobs fail

#### B1: Syntax/Configuration Errors

```
Error: .github/workflows/spec-ingestion.yml: Invalid workflow file
```

**Resolution:**
```bash
# Validate YAML syntax
yq e '.' .github/workflows/spec-ingestion.yml

# Common fixes:
# - Fix indentation (use 2 spaces)
# - Quote strings with special characters
# - Check for missing colons or dashes
```

#### B2: Missing Secrets

```
Error: Context access might be invalid: ANTHROPIC_API_KEY
```

**Resolution:**
1. Go to **Settings > Secrets and variables > Actions**
2. Add missing secret
3. Ensure secret name matches workflow reference (case-sensitive)

```bash
# Check if secret is referenced correctly in workflow
grep -r "secrets\." .github/workflows/
```

#### B3: Permission Errors

```
Error: Resource not accessible by integration
Error: Permission denied
```

**Resolution:**
```yaml
# Add permissions to workflow file:
permissions:
  contents: write
  pull-requests: write
  issues: read
```

Or update repository settings:
1. **Settings > Actions > General**
2. Under "Workflow permissions", select "Read and write permissions"

#### B4: Runner Issues

```
Error: No runners available
Error: Runner connection timeout
```

**Resolution:**
1. Check GitHub Status page for outages
2. Verify `runs-on` uses valid runner:
   ```yaml
   runs-on: ubuntu-latest  # Recommended
   ```
3. If using self-hosted runners, check runner status

### Scenario C: Workflow Stuck

**Symptoms:** Workflow run in "Queued" or "In Progress" for extended time

#### C1: Concurrency Issues

```yaml
# Add concurrency control to workflow:
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

#### C2: Cancel and Re-run

```bash
# Cancel stuck run
gh run cancel <run-id>

# Re-run workflow
gh run rerun <run-id>
```

#### C3: Check Dependent Jobs

```yaml
# Ensure job dependencies are correct:
jobs:
  build:
    runs-on: ubuntu-latest

  test:
    needs: build  # Only runs after build completes
```

### Scenario D: Notification Workflow Issues

**Symptoms:** notify-integrations.yml not sending notifications

1. **Check integration is enabled:**
   ```yaml
   # In specs.config.yaml
   integrations:
     slack:
       enabled: true  # Must be true
   ```

2. **Verify secrets are configured:**
   - `SLACK_WEBHOOK_URL`
   - `TEAMS_WEBHOOK_URL`
   - `DISCORD_WEBHOOK_URL`

3. **Test webhook manually:**
   ```bash
   # Test Slack webhook
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"Test message"}' \
     "$SLACK_WEBHOOK_URL"
   ```

4. **Check workflow_call inputs:**
   ```yaml
   # Ensure calling workflow passes all required inputs
   uses: ./.github/workflows/notify-integrations.yml
   with:
     event: "implementation_completed"
     spec_id: "FEAT-0001"
   ```

## Rollback Procedure

If a workflow change caused issues:

1. **Revert workflow file:**
   ```bash
   git log --oneline .github/workflows/
   git checkout <commit-sha> -- .github/workflows/
   git commit -m "fix: Revert workflow to working version"
   git push
   ```

2. **Cancel any broken runs:**
   ```bash
   gh run list --status=in_progress | awk '{print $7}' | xargs -I {} gh run cancel {}
   ```

## Escalation

| Condition | Escalate To | Contact |
|-----------|-------------|---------|
| All workflows failing | Platform Lead | #platform-support |
| GitHub Actions outage | No escalation | Check status.github.com |
| Security concerns | Security Team | #security |

## Post-Incident

After resolving:

- [ ] Document root cause in incident ticket
- [ ] Update workflow with better error handling if needed
- [ ] Add workflow status badge to README if not present
- [ ] Consider adding workflow tests
- [ ] Update this runbook with new scenarios

## Useful Commands Reference

```bash
# List workflows
gh workflow list

# View workflow definition
gh workflow view spec-ingestion.yml

# Run workflow manually
gh workflow run spec-ingestion.yml

# List runs with status filter
gh run list --status=failure

# Download run logs
gh run download <run-id>

# Watch a run in progress
gh run watch <run-id>
```

## Related Runbooks

- [Spec Ingestion Failure](spec-ingestion-failure.md)
- [Integration Issues](integration-issues.md)
- [Incident Response](incident-response.md)

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2025-01-19 | Template | Initial version |
