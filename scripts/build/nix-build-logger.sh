#!/usr/bin/env bash
# nix-build-logger.sh - Log Nix build outcomes to JSONL file
# Captures nh command results with duration and error context.

set -euo pipefail

LOG_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/nix-build-logs/builds.jsonl"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log a build result to JSONL file
log_build() {
    local status="$1"
    local cmd="$2"
    local duration="$3"
    local error="${4:-}"

    jq -nc \
        --arg ts "$(date -Iseconds)" \
        --arg status "$status" \
        --arg cmd "$cmd" \
        --arg dur "$duration" \
        --arg err "$error" \
        '{timestamp:$ts, status:$status, command:$cmd, duration:$dur, error:$err}' >> "$LOG_FILE"
}

# Wrapper for nh commands with logging
nh_logged() {
    local start exit_code output duration

    start=$(date +%s)

    # Capture output and exit code
    if output=$(nh "$@" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi

    duration=$(($(date +%s) - start))

    if [[ $exit_code -eq 0 ]]; then
        log_build "success" "nh $*" "${duration}s"
    else
        # Extract error lines for context
        local error_context
        error_context=$(echo "$output" | grep -iE "error|Error|failed|Failed" | head -5 || true)
        log_build "failure" "nh $*" "${duration}s" "$error_context"
    fi

    # Output the original command output
    echo "$output"
    return $exit_code
}

# Show recent build history
show_history() {
    local count="${1:-10}"

    if [[ ! -f "$LOG_FILE" ]]; then
        echo "No build history found at $LOG_FILE"
        exit 0
    fi

    echo "=== Recent Nix Builds (last $count) ==="
    tail -n "$count" "$LOG_FILE" | jq -r '
        "\(.timestamp) | \(.status | if . == "success" then "✓" else "✗" end) | \(.duration) | \(.command)" +
        if .error != "" then "\n  Error: \(.error)" else "" end
    '
}

# Show failure statistics
show_stats() {
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "No build history found at $LOG_FILE"
        exit 0
    fi

    echo "=== Build Statistics ==="
    local total success failure
    total=$(wc -l < "$LOG_FILE")
    success=$(grep -c '"status":"success"' "$LOG_FILE" || echo 0)
    failure=$(grep -c '"status":"failure"' "$LOG_FILE" || echo 0)

    echo "Total builds: $total"
    echo "Successful:   $success"
    echo "Failed:       $failure"

    if [[ $total -gt 0 ]]; then
        local rate
        rate=$(echo "scale=1; $success * 100 / $total" | bc)
        echo "Success rate: ${rate}%"
    fi
}

# Main entry point
case "${1:-}" in
    history)
        show_history "${2:-10}"
        ;;
    stats)
        show_stats
        ;;
    log)
        # Direct log command: nix-build-logger.sh log success "nh os switch" "45s" "error msg"
        shift
        log_build "$@"
        ;;
    *)
        # Default: wrap nh command
        if [[ $# -gt 0 ]]; then
            nh_logged "$@"
        else
            echo "Usage: nix-build-logger.sh <nh-args...>"
            echo "       nix-build-logger.sh history [count]"
            echo "       nix-build-logger.sh stats"
            exit 1
        fi
        ;;
esac
