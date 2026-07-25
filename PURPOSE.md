# dotfiles — Ubuntu Provisioning System

## Problem

Fresh Ubuntu installs require hours of manual configuration: installing packages, applying custom configurations, setting up shells, and syncing user preferences. This process is error-prone, inconsistent across machines, and impossible to automate or version control.

## Audience

Ubuntu developers and system administrators who want reproducible, declarative workstation provisioning that scales from single machines to fleet deployments without proprietary tools.

## Key Constraints

- **Declarative only:** All state expressed via YAML, no imperative setup scripts
- **Vendor-agnostic:** No dependence on SaaS or cloud-specific tooling
- **Self-contained:** All config and package lists checked into git, portable across environments
- **Minimal dependencies:** Works with only standard Ubuntu packages, no external tools required

## Success Metric

A fresh Ubuntu install provisioned from dotfiles reaches a fully configured developer environment in under 5 minutes with zero manual intervention.
