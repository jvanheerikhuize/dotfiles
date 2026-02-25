# Runbook: [Title]

> **Last Updated:** YYYY-MM-DD
> **Owner:** [Team/Person]
> **Review Frequency:** Quarterly

## Overview

Brief description of what this runbook covers and when to use it.

## Prerequisites

- [ ] Access to [system/tool]
- [ ] Permissions: [required permissions]
- [ ] Tools installed: [list tools]

## Symptoms

How do you know you need this runbook?

- Symptom 1: [Description]
- Symptom 2: [Description]
- Error message: `[exact error text]`

## Impact Assessment

| Severity | Criteria | Response Time |
|----------|----------|---------------|
| SEV1 | [Complete outage] | Immediate |
| SEV2 | [Major feature down] | 15 minutes |
| SEV3 | [Degraded performance] | 1 hour |
| SEV4 | [Minor issue] | Next business day |

## Diagnostic Steps

### Step 1: [Initial Assessment]

```bash
# Command to check status
[diagnostic command]
```

**Expected output:** [what you should see]

**If output shows X:** Go to [section]
**If output shows Y:** Go to [other section]

### Step 2: [Further Investigation]

```bash
# Additional diagnostic commands
[command]
```

## Resolution Steps

### Scenario A: [Problem Type]

1. **Step 1:** [Action]
   ```bash
   [command]
   ```

2. **Step 2:** [Action]
   ```bash
   [command]
   ```

3. **Verify:** [How to confirm fix]
   ```bash
   [verification command]
   ```

### Scenario B: [Different Problem Type]

1. [Steps for this scenario]

## Rollback Procedure

If the fix doesn't work or causes additional issues:

1. [Rollback step 1]
2. [Rollback step 2]
3. [Verify rollback]

## Escalation

| Condition | Escalate To | Contact |
|-----------|-------------|---------|
| Issue persists > 30 min | [Team Lead] | [contact] |
| Data loss suspected | [Security Team] | [contact] |
| Customer impact | [Support Lead] | [contact] |

## Post-Incident

After resolving the incident:

- [ ] Update incident ticket with resolution
- [ ] Notify stakeholders
- [ ] Schedule post-mortem (if SEV1/SEV2)
- [ ] Update this runbook with lessons learned
- [ ] Create follow-up tickets for improvements

## Related Runbooks

- [Related Runbook 1](link)
- [Related Runbook 2](link)

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| YYYY-MM-DD | [Name] | Initial version |
