# Runbook: Cross-Platform Setup

> **Last Updated:** 2025-01-19
> **Owner:** Platform Team
> **Review Frequency:** Quarterly

## Overview

This runbook covers setting up the spec-based development environment on different operating systems and with various AI CLI tools. Use this when onboarding new team members or setting up new development machines.

## Prerequisites

- [ ] Git installed and configured
- [ ] GitHub CLI (`gh`) installed
- [ ] Code editor of choice (VS Code, Cursor, etc.)
- [ ] Account with at least one AI provider (Anthropic, OpenAI, GitHub, Sourcegraph)

## Platform-Specific Setup

### Windows (PowerShell)

#### 1. Install Package Manager

```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Or use winget (built into Windows 11)
winget --version
```

#### 2. Install Dependencies

```powershell
# Using Chocolatey
choco install nodejs-lts python git gh yq jq -y

# Or using winget
winget install OpenJS.NodeJS.LTS
winget install Python.Python.3.11
winget install GitHub.cli
winget install MikeFarah.yq
winget install jqlang.jq

# Install PowerShell YAML module
Install-Module -Name powershell-yaml -Scope CurrentUser -Force
```

#### 3. Install AI CLI (Choose One or More)

```powershell
# Claude Code
npm install -g @anthropic-ai/claude-code

# Aider
pip install aider-chat

# GitHub Copilot
gh extension install github/gh-copilot

# OpenAI CLI
pip install openai
```

#### 4. Configure Environment Variables

```powershell
# Set API keys (use your actual keys)
[Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", "your-key", "User")
[Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your-key", "User")
[Environment]::SetEnvironmentVariable("GITHUB_TOKEN", "your-token", "User")

# Verify
$env:ANTHROPIC_API_KEY
```

#### 5. Clone and Setup Repository

```powershell
# Clone repository
git clone https://github.com/your-org/your-repo.git
cd your-repo

# Verify setup
./scripts/Invoke-SpecIngestion.ps1 -ShowHelp
```

---

### macOS (Bash/Zsh)

#### 1. Install Package Manager

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Dependencies

```bash
# Core tools
brew install node python git gh yq jq

# Verify installations
node --version
python3 --version
yq --version
jq --version
```

#### 3. Install AI CLI (Choose One or More)

```bash
# Claude Code
npm install -g @anthropic-ai/claude-code

# Aider
pip3 install aider-chat

# GitHub Copilot
gh extension install github/gh-copilot

# Sourcegraph Cody
brew install sourcegraph/cody/cody
```

#### 4. Configure Environment Variables

```bash
# Add to ~/.zshrc or ~/.bashrc
export ANTHROPIC_API_KEY="your-key"
export OPENAI_API_KEY="your-key"
export GITHUB_TOKEN="your-token"
export SRC_ACCESS_TOKEN="your-sourcegraph-token"

# Reload shell
source ~/.zshrc  # or source ~/.bashrc
```

#### 5. Clone and Setup Repository

```bash
# Clone repository
git clone https://github.com/your-org/your-repo.git
cd your-repo

# Make scripts executable
chmod +x scripts/*.sh

# Verify setup
./scripts/ingest-spec.sh --help
```

---

### Linux (Ubuntu/Debian)

#### 1. Update System

```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Install Dependencies

```bash
# Core tools
sudo apt install -y curl git jq

# Node.js (via NodeSource)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Python
sudo apt install -y python3 python3-pip

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh -y

# yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

#### 3. Install AI CLI (Choose One or More)

```bash
# Claude Code
sudo npm install -g @anthropic-ai/claude-code

# Aider
pip3 install aider-chat

# GitHub Copilot
gh extension install github/gh-copilot
```

#### 4. Configure Environment Variables

```bash
# Add to ~/.bashrc
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.bashrc
echo 'export OPENAI_API_KEY="your-key"' >> ~/.bashrc
echo 'export GITHUB_TOKEN="your-token"' >> ~/.bashrc

# Reload
source ~/.bashrc
```

#### 5. Clone and Setup Repository

```bash
git clone https://github.com/your-org/your-repo.git
cd your-repo
chmod +x scripts/*.sh
./scripts/ingest-spec.sh --help
```

---

### Linux (RHEL/CentOS/Fedora)

#### 1. Install Dependencies

```bash
# Fedora
sudo dnf install -y nodejs python3 python3-pip git jq

# RHEL/CentOS (may need EPEL)
sudo dnf install -y epel-release
sudo dnf install -y nodejs python3 python3-pip git jq

# GitHub CLI
sudo dnf install -y gh

# yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

Follow steps 3-5 from Ubuntu/Debian section.

---

## AI CLI Quick Reference

| CLI | Install | API Key Variable | Test Command |
|-----|---------|------------------|--------------|
| Claude Code | `npm i -g @anthropic-ai/claude-code` | `ANTHROPIC_API_KEY` | `claude --version` |
| Aider | `pip install aider-chat` | `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` | `aider --version` |
| GitHub Copilot | `gh extension install github/gh-copilot` | `GITHUB_TOKEN` | `gh copilot --help` |
| Cody | `brew install sourcegraph/cody/cody` | `SRC_ACCESS_TOKEN` | `cody --version` |
| OpenAI CLI | `pip install openai` | `OPENAI_API_KEY` | `openai --version` |

## Verification Steps

### 1. Verify Dependencies

**Bash/Unix:**
```bash
# Run all checks
echo "Node: $(node --version)"
echo "Python: $(python3 --version)"
echo "Git: $(git --version)"
echo "yq: $(yq --version)"
echo "jq: $(jq --version)"
echo "gh: $(gh --version)"
```

**PowerShell:**
```powershell
# Run all checks
Write-Host "Node: $(node --version)"
Write-Host "Python: $(python --version)"
Write-Host "Git: $(git --version)"
Write-Host "yq: $(yq --version)"
Write-Host "jq: $(jq --version)"
Write-Host "gh: $(gh --version)"
```

### 2. Verify AI CLI

**Bash/Unix:**
```bash
# Check which AI CLIs are available
for cli in claude aider cody gpt; do
    if command -v $cli &> /dev/null; then
        echo "✓ $cli is installed"
    else
        echo "✗ $cli is not installed"
    fi
done

# Check for Copilot
if gh extension list | grep -q copilot; then
    echo "✓ GitHub Copilot is installed"
fi
```

**PowerShell:**
```powershell
# Check which AI CLIs are available
@('claude', 'aider', 'cody', 'gpt') | ForEach-Object {
    if (Get-Command $_ -ErrorAction SilentlyContinue) {
        Write-Host "✓ $_ is installed" -ForegroundColor Green
    } else {
        Write-Host "✗ $_ is not installed" -ForegroundColor Red
    }
}

# Check for Copilot
if ((gh extension list) -match 'copilot') {
    Write-Host "✓ GitHub Copilot is installed" -ForegroundColor Green
}
```

### 3. Verify API Keys

**Bash/Unix:**
```bash
# Check API keys are set (without revealing values)
for var in ANTHROPIC_API_KEY OPENAI_API_KEY GITHUB_TOKEN SRC_ACCESS_TOKEN; do
    if [ -n "${!var}" ]; then
        echo "✓ $var is set"
    else
        echo "✗ $var is not set"
    fi
done
```

**PowerShell:**
```powershell
@('ANTHROPIC_API_KEY', 'OPENAI_API_KEY', 'GITHUB_TOKEN', 'SRC_ACCESS_TOKEN') | ForEach-Object {
    if ([Environment]::GetEnvironmentVariable($_)) {
        Write-Host "✓ $_ is set" -ForegroundColor Green
    } else {
        Write-Host "✗ $_ is not set" -ForegroundColor Yellow
    }
}
```

### 4. Test Spec Processing

**Bash/Unix:**
```bash
# Dry run to test setup
DRY_RUN=true ./scripts/ingest-spec.sh --validate specs/features/_template.yaml
```

**PowerShell:**
```powershell
# Dry run to test setup
./scripts/Invoke-SpecIngestion.ps1 -Validate -ValidateFile specs/features/_template.yaml
```

## Troubleshooting

### Common Issues

| Issue | Platform | Solution |
|-------|----------|----------|
| `command not found: yq` | All | Reinstall yq, check PATH |
| `ANTHROPIC_API_KEY not set` | All | Export/set environment variable, restart terminal |
| Permission denied on scripts | Unix | Run `chmod +x scripts/*.sh` |
| PowerShell execution policy | Windows | Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Node version too old | All | Update Node.js to v18+ |
| Python module not found | All | Use `pip3` instead of `pip`, check virtual environment |

### Platform-Specific Issues

**Windows:**
```powershell
# If scripts fail with "cannot be loaded because running scripts is disabled"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# If npm packages fail to install globally
npm config set prefix "$env:APPDATA\npm"
```

**macOS:**
```bash
# If Homebrew commands fail after macOS upgrade
brew update && brew doctor

# If Python packages install to wrong location
python3 -m pip install --user aider-chat
```

**Linux:**
```bash
# If npm global install requires sudo (bad practice)
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## IDE Integration

### VS Code

```json
// .vscode/settings.json
{
    "terminal.integrated.defaultProfile.windows": "PowerShell",
    "terminal.integrated.defaultProfile.linux": "bash",
    "terminal.integrated.defaultProfile.osx": "zsh"
}
```

### Cursor

Create `.cursorrules` in project root for Cursor-specific instructions.

### JetBrains IDEs

Configure terminal to use appropriate shell in Settings → Tools → Terminal.

## Post-Incident

After resolving setup issues:

- [ ] Document any new issues encountered
- [ ] Update this runbook if steps changed
- [ ] Share solutions with team
- [ ] Consider automating problematic steps

## Related Runbooks

- [Workflow Troubleshooting](workflow-troubleshooting.md)
- [Integration Issues](integration-issues.md)
- [Spec Ingestion Failure](spec-ingestion-failure.md)

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2025-01-19 | Template | Initial version with cross-platform support |
