<#
.SYNOPSIS
    Spec Ingestion Script (PowerShell/Cross-Platform)
    Processes specification files and triggers AI CLI for implementation

.DESCRIPTION
    This script processes specification files and uses AI CLI tools to implement features.
    Supports multiple AI CLIs: Claude Code, Aider, GitHub Copilot, Cody, and custom commands.
    Works on Windows, macOS, and Linux with PowerShell 7+.

.PARAMETER SpecFile
    Path to a single specification file to process

.PARAMETER Config
    Process specs from configuration file (default: specs.config.yaml)

.PARAMETER ConfigFile
    Path to configuration file (used with -Config)

.PARAMETER Validate
    Validate spec file without processing

.PARAMETER AiCli
    Force specific AI CLI (claude, aider, copilot, cody, gpt, custom)

.PARAMETER AiCliCommand
    Custom CLI command (when -AiCli is 'custom')

.PARAMETER DryRun
    Show what would be done without making changes

.PARAMETER Verbose
    Enable verbose output

.EXAMPLE
    ./Invoke-SpecIngestion.ps1 -SpecFile specs/features/FEAT-0001.yaml

.EXAMPLE
    ./Invoke-SpecIngestion.ps1 -Config

.EXAMPLE
    ./Invoke-SpecIngestion.ps1 -SpecFile specs/features/FEAT-0001.yaml -AiCli aider

.EXAMPLE
    ./Invoke-SpecIngestion.ps1 -Validate -SpecFile specs/features/FEAT-0001.yaml
#>

[CmdletBinding(DefaultParameterSetName = 'SpecFile')]
param(
    [Parameter(ParameterSetName = 'SpecFile', Position = 0)]
    [string]$SpecFile,

    [Parameter(ParameterSetName = 'Config')]
    [switch]$Config,

    [Parameter(ParameterSetName = 'Config')]
    [string]$ConfigFile = "specs.config.yaml",

    [Parameter(ParameterSetName = 'Validate')]
    [switch]$Validate,

    [Parameter(ParameterSetName = 'Validate', Mandatory = $true)]
    [string]$ValidateFile,

    [ValidateSet('claude', 'aider', 'copilot', 'cody', 'gpt', 'custom', 'auto')]
    [string]$AiCli = 'auto',

    [string]$AiCliCommand,

    [switch]$DryRun,

    [switch]$ShowHelp
)

# Script configuration
$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SpecsConfigPath = Join-Path $ProjectRoot $ConfigFile

# Color output helper
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Level = 'Info'
    )

    $colors = @{
        'Info'    = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
        'Debug'   = 'Gray'
    }

    $prefix = @{
        'Info'    = '[INFO]'
        'Success' = '[SUCCESS]'
        'Warning' = '[WARN]'
        'Error'   = '[ERROR]'
        'Debug'   = '[DEBUG]'
    }

    Write-Host "$($prefix[$Level]) $Message" -ForegroundColor $colors[$Level]
}

function Write-Log {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Level 'Info'
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Level 'Success'
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Level 'Warning'
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput -Message $Message -Level 'Error'
}

function Write-Debug {
    param([string]$Message)
    if ($VerbosePreference -eq 'Continue' -or $PSBoundParameters['Verbose']) {
        Write-ColorOutput -Message $Message -Level 'Debug'
    }
}

# Detect available AI CLI
function Get-AiCli {
    if ($AiCli -ne 'auto') {
        return $AiCli
    }

    $cliOptions = @('claude', 'aider', 'gh', 'cody', 'gpt')

    foreach ($cli in $cliOptions) {
        if (Get-Command $cli -ErrorAction SilentlyContinue) {
            if ($cli -eq 'gh') {
                # Check if copilot extension is installed
                $extensions = gh extension list 2>$null
                if ($extensions -match 'copilot') {
                    return 'copilot'
                }
            }
            else {
                return $cli
            }
        }
    }

    return 'none'
}

# Get API key environment variable name
function Get-ApiKeyVar {
    param([string]$Cli)

    switch ($Cli) {
        'claude'  { return 'ANTHROPIC_API_KEY' }
        'aider'   { return 'OPENAI_API_KEY' }
        'gpt'     { return 'OPENAI_API_KEY' }
        'copilot' { return 'GITHUB_TOKEN' }
        'cody'    { return 'SRC_ACCESS_TOKEN' }
        default   { return 'AI_API_KEY' }
    }
}

# Check dependencies
function Test-Dependencies {
    $missingDeps = @()

    # Check for PowerShell-yaml module or yq
    $hasYaml = $false
    if (Get-Module -ListAvailable -Name powershell-yaml) {
        $hasYaml = $true
        Import-Module powershell-yaml -ErrorAction SilentlyContinue
    }
    elseif (Get-Command yq -ErrorAction SilentlyContinue) {
        $hasYaml = $true
    }

    if (-not $hasYaml) {
        $missingDeps += "powershell-yaml module (Install-Module powershell-yaml) or yq CLI"
    }

    # Detect AI CLI
    $script:DetectedCli = Get-AiCli

    if ($script:DetectedCli -eq 'none' -and $AiCli -ne 'custom') {
        $missingDeps += "AI CLI (claude, aider, copilot, cody, or gpt)"
    }

    if ($missingDeps.Count -gt 0) {
        Write-Error "Missing dependencies:"
        foreach ($dep in $missingDeps) {
            Write-Host "  - $dep"
        }
        Write-Host ""
        Write-Host "Install an AI CLI:"
        Write-Host "  - Claude Code:    npm install -g @anthropic-ai/claude-code"
        Write-Host "  - Aider:          pip install aider-chat"
        Write-Host "  - GitHub Copilot: gh extension install github/gh-copilot"
        Write-Host "  - Cody:           See https://sourcegraph.com/docs/cody"
        throw "Missing dependencies"
    }

    # Check API key
    $apiKeyVar = Get-ApiKeyVar -Cli $script:DetectedCli
    $apiKey = [Environment]::GetEnvironmentVariable($apiKeyVar)

    if ([string]::IsNullOrEmpty($apiKey) -and $script:DetectedCli -ne 'copilot') {
        Write-Warning "$apiKeyVar environment variable is not set"
        Write-Log "Some AI CLIs may use different authentication methods"
    }

    Write-Debug "Using AI CLI: $($script:DetectedCli)"
}

# Read YAML file
function Read-YamlFile {
    param([string]$Path)

    if (Get-Module -Name powershell-yaml) {
        return Get-Content $Path -Raw | ConvertFrom-Yaml
    }
    else {
        # Fallback to yq
        $json = yq -o=json $Path
        return $json | ConvertFrom-Json
    }
}

# Validate spec file
function Test-SpecFile {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Error "Spec file not found: $Path"
        return $false
    }

    Write-Log "Validating spec: $Path"

    $ext = [System.IO.Path]::GetExtension($Path).TrimStart('.')
    if ($ext -notin @('yaml', 'yml', 'json')) {
        Write-Error "Unsupported file format: $ext (expected yaml, yml, or json)"
        return $false
    }

    try {
        if ($ext -in @('yaml', 'yml')) {
            $spec = Read-YamlFile -Path $Path
        }
        else {
            $spec = Get-Content $Path -Raw | ConvertFrom-Json
        }

        if ([string]::IsNullOrEmpty($spec.metadata.id)) {
            Write-Error "Missing required field: metadata.id"
            return $false
        }

        if ([string]::IsNullOrEmpty($spec.metadata.title)) {
            Write-Error "Missing required field: metadata.title"
            return $false
        }

        Write-Success "Spec validation passed: $($spec.metadata.id) - $($spec.metadata.title)"
        return $true
    }
    catch {
        Write-Error "Invalid file syntax: $_"
        return $false
    }
}

# Build AI prompt from spec
function Build-Prompt {
    param([string]$Path)

    $specContent = Get-Content $Path -Raw

    $ext = [System.IO.Path]::GetExtension($Path).TrimStart('.')
    if ($ext -in @('yaml', 'yml')) {
        $spec = Read-YamlFile -Path $Path
    }
    else {
        $spec = Get-Content $Path -Raw | ConvertFrom-Json
    }

    $specId = $spec.metadata.id
    $specTitle = $spec.metadata.title
    $acceptanceCriteria = $spec.acceptance_criteria | ConvertTo-Json -Depth 10

    $prompt = @"
# Implementation Request: $specId - $specTitle

## Context
You are implementing a feature based on an approved specification. Follow the spec precisely and implement all acceptance criteria.

## Specification
``````yaml
$specContent
``````

## Instructions

1. **Analyze** the specification thoroughly before making changes
2. **Plan** the implementation approach based on the existing codebase
3. **Implement** the feature following project conventions and patterns
4. **Test** - Create appropriate tests for all acceptance criteria
5. **Document** - Update relevant documentation if needed

## Requirements

- Follow existing code patterns and conventions in this repository
- Implement ALL acceptance criteria listed in the spec
- Write clean, maintainable, well-tested code
- Do not over-engineer - implement exactly what the spec requires
- If the spec is ambiguous, make reasonable decisions and document them

## Acceptance Criteria to Implement
$acceptanceCriteria

Begin implementation now. Start by exploring the codebase to understand the existing structure, then implement the feature.
"@

    return $prompt
}

# Run AI CLI
function Invoke-AiCli {
    param([string]$SpecPath)

    $prompt = Build-Prompt -Path $SpecPath

    Write-Log "Starting AI implementation with: $($script:DetectedCli)"
    Write-Debug "Prompt length: $($prompt.Length) characters"

    if ($DryRun) {
        Write-Warning "DRY RUN MODE - No changes will be made"
        Write-Host "---"
        Write-Host "Prompt that would be sent:"
        Write-Host "---"
        Write-Host $prompt
        Write-Host "---"
        return $true
    }

    # Create temporary file for prompt
    $promptFile = New-TemporaryFile
    $prompt | Out-File -FilePath $promptFile.FullName -Encoding utf8

    Push-Location $ProjectRoot

    try {
        $exitCode = 0

        switch ($script:DetectedCli) {
            'claude' {
                $result = Get-Content $promptFile.FullName | claude --print --dangerously-skip-permissions
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Implementation completed successfully"
                }
                else {
                    $exitCode = 1
                }
            }
            'aider' {
                $promptContent = Get-Content $promptFile.FullName -Raw
                & aider --message $promptContent --yes --no-git
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Implementation completed successfully"
                }
                else {
                    $exitCode = 1
                }
            }
            'copilot' {
                $promptContent = Get-Content $promptFile.FullName -Raw
                & gh copilot suggest $promptContent
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Copilot suggestion generated"
                }
                else {
                    $exitCode = 1
                }
            }
            'cody' {
                $promptContent = Get-Content $promptFile.FullName -Raw
                & cody chat --message $promptContent
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Implementation completed successfully"
                }
                else {
                    $exitCode = 1
                }
            }
            'gpt' {
                $promptContent = Get-Content $promptFile.FullName -Raw
                & gpt $promptContent
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Implementation completed successfully"
                }
                else {
                    $exitCode = 1
                }
            }
            'custom' {
                if ([string]::IsNullOrEmpty($AiCliCommand)) {
                    Write-Error "AiCliCommand must be set when using custom CLI"
                    $exitCode = 1
                }
                else {
                    $promptContent = Get-Content $promptFile.FullName -Raw
                    Invoke-Expression "$AiCliCommand `"$promptContent`""
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "Implementation completed successfully"
                    }
                    else {
                        $exitCode = 1
                    }
                }
            }
            default {
                Write-Error "Unsupported AI CLI: $($script:DetectedCli)"
                $exitCode = 1
            }
        }

        return $exitCode -eq 0
    }
    finally {
        Pop-Location
        Remove-Item $promptFile.FullName -Force -ErrorAction SilentlyContinue
    }
}

# Process specs from config file
function Invoke-ConfigProcessing {
    param([string]$ConfigPath)

    if (-not (Test-Path $ConfigPath)) {
        Write-Error "Config file not found: $ConfigPath"
        return $false
    }

    Write-Log "Processing specs from config: $ConfigPath"

    $config = Read-YamlFile -Path $ConfigPath

    $specsToProcess = $config.specifications | Where-Object {
        $_.status -eq 'approved' -and $_.auto_implement -eq $true
    }

    if ($null -eq $specsToProcess -or $specsToProcess.Count -eq 0) {
        Write-Log "No specs pending implementation"
        return $true
    }

    $processed = 0
    $failed = 0

    foreach ($spec in $specsToProcess) {
        Write-Log "Processing: $($spec.file)"

        if (Invoke-SpecProcessing -SpecPath $spec.file) {
            $processed++
        }
        else {
            $failed++
        }
    }

    Write-Log "Processed: $processed, Failed: $failed"

    return $failed -eq 0
}

# Process a single spec file
function Invoke-SpecProcessing {
    param([string]$SpecPath)

    if (-not (Test-SpecFile -Path $SpecPath)) {
        return $false
    }

    if (-not (Invoke-AiCli -SpecPath $SpecPath)) {
        return $false
    }

    return $true
}

# Show help
function Show-Help {
    $help = @"
Spec Ingestion Script (PowerShell) - Process specifications with AI CLI

Usage:
    ./Invoke-SpecIngestion.ps1 -SpecFile <file>      Process a single spec file
    ./Invoke-SpecIngestion.ps1 -Config               Process specs from config file
    ./Invoke-SpecIngestion.ps1 -Validate -ValidateFile <file>  Validate spec only
    ./Invoke-SpecIngestion.ps1 -ShowHelp             Show this help message

Parameters:
    -SpecFile <path>      Path to specification file
    -Config               Process specs from configuration file
    -ConfigFile <path>    Path to config file (default: specs.config.yaml)
    -Validate             Validate only, no implementation
    -ValidateFile <path>  Path to file to validate
    -AiCli <name>         Force specific AI CLI (auto-detected by default)
    -AiCliCommand <cmd>   Custom CLI command (when -AiCli is 'custom')
    -DryRun               Show what would be done without making changes
    -Verbose              Enable verbose output

Supported AI CLIs:
    claude      Anthropic Claude Code
    aider       Aider AI pair programming
    copilot     GitHub Copilot CLI
    cody        Sourcegraph Cody
    gpt         OpenAI GPT CLI
    custom      Custom command (set -AiCliCommand)

Environment Variables:
    AI_API_KEY           Generic API key
    ANTHROPIC_API_KEY    API key for Claude
    OPENAI_API_KEY       API key for OpenAI/Aider
    GITHUB_TOKEN         Token for GitHub Copilot
    SRC_ACCESS_TOKEN     Token for Sourcegraph Cody

Examples:
    # Process a single feature spec (auto-detect AI CLI)
    ./Invoke-SpecIngestion.ps1 -SpecFile specs/features/FEAT-0001.yaml

    # Process with specific AI CLI
    ./Invoke-SpecIngestion.ps1 -SpecFile specs/features/FEAT-0001.yaml -AiCli aider

    # Process all approved specs from config
    ./Invoke-SpecIngestion.ps1 -Config

    # Validate a spec without implementing
    ./Invoke-SpecIngestion.ps1 -Validate -ValidateFile specs/features/FEAT-0001.yaml

    # Dry run
    ./Invoke-SpecIngestion.ps1 -SpecFile specs/features/FEAT-0001.yaml -DryRun

    # Use custom AI CLI
    ./Invoke-SpecIngestion.ps1 -SpecFile spec.yaml -AiCli custom -AiCliCommand "my-ai-tool"
"@

    Write-Host $help
}

# Main execution
if ($ShowHelp) {
    Show-Help
    exit 0
}

if ($Validate) {
    $result = Test-SpecFile -Path $ValidateFile
    exit ([int](-not $result))
}

Test-Dependencies

if ($Config) {
    $result = Invoke-ConfigProcessing -ConfigPath $SpecsConfigPath
    exit ([int](-not $result))
}

if (-not [string]::IsNullOrEmpty($SpecFile)) {
    $result = Invoke-SpecProcessing -SpecPath $SpecFile
    exit ([int](-not $result))
}

Show-Help
exit 1
