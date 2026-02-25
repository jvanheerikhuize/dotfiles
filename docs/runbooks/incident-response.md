# Runbook: Incident Response

> **Last Updated:** 2025-01-19
> **Owner:** Platform Team
> **Review Frequency:** Quarterly

## Overview

This runbook provides the standard incident response procedure for production incidents affecting the spec-based development system.

## Prerequisites

- [ ] Access to monitoring dashboards
- [ ] Access to communication channels (Slack/Teams)
- [ ] On-call rotation contact list
- [ ] Admin access to GitHub repository

## Severity Definitions

| Level | Name | Criteria | Response Time | Examples |
|-------|------|----------|---------------|----------|
| SEV1 | Critical | Complete system outage, data loss, security breach | Immediate | All workflows failing, secrets exposed |
| SEV2 | High | Major feature unavailable, significant user impact | 15 min | Spec ingestion broken, integrations down |
| SEV3 | Medium | Degraded performance, partial functionality loss | 1 hour | Slow processing, intermittent failures |
| SEV4 | Low | Minor issue, workaround available | 4 hours | UI glitch, non-critical error |

## Incident Response Process

### Phase 1: Detection & Triage (0-5 minutes)

1. **Acknowledge the alert**
   - Respond in #incidents channel: "Investigating [brief description]"
   - Create incident issue using the [Incident Report template](/.github/ISSUE_TEMPLATE/incident-report.yaml)

2. **Assess severity**
   - Use severity matrix above
   - When in doubt, escalate up (SEV2 → SEV1)

3. **Assemble response team** (SEV1/SEV2)
   - Page on-call engineer
   - Notify team lead
   - Open incident bridge (video call link)

### Phase 2: Investigation (5-30 minutes)

1. **Gather information**
   ```bash
   # Check recent deployments
   git log --oneline -10

   # Check workflow status
   gh run list --workflow=spec-ingestion.yml --limit=5

   # Check recent PRs
   gh pr list --state=merged --limit=5
   ```

2. **Check monitoring**
   - GitHub Actions dashboard
   - Integration status (Slack, Teams, etc.)
   - API rate limits

3. **Identify scope**
   - What's affected?
   - How many users/specs impacted?
   - When did it start?

4. **Document timeline**
   Update incident issue with:
   ```
   - HH:MM UTC - [Event description]
   - HH:MM UTC - [Event description]
   ```

### Phase 3: Mitigation (30-60 minutes)

1. **Implement immediate fix**
   - Prefer quick mitigation over perfect solution
   - Options:
     - Revert recent change
     - Disable problematic feature
     - Switch to backup/fallback

2. **Communicate status**
   - Update #incidents channel every 15 minutes
   - Update status page (if applicable)
   - Notify stakeholders

3. **Verify mitigation**
   ```bash
   # Test spec processing
   ./scripts/ingest-spec.sh --validate specs/features/test-spec.yaml

   # Check workflow
   gh workflow run spec-ingestion.yml
   ```

### Phase 4: Resolution

1. **Confirm resolution**
   - All symptoms resolved
   - Monitoring shows normal behavior
   - Test transactions successful

2. **Update communications**
   - #incidents: "Incident resolved. [brief summary]"
   - Status page: "Resolved"
   - Close incident bridge

3. **Update incident issue**
   - Resolution time
   - Root cause (if known)
   - Actions taken

### Phase 5: Post-Incident (within 48 hours)

1. **Schedule post-mortem** (SEV1/SEV2)
   - Within 48 hours of resolution
   - Include all responders
   - Blameless culture

2. **Write post-mortem document**
   ```markdown
   ## Incident Summary
   - Duration:
   - Impact:
   - Root cause:

   ## Timeline
   [Detailed timeline]

   ## What went well
   -

   ## What could be improved
   -

   ## Action items
   - [ ] [Action] - Owner - Due date
   ```

3. **Create follow-up tickets**
   - Preventive measures
   - Monitoring improvements
   - Documentation updates

## Communication Templates

### Initial Acknowledgment
```
🔴 INCIDENT: [Brief description]
Severity: SEV[X]
Status: Investigating
Impact: [Who/what is affected]
Updates will follow every 15 minutes.
```

### Status Update
```
🟡 UPDATE: [Incident name]
Status: [Investigating/Identified/Monitoring]
Current situation: [Brief update]
Next update: [Time]
```

### Resolution
```
🟢 RESOLVED: [Incident name]
Duration: [X hours Y minutes]
Resolution: [Brief description of fix]
Post-mortem scheduled for [date/time]
```

## Escalation Contacts

| Role | Name | Contact | When to Escalate |
|------|------|---------|------------------|
| On-Call Primary | [TODO] | [Slack/Phone] | First responder |
| On-Call Secondary | [TODO] | [Slack/Phone] | Primary unavailable |
| Team Lead | [TODO] | [Slack/Phone] | SEV1/SEV2, >30 min |
| Engineering Manager | [TODO] | [Slack/Phone] | SEV1, >1 hour |
| Security | [TODO] | security@example.com | Security incidents |

## Incident Commander Responsibilities

For SEV1/SEV2 incidents, designate an Incident Commander (IC):

- [ ] Coordinate response efforts
- [ ] Manage communications
- [ ] Make decisions on mitigation approach
- [ ] Ensure documentation
- [ ] Delegate tasks to responders
- [ ] Call for additional help when needed

## Common Scenarios

### All Workflows Failing (SEV1)

1. Check GitHub status: https://www.githubstatus.com/
2. Check if issue is repository-specific or org-wide
3. Verify secrets are intact
4. Check for recent workflow file changes

### API Rate Limits (SEV2)

1. Check Anthropic API status
2. Review API usage
3. Implement rate limiting if needed
4. Consider API key rotation

### Integration Outage (SEV3)

1. Check third-party service status
2. Verify webhook URLs
3. Test connectivity
4. Enable fallback notifications

## Tools and Resources

| Tool | Purpose | Link |
|------|---------|------|
| GitHub Status | Check GitHub availability | https://www.githubstatus.com |
| Anthropic Status | Check API availability | https://status.anthropic.com |
| Incident Bridge | Video call for response | [TODO: Configure] |
| Runbooks | Detailed procedures | `/docs/runbooks/` |

## Post-Mortem Template Location

See: `/docs/templates/post-mortem.md` (create if needed)

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2025-01-19 | Template | Initial version |
