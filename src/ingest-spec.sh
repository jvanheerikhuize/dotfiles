#!/usr/bin/env bash
#
# Spec Ingestion Script (Bash/Unix)
# Processes specification files and triggers AI CLI for implementation
#
# Usage:
#   ./scripts/ingest-spec.sh <spec-file>
#   ./scripts/ingest-spec.sh --config [config-file]
#   ./scripts/ingest-spec.sh --validate <spec-file>
#
# Supported AI CLIs (auto-detected or set via AI_CLI):
#   - claude     (Anthropic Claude Code)
#   - aider      (Aider - AI pair programming)
#   - copilot    (GitHub Copilot CLI)
#   - cody       (Sourcegraph Cody)
#   - cursor     (Cursor AI - via CLI)
#   - continue   (Continue.dev)
#   - gpt        (OpenAI GPT CLI)
#   - custom     (Custom command via AI_CLI_COMMAND)
#
# Environment Variables:
#   AI_CLI             - AI CLI to use (auto-detected if not set)
#   AI_CLI_COMMAND     - Custom CLI command (when AI_CLI=custom)
#   AI_API_KEY         - API key for AI service (name varies by provider)
#   AI_MODEL           - Model to use (provider-specific)
#   DRY_RUN            - Set to "true" for validation only
#   VERBOSE            - Set to "true" for detailed output

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SPECS_CONFIG="${PROJECT_ROOT}/specs.config.yaml"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"

# Colors for output (with fallback for non-color terminals)
if [[ -t 1 ]] && command -v tput &> /dev/null && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Detect available AI CLI
detect_ai_cli() {
    if [[ -n "${AI_CLI:-}" ]]; then
        echo "$AI_CLI"
        return 0
    fi

    # Detection order (most common first)
    local cli_options=("claude" "aider" "gh copilot" "cody" "cursor" "continue" "gpt")

    for cli in "${cli_options[@]}"; do
        if command -v "${cli%% *}" &> /dev/null; then
            echo "${cli%% *}"
            return 0
        fi
    done

    echo "none"
    return 1
}

# Get API key environment variable name for CLI
get_api_key_var() {
    local cli="$1"
    case "$cli" in
        claude)   echo "ANTHROPIC_API_KEY" ;;
        aider)    echo "OPENAI_API_KEY" ;;  # or ANTHROPIC_API_KEY
        gpt)      echo "OPENAI_API_KEY" ;;
        copilot)  echo "GITHUB_TOKEN" ;;
        cody)     echo "SRC_ACCESS_TOKEN" ;;
        *)        echo "AI_API_KEY" ;;
    esac
}

# Check dependencies
check_dependencies() {
    local missing_deps=()

    # Check for YAML/JSON processors
    if ! command -v yq &> /dev/null; then
        missing_deps+=("yq (https://github.com/mikefarah/yq)")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq (https://stedolan.github.io/jq/)")
    fi

    # Detect AI CLI
    local detected_cli
    detected_cli=$(detect_ai_cli)

    if [[ "$detected_cli" == "none" && "${AI_CLI:-}" != "custom" ]]; then
        missing_deps+=("AI CLI (claude, aider, copilot, cody, cursor, continue, or gpt)")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Install an AI CLI:"
        echo "  - Claude Code:  npm install -g @anthropic-ai/claude-code"
        echo "  - Aider:        pip install aider-chat"
        echo "  - GitHub Copilot: gh extension install github/gh-copilot"
        echo "  - Cody:         See https://sourcegraph.com/docs/cody"
        exit 1
    fi

    # Check API key
    local api_key_var
    api_key_var=$(get_api_key_var "$detected_cli")

    if [[ -z "${!api_key_var:-}" && "$detected_cli" != "copilot" ]]; then
        log_warn "$api_key_var environment variable is not set"
        log_info "Some AI CLIs may use different authentication methods"
    fi

    AI_CLI_DETECTED="$detected_cli"
    log_verbose "Using AI CLI: $AI_CLI_DETECTED"
}

# Validate spec file
validate_spec() {
    local spec_file="$1"

    if [[ ! -f "$spec_file" ]]; then
        log_error "Spec file not found: $spec_file"
        return 1
    fi

    log_info "Validating spec: $spec_file"

    # Check file extension
    local ext="${spec_file##*.}"
    if [[ "$ext" != "yaml" && "$ext" != "yml" && "$ext" != "json" ]]; then
        log_error "Unsupported file format: $ext (expected yaml, yml, or json)"
        return 1
    fi

    # Validate YAML syntax
    if [[ "$ext" == "yaml" || "$ext" == "yml" ]]; then
        if ! yq e '.' "$spec_file" > /dev/null 2>&1; then
            log_error "Invalid YAML syntax in: $spec_file"
            return 1
        fi
    fi

    # Check required fields
    local spec_id spec_title spec_status

    if [[ "$ext" == "yaml" || "$ext" == "yml" ]]; then
        spec_id=$(yq e '.metadata.id // ""' "$spec_file")
        spec_title=$(yq e '.metadata.title // ""' "$spec_file")
        spec_status=$(yq e '.metadata.status // ""' "$spec_file")
    else
        spec_id=$(jq -r '.metadata.id // ""' "$spec_file")
        spec_title=$(jq -r '.metadata.title // ""' "$spec_file")
        spec_status=$(jq -r '.metadata.status // ""' "$spec_file")
    fi

    if [[ -z "$spec_id" ]]; then
        log_error "Missing required field: metadata.id"
        return 1
    fi

    if [[ -z "$spec_title" ]]; then
        log_error "Missing required field: metadata.title"
        return 1
    fi

    log_success "Spec validation passed: $spec_id - $spec_title"
    return 0
}

# Build AI prompt from spec
build_prompt() {
    local spec_file="$1"
    local spec_content
    spec_content=$(cat "$spec_file")

    local ext="${spec_file##*.}"
    local spec_id spec_title acceptance_criteria

    if [[ "$ext" == "yaml" || "$ext" == "yml" ]]; then
        spec_id=$(yq e '.metadata.id' "$spec_file")
        spec_title=$(yq e '.metadata.title' "$spec_file")
        acceptance_criteria=$(yq e -o=json '.acceptance_criteria' "$spec_file")
    else
        spec_id=$(jq -r '.metadata.id' "$spec_file")
        spec_title=$(jq -r '.metadata.title' "$spec_file")
        acceptance_criteria=$(jq '.acceptance_criteria' "$spec_file")
    fi

    cat <<EOF
# Implementation Request: $spec_id - $spec_title

## Context
You are implementing a feature based on an approved specification. Follow the spec precisely and implement all acceptance criteria.

## Specification
\`\`\`yaml
$spec_content
\`\`\`

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
$acceptance_criteria

Begin implementation now. Start by exploring the codebase to understand the existing structure, then implement the feature.
EOF
}

# Run AI CLI
run_ai_cli() {
    local spec_file="$1"
    local prompt
    prompt=$(build_prompt "$spec_file")

    log_info "Starting AI implementation with: $AI_CLI_DETECTED"
    log_verbose "Prompt length: ${#prompt} characters"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        echo "---"
        echo "Prompt that would be sent:"
        echo "---"
        echo "$prompt"
        echo "---"
        return 0
    fi

    # Create a temporary file for the prompt
    local prompt_file
    prompt_file=$(mktemp)
    echo "$prompt" > "$prompt_file"

    cd "$PROJECT_ROOT"
    local exit_code=0

    case "$AI_CLI_DETECTED" in
        claude)
            # Claude Code CLI
            if claude --print --dangerously-skip-permissions < "$prompt_file"; then
                log_success "Implementation completed successfully"
            else
                exit_code=1
            fi
            ;;
        aider)
            # Aider
            if aider --message "$(cat "$prompt_file")" --yes --no-git; then
                log_success "Implementation completed successfully"
            else
                exit_code=1
            fi
            ;;
        copilot)
            # GitHub Copilot CLI
            if gh copilot suggest "$(cat "$prompt_file")"; then
                log_success "Copilot suggestion generated"
            else
                exit_code=1
            fi
            ;;
        cody)
            # Sourcegraph Cody
            if cody chat --message "$(cat "$prompt_file")"; then
                log_success "Implementation completed successfully"
            else
                exit_code=1
            fi
            ;;
        gpt)
            # OpenAI GPT CLI
            if gpt "$(cat "$prompt_file")"; then
                log_success "Implementation completed successfully"
            else
                exit_code=1
            fi
            ;;
        custom)
            # Custom CLI command
            if [[ -z "${AI_CLI_COMMAND:-}" ]]; then
                log_error "AI_CLI_COMMAND must be set when using custom CLI"
                exit_code=1
            else
                if eval "$AI_CLI_COMMAND" < "$prompt_file"; then
                    log_success "Implementation completed successfully"
                else
                    exit_code=1
                fi
            fi
            ;;
        *)
            log_error "Unsupported AI CLI: $AI_CLI_DETECTED"
            exit_code=1
            ;;
    esac

    rm -f "$prompt_file"

    if [[ $exit_code -ne 0 ]]; then
        log_error "AI CLI execution failed"
    fi

    return $exit_code
}

# Process specs from config file
process_config() {
    local config_file="${1:-$SPECS_CONFIG}"

    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        exit 1
    fi

    log_info "Processing specs from config: $config_file"

    # Get specs with status=approved and auto_implement=true
    local specs
    specs=$(yq e '.specifications[] | select(.status == "approved" and .auto_implement == true) | .file' "$config_file")

    if [[ -z "$specs" ]]; then
        log_info "No specs pending implementation"
        return 0
    fi

    local processed=0
    local failed=0

    while IFS= read -r spec_file; do
        if [[ -n "$spec_file" ]]; then
            log_info "Processing: $spec_file"

            if process_spec "$spec_file"; then
                ((processed++))
            else
                ((failed++))
            fi
        fi
    done <<< "$specs"

    log_info "Processed: $processed, Failed: $failed"

    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Process a single spec file
process_spec() {
    local spec_file="$1"

    # Validate first
    if ! validate_spec "$spec_file"; then
        return 1
    fi

    # Run AI implementation
    if ! run_ai_cli "$spec_file"; then
        return 1
    fi

    return 0
}

# Display usage
usage() {
    cat <<EOF
Spec Ingestion Script - Process specifications with AI CLI

Usage:
    $(basename "$0") <spec-file>           Process a single spec file
    $(basename "$0") --config [file]       Process specs from config file
    $(basename "$0") --validate <file>     Validate spec without processing
    $(basename "$0") --help                Show this help message

Options:
    --config [file]    Process specs from config (default: specs.config.yaml)
    --validate         Validate spec file only, no implementation
    --help, -h         Show this help message

Supported AI CLIs (auto-detected):
    claude      Anthropic Claude Code
    aider       Aider AI pair programming
    copilot     GitHub Copilot CLI
    cody        Sourcegraph Cody
    gpt         OpenAI GPT CLI
    custom      Custom command (set AI_CLI_COMMAND)

Environment Variables:
    AI_CLI             Force specific AI CLI (optional, auto-detected)
    AI_CLI_COMMAND     Custom CLI command (when AI_CLI=custom)
    AI_API_KEY         Generic API key (or use provider-specific var)
    ANTHROPIC_API_KEY  API key for Claude
    OPENAI_API_KEY     API key for OpenAI/Aider
    AI_MODEL           Model to use (provider-specific)
    DRY_RUN            Set to "true" for validation only
    VERBOSE            Set to "true" for detailed output

Examples:
    # Process a single feature spec (auto-detect AI CLI)
    ./scripts/ingest-spec.sh specs/features/FEAT-0001.yaml

    # Process with specific AI CLI
    AI_CLI=aider ./scripts/ingest-spec.sh specs/features/FEAT-0001.yaml

    # Process all approved specs from config
    ./scripts/ingest-spec.sh --config

    # Validate a spec without implementing
    ./scripts/ingest-spec.sh --validate specs/features/FEAT-0001.yaml

    # Dry run (show what would be done)
    DRY_RUN=true ./scripts/ingest-spec.sh specs/features/FEAT-0001.yaml

    # Use custom AI CLI
    AI_CLI=custom AI_CLI_COMMAND="my-ai-tool --input" ./scripts/ingest-spec.sh spec.yaml
EOF
}

# Main entry point
main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 1
    fi

    case "${1:-}" in
        --help|-h)
            usage
            exit 0
            ;;
        --config)
            check_dependencies
            process_config "${2:-}"
            ;;
        --validate)
            if [[ -z "${2:-}" ]]; then
                log_error "Spec file required for validation"
                exit 1
            fi
            validate_spec "$2"
            ;;
        *)
            if [[ -f "$1" ]]; then
                check_dependencies
                process_spec "$1"
            else
                log_error "Unknown option or file not found: $1"
                usage
                exit 1
            fi
            ;;
    esac
}

main "$@"
