# shellcheck shell=bash
# Shared log directory paths for AI agent scripts.
# Source this file to get consistent log directory constants.
# Usage: source "${SCRIPT_DIR}/../lib/log-dirs.sh"

# shellcheck disable=SC2034
LOG_DIR="${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agents/logs}"
# shellcheck disable=SC2034
OPENCODE_LOG_DIR="${OPENCODE_LOG_DIR:-$HOME/.local/share/opencode/log}"
# shellcheck disable=SC2034
CODEX_LOG_DIR="${CODEX_LOG_DIR:-$HOME/.codex/log}"
