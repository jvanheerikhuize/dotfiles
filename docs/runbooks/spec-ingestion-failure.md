# Runbook: Spec Ingestion Failure

> **Last Updated:** 2025-01-19
> **Owner:** Platform Team
> **Review Frequency:** Quarterly

## Overview

This runbook covers troubleshooting when the spec ingestion workflow fails to process specifications. Use this when specs aren't being automatically implemented or when the GitHub Actions workflow fails.

## Prerequisites

- [ ] Access to GitHub repository
- [ ] Ability to view GitHub Actions logs
- [ ] Access to repository secrets (for admins)
- [ ] `yq` and `jq` installed locally

## Symptoms

- GitHub Actions workflow shows failed status
- Approved specs not being processed
- No PR created after spec approval
- Error notifications in Slack/Teams
- Spec status stuck at "approved"

## Impact Assessment

| Severity | Criteria | Response Time |
|----------|----------|---------------|
| SEV3 | Single spec failing | 1 hour |
| SEV2 | All specs failing | 15 minutes |
| SEV1 | Workflow completely broken | Immediate |

## Diagnostic Steps

### Step 1: Check Workflow Status

1. Go to **Actions** tab in GitHub repository
2. Find the **Spec Ingestion** workflow
3. Check recent runs for failures

**If workflow not running at all:** Go to [Workflow Not Triggering](#scenario-a-workflow-not-triggering)
**If workflow fails during execution:** Go to [Workflow Execution Failure](#scenario-b-workflow-execution-failure)

### Step 2: Check Workflow Logs

Click on the failed run and examine logs for each step:

- **validate** job: Schema/YAML validation issues
- **implement** job: Claude Code or git issues
- **summary** job: Notification issues

### Step 3: Local Validation

```bash
# Validate spec locally
./scripts/ingest-spec.sh --validate specs/features/FEAT-XXXX.yaml

# Check YAML syntax
yq e '.' specs/features/FEAT-XXXX.yaml

# Verify schema compliance
yq e -o=json specs/features/FEAT-XXXX.yaml | \
  ajv validate -s specs/schemas/feature-spec.schema.json -d /dev/stdin
```

## Resolution Steps

### Scenario A: Workflow Not Triggering

**Symptoms:** No workflow runs appear after push/approval

1. **Check spec status:**
   ```yaml
   # In specs.config.yaml, verify:
   status: "approved"      # Must be "approved"
   auto_implement: true    # Must be true
   ```

2. **Check workflow triggers:**
   ```yaml
   # In .github/workflows/spec-ingestion.yml
   on:
     push:
       paths:
         - "specs/**/*.yaml"  # Verify path matches
   ```

3. **Check branch:**
   - Workflow only runs on `main` branch (by default)
   - Ensure you're pushing to correct branch

4. **Verify workflow is enabled:**
   - Go to Actions > Spec Ingestion
   - Check if workflow is disabled (enable if needed)

### Scenario B: Workflow Execution Failure

**Symptoms:** Workflow runs but fails during execution

#### B1: Validation Failure

```
Error: Schema validation failed for specs/features/FEAT-XXXX.yaml
```

**Resolution:**
1. Check the specific validation error in logs
2. Fix the spec file:
   ```bash
   # Common issues:
   # - Missing required field (id, title, status)
   # - Invalid status value
   # - Missing acceptance criteria

   # Validate and see errors:
   ./scripts/ingest-spec.sh --validate specs/features/FEAT-XXXX.yaml
   ```
3. Commit and push the fix

#### B2: API Key Missing

```
Error: ANTHROPIC_API_KEY environment variable is not set
```

**Resolution:**
1. Go to repository **Settings > Secrets and variables > Actions**
2. Verify `ANTHROPIC_API_KEY` secret exists
3. If missing, add it with valid API key
4. Re-run the workflow

#### B3: Claude Code Failure

```
Error: Claude Code execution failed
```

**Resolution:**
1. Check Claude Code output in logs for specific error
2. Verify API key is valid and has credits
3. Check if spec is too complex (simplify if needed)
4. Try running locally:
   ```bash
   export ANTHROPIC_API_KEY="your-key"
   ./scripts/ingest-spec.sh specs/features/FEAT-XXXX.yaml
   ```

#### B4: Git/GitHub Failure

```
Error: Failed to push branch
Error: Failed to create PR
```

**Resolution:**
1. Check if branch already exists:
   ```bash
   git branch -r | grep spec/FEAT-XXXX
   ```
2. Delete existing branch if stale:
   ```bash
   git push origin --delete spec/FEAT-XXXX
   ```
3. Check GitHub token permissions:
   - `GITHUB_TOKEN` needs `contents: write` and `pull-requests: write`
4. Re-run workflow

### Scenario C: Partial Success

**Symptoms:** Some specs process, others fail

1. **Check individual spec files:**
   ```bash
   for spec in specs/features/*.yaml; do
     echo "Validating: $spec"
     ./scripts/ingest-spec.sh --validate "$spec"
   done
   ```

2. **Check specs.config.yaml:**
   - Ensure file paths are correct
   - Verify status is "approved" for intended specs

3. **Check for conflicts:**
   - PR already exists for this spec
   - Branch name collision

## Rollback Procedure

If a bad implementation was merged:

1. **Revert the PR:**
   ```bash
   git revert -m 1 <merge-commit-sha>
   git push origin main
   ```

2. **Reset spec status:**
   ```yaml
   # In spec file, change:
   status: "approved"  # Reset from "implemented"
   ```

3. **Delete feature branch:**
   ```bash
   git push origin --delete spec/FEAT-XXXX
   ```

## Escalation

| Condition | Escalate To | Contact |
|-----------|-------------|---------|
| API key issues | Platform Admin | #platform-support |
| Repeated failures | Tech Lead | @tech-lead |
| Security concerns | Security Team | security@example.com |

## Post-Incident

After resolving:

- [ ] Document root cause
- [ ] Update this runbook if new scenario found
- [ ] Consider adding monitoring/alerting for this failure mode
- [ ] Create follow-up ticket for systemic fixes

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `Invalid YAML syntax` | Malformed YAML | Fix indentation/syntax |
| `Missing required field: metadata.id` | Incomplete spec | Add missing field |
| `Spec ID not found in config` | Not in specs.config.yaml | Add spec to config |
| `Rate limit exceeded` | Too many API calls | Wait and retry |
| `Branch already exists` | Previous run didn't clean up | Delete branch manually |

## Related Runbooks

- [Workflow Troubleshooting](workflow-troubleshooting.md)
- [Integration Issues](integration-issues.md)

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2025-01-19 | Template | Initial version |
