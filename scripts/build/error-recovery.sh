#!/usr/bin/env bash
# error-recovery.sh - Enhanced error recovery utilities for build process
# Provides robust error handling and recovery mechanisms

set -euo pipefail

# Configuration
LOG_FILE="/tmp/nixos-build-errors.log"
MAX_RETRIES=3
RETRY_DELAY=5

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE" >&2
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

# Initialize log file
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== NixOS Build Error Recovery Log $(date) ===" > "$LOG_FILE"
    log_info "Error recovery system initialized"
}

# Retry mechanism with exponential backoff
retry_command() {
    local max_retries="${1:-$MAX_RETRIES}"
    local delay="${2:-$RETRY_DELAY}"
    shift 2 2>/dev/null || true
    local attempt=1

    while [[ $attempt -le $max_retries ]]; do
        log_info "Executing (attempt $attempt/$max_retries): $*"

        if "$@"; then
            log_success "Command succeeded on attempt $attempt"
            return 0
        else
            local exit_code=$?
            log_warning "Command failed on attempt $attempt (exit code: $exit_code)"

            if [[ $attempt -eq $max_retries ]]; then
                log_error "Command failed after $max_retries attempts"
                return $exit_code
            fi

            local sleep_time=$((delay * attempt))  # Exponential backoff
            log_info "Retrying in ${sleep_time}s..."
            sleep "$sleep_time"
            ((attempt++))
        fi
    done
}

# Network connectivity check
check_network() {
    local test_urls=("https://cache.nixos.org" "https://github.com" "https://nixos.org")
    local connected=false

    for url in "${test_urls[@]}"; do
        if curl -s --max-time 10 --head "$url" >/dev/null 2>&1; then
            log_info "Network connectivity confirmed via $url"
            connected=true
            break
        fi
    done

    if [[ "$connected" != "true" ]]; then
        log_error "No network connectivity detected"
        return 1
    fi
}

# Disk space check
check_disk_space() {
    local min_space_gb="${1:-5}"
    local nix_store="/nix"

    # Get available space in GB
    local available_gb
    available_gb=$(df -BG "$nix_store" | tail -1 | awk '{print int($4)}')

    if [[ $available_gb -lt $min_space_gb ]]; then
        log_error "Insufficient disk space: ${available_gb}GB available, ${min_space_gb}GB required"
        log_info "Consider running: nix-collect-garbage -d && nix store optimise"
        return 1
    fi

    log_info "Disk space check passed: ${available_gb}GB available"
}

# Nix store integrity check
check_nix_store() {
    log_info "Checking Nix store integrity..."

    if ! nix store verify --all-users 2>/dev/null; then
        log_warning "Nix store verification found issues"
        log_info "Attempting to repair Nix store..."

        if nix store repair --all; then
            log_success "Nix store repair completed"
        else
            log_error "Nix store repair failed"
            return 1
        fi
    else
        log_info "Nix store integrity check passed"
    fi
}

# Memory check
check_memory() {
    local min_memory_mb="${1:-1024}"  # 1GB minimum

    # Get available memory in MB
    local available_mb
    available_mb=$(free -m | awk 'NR==2{print $7}')

    if [[ $available_mb -lt $min_memory_mb ]]; then
        log_error "Insufficient memory: ${available_mb}MB available, ${min_memory_mb}MB required"
        return 1
    fi

    log_info "Memory check passed: ${available_mb}MB available"
}

# Pre-build validation
pre_build_check() {
    log_info "Running pre-build validation..."

    check_network || return 1
    check_disk_space || return 1
    check_memory || return 1
    check_nix_store || return 1

    log_success "Pre-build validation completed"
}

# Main error recovery function
recover_from_error() {
    local failed_command="$1"
    local error_context="$2"

    log_error "Build failed: $failed_command"
    log_info "Error context: $error_context"
    log_info "Attempting error recovery..."

    # Try common recovery steps
    case "$failed_command" in
        *flake-check*|*check*)
            log_info "Flake check failed - attempting recovery..."

            # Clear flake lock and try again
            if [[ -f "flake.lock" ]]; then
                cp flake.lock flake.lock.backup
                rm flake.lock
                log_info "Removed flake.lock, retrying..."
                return 0  # Signal to retry
            fi
            ;;
        *switch*|*rebuild*)
            log_info "Switch failed - attempting recovery..."

            # Clean up and retry
            retry_command 2 2 nh clean all --keep 1
            return 0  # Signal to retry
            ;;
        *)
            log_error "Unknown error type, manual intervention required"
            return 1
            ;;
    esac
}

# Export functions for use in other scripts (only if supported)
if [[ "${BASH_VERSION:-}" && "${BASH_VERSION%%.*}" -ge 4 ]]; then
    export -f log_error log_warning log_info log_success 2>/dev/null || true
    export -f retry_command check_network check_disk_space check_nix_store check_memory 2>/dev/null || true
    export -f pre_build_check recover_from_error 2>/dev/null || true
fi

# If script is run directly, show usage
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
    echo "NixOS Build Error Recovery Utilities"
    echo ""
    echo "Usage:"
    echo "  source $0  # Load functions into current shell"
    echo "  pre_build_check  # Run pre-build validation"
    echo "  retry_command [max_retries] [delay] command [args...]  # Retry a command"
    echo ""
    echo "Available functions:"
    echo "  log_error, log_warning, log_info, log_success - Logging"
    echo "  check_network, check_disk_space, check_nix_store, check_memory - Validation"
    echo "  recover_from_error - Error recovery"
fi