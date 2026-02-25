# Runbooks

This directory contains operational runbooks for managing and troubleshooting the spec-based development system.

## What is a Runbook?

A runbook is a documented procedure for handling operational tasks and incidents. Good runbooks:
- Provide step-by-step instructions
- Include diagnostic commands
- Define escalation paths
- Are regularly tested and updated

## Available Runbooks

| Runbook | Description | When to Use |
|---------|-------------|-------------|
| [Spec Ingestion Failures](spec-ingestion-failure.md) | Troubleshoot failed spec processing | Workflow fails to process specs |
| [Workflow Troubleshooting](workflow-troubleshooting.md) | Debug GitHub Actions issues | CI/CD pipeline problems |
| [Integration Issues](integration-issues.md) | Fix integration connectivity | Slack/Teams/Jira not working |
| [Incident Response](incident-response.md) | Handle production incidents | System outages or critical bugs |

## Runbook Template

Use [_template.md](_template.md) when creating new runbooks.

## Maintenance

Runbooks should be:
- Reviewed quarterly
- Updated after each incident (lessons learned)
- Tested in staging environment
- Version controlled alongside code

## On-Call Information

| Role | Contact | Escalation |
|------|---------|------------|
| Primary | [TODO: Configure] | Slack: #on-call |
| Secondary | [TODO: Configure] | Email: oncall@example.com |
| Manager | [TODO: Configure] | Phone: [TODO] |

## Related Documentation

- [Spec-Based Development Guide](../spec-based-development.md)
- [Integration Guide](../integrations.md)
- [Security Policy](../../SECURITY.md)
