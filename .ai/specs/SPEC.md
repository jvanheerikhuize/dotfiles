# Product Specification — dotfiles

> **For AI Assistants**: This document defines WHAT the product does. For HOW it's built, see `../architecture/ARCHITECTURE.md`.

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Status | Active |
| Last Updated | 2026-02-25 |
| Owner | Jerry |

---

## 1. Product Overview

### 1.1 Vision

`dotfiles` enables a developer to go from a fresh Ubuntu install to a fully configured, personalised machine in a single command, repeatably and reliably.

### 1.2 Problem Statement

**Current State**: After Stage 1 (Autoinstall.yaml), Ubuntu is installed but bare. Every new machine or reinstall requires manually installing tools, configuring shell environments, and copying config files — a slow, inconsistent, and error-prone process.

**Impact**: Each new machine setup takes hours and produces subtly different results, making it hard to reproduce a known-good environment.

**Root Cause**: No single source of truth for what tools and configs belong on a machine, and no automated way to apply them.

### 1.3 Solution Summary

`dotfiles` solves this by:
1. Declaring all packages and config files in version-controlled YAML profiles
2. Providing a single `./install.sh` entrypoint that applies everything
3. Supporting role-based profiles (base → desktop → dev) so different machine types get the right set of tools
4. Managing dotfiles as symlinks back to the repo, so config changes are tracked in git

---

## 2. Users & Personas

### 2.1 Target Users

| Persona | Description | Primary Goal |
|---------|-------------|--------------|
| Developer (Jerry) | Linux power user setting up a workstation | Full dev environment in one command |
| Sysadmin (Jerry) | Setting up a headless server | Minimal server tools, no desktop cruft |

### 2.2 User Journey

```
[Stage 1 complete] → [git clone dotfiles] → [./install.sh --profile dev] → [Configured machine]
```

---

## 3. Functional Requirements

### Feature: Core Provisioning Engine
- **Spec**: `specs/features/FEAT-0001-core-provisioning-engine.yaml`
- **Status**: Approved
- **Priority**: Critical
- **Description**: `install.sh` entrypoint + YAML profile loading + apt package installation + profile inheritance + dotfile symlinking
- **Acceptance Criteria**: See FEAT-0001 spec

### Feature: Multi-Type Package Support
- **Spec**: `specs/features/FEAT-0002-multi-type-packages.yaml` *(pending)*
- **Status**: Draft
- **Priority**: High
- **Description**: Extend the package installer to support snap, flatpak, direct .deb URLs, and custom install scripts
- **Depends on**: FEAT-0001

### Feature: Dotfile Content — Base Shell
- **Spec**: `specs/features/FEAT-0003-base-shell-dotfiles.yaml` *(pending)*
- **Status**: Draft
- **Priority**: High
- **Description**: Actual dotfile content: `.bashrc`, `.bash_aliases`, `.gitconfig`, `.vimrc` for the base profile

### Feature: Smoke Test Suite
- **Spec**: `specs/features/FEAT-0004-smoke-tests.yaml` *(pending)*
- **Status**: Draft
- **Priority**: Medium
- **Description**: Docker-based smoke tests that run `install.sh --profile base` against a clean Ubuntu 22.04 container and verify the result

### 3.2 Feature Roadmap

| Phase | Features | Target |
|-------|----------|--------|
| v1.0 | FEAT-0001 core engine | Current |
| v1.1 | FEAT-0002 multi-type packages, FEAT-0003 shell dotfiles, FEAT-0005 dry run, FEAT-0006 validation, FEAT-0007 run summary, FEAT-0008 git identity, FEAT-0012 log to file, FEAT-0014 connectivity check | Next |
| v1.2 | FEAT-0004 smoke tests, FEAT-0009 SSH key, FEAT-0010 fonts, FEAT-0011 GNOME dconf, FEAT-0013 status diff | Future |

---

## 4. Non-Functional Requirements

### 4.1 Reliability
| Requirement | Target |
|-------------|--------|
| Idempotency | Running install.sh N times = same result as running it once |
| Fail behaviour | Exit non-zero immediately on any error; never silently continue |
| Partial runs | Packages installed before a failure stay installed (no rollback) |

### 4.2 Compatibility
- **OS**: Ubuntu 22.04 LTS and later
- **Shell**: bash 5.x
- **Dependencies**: Only tools available on a default Ubuntu 22.04 install (git, python3, apt)

### 4.3 Security
- No credentials or secrets stored in the repo
- `sudo` only for package operations, not the whole script
- Dotfiles only written to `$HOME`
- Custom scripts must be reviewed before being added to a profile

---

## 5. Constraints & Assumptions

### 5.1 Constraints
- **Bash only**: No Python, Ruby, or Node runtimes for the installer itself
- **Ubuntu only**: No macOS or Windows support
- **Stage 1 prerequisite**: Assumes Ubuntu is already installed and git is present

### 5.2 Assumptions
- Internet access is available when running the installer
- The user running install.sh has sudo privileges
- python3 is available for YAML parsing (true on Ubuntu 22.04 default)

---

## 6. Out of Scope

- Windows or macOS support
- GUI configuration (GNOME settings, dconf, etc.) — future spec
- Secret/credential management (SSH keys, GPG keys) — future spec
- Automatic updates or drift detection — future spec
- Network/firewall configuration — handled in Stage 1

---

## 7. Success Metrics

| Metric | Target |
|--------|--------|
| Time to configured machine (post Stage 1) | < 15 minutes unattended |
| Number of manual steps required | 2 (git clone + ./install.sh) |
| Idempotency | Zero errors on second run |
| Profile coverage | base, desktop, server, dev all defined and tested |

---

## 8. Glossary

| Term | Definition |
|------|------------|
| Stage 1 | Unattended Ubuntu OS install via Autoinstall.yaml |
| Stage 2 | Post-boot provisioning — this repo |
| Profile | A named YAML file declaring which packages and configs to apply |
| Dotfile | A `$HOME`-level config file (e.g. `.bashrc`, `.gitconfig`) |
| Symlink | A pointer from `$HOME/<file>` back to `<repo>/dotfiles/<file>` |
| Idempotent | Safe to run multiple times; same result each time |

---

## Appendix

### A. Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-25 | Jerry | Initial product spec for dotfiles provisioning system |
