#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck source=scripts/lib/log-dirs.sh
source "${SCRIPT_DIR}/../lib/log-dirs.sh"

if [[ $# -lt 2 ]]; then
	print_error "Usage: ai-agent-log-wrapper <agent-name> <command> [args...]"
	exit 1
fi

AGENT_NAME="$1"
shift

LOG_FILE="$LOG_DIR/$AGENT_NAME-$(date +%Y-%m-%d).log"
ERROR_LOG="$LOG_DIR/$AGENT_NAME-errors-$(date +%Y-%m-%d).log"
NOTIFY_ON_ERROR="${AI_AGENT_NOTIFY_ON_ERROR:-false}"

mkdir -p "$LOG_DIR"

log_info "Starting $AGENT_NAME: $*"
echo "[$(date -Iseconds)] Starting $AGENT_NAME: $*" >>"$LOG_FILE"

set +e
"$@" 2> >(tee -a "$ERROR_LOG" >&2) | tee -a "$LOG_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

log_info "$AGENT_NAME exited with code $EXIT_CODE"
echo "[$(date -Iseconds)] $AGENT_NAME exited with code $EXIT_CODE" >>"$LOG_FILE"

if [[ "$NOTIFY_ON_ERROR" == "true" && $EXIT_CODE -ne 0 ]]; then
	notify-send -u critical "AI Agent Error" "$AGENT_NAME failed with exit code $EXIT_CODE"
fi

exit "$EXIT_CODE"
