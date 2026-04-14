# shellcheck shell=bash
# Shared error keyword pattern for AI agent log analysis scripts.
# Source this file to get consistent error matching across all consumers.
# Usage: source "${SCRIPT_DIR}/../lib/error-patterns.sh"

# shellcheck disable=SC2034
ERROR_PATTERN='\b(error|panic|fatal|exception|failed|invalid|deprecated|certificate|ssl|tls)\b'
