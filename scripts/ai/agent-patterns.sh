#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agent-logs}"

echo "Analyzing error patterns..."
echo "----------------------------------------------------------------"

if compgen -G "$LOG_DIR/*-errors-*.log" >/dev/null; then
	cat "$LOG_DIR"/*-errors-*.log 2>/dev/null |
		grep -oE "(Error|ERROR|error|Exception|EXCEPTION|failed|Failed|FAILED):? [^[:space:]]{0,100}" |
		sort | uniq -c | sort -rn | head -20
else
	echo "No error log files found."
fi

echo ""
echo "----------------------------------------------------------------"
echo "Top exit codes:"
if compgen -G "$LOG_DIR/*.log" >/dev/null; then
	grep -h "exited with code" "$LOG_DIR"/*.log 2>/dev/null |
		grep -oE "code [0-9]+" | sort | uniq -c | sort -rn | head -10 || true
else
	echo "No log files found."
fi
