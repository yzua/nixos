#!/usr/bin/env bash
# Core collectors for system report generation.

# shellcheck source=scripts/lib/error-patterns.sh
source "${SCRIPT_DIR}/../../lib/error-patterns.sh"
# shellcheck source=scripts/lib/log-dirs.sh
source "${SCRIPT_DIR}/../../lib/log-dirs.sh"

scan_error_log_count() {
	local mtime_filter="$1"
	shift
	local -a dirs=("$@")
	local -a find_args=()
	local -a matched_files=()

	find_args=("${dirs[@]}" -type f -name "*.log")
	if [[ -n "$mtime_filter" ]]; then
		find_args+=(-mtime "$mtime_filter")
	fi

	mapfile -t matched_files < <(
		find "${find_args[@]}" -print0 2>/dev/null |
			xargs -0 -r grep -Eil "$ERROR_PATTERN" 2>/dev/null || true
	)

	echo "${#matched_files[@]}"
}

collect_systemd_errors() {
	section "Failed Services"

	local failed
	failed=$(safe_cmd systemctl --no-legend --plain list-units --state=failed --no-pager)

	if [[ -z "$failed" ]]; then
		echo "No failed services."
	else
		while IFS= read -r line; do
			local unit
			unit="${line%% *}"
			echo "- \`${unit}\`"
		done <<<"$failed"
	fi

	section "Recent Errors (last ${1:-24}h)"

	local since="${1:-24}"
	local errors
	errors=$(safe_cmd journalctl --no-pager --quiet -p 0..3 --since "-${since}h" -o json |
		jq -rs '
            group_by(._SYSTEMD_UNIT // .SYSLOG_IDENTIFIER // "kernel")
            | map({
                unit: (.[0]._SYSTEMD_UNIT // .[0].SYSLOG_IDENTIFIER // "kernel"),
                count: length,
                severity: (.[0].PRIORITY | tonumber | if . <= 2 then "err" elif . == 3 then "warning" else "notice" end)
            })
            | sort_by(-.count)
            | .[:20]
        ' 2>/dev/null)

	if json_is_empty "$errors"; then
		echo "No priority 0-3 errors in the last ${since}h."
	else
		print_table_header "| Unit | Count | Severity |" "|------|-------|----------|"
		echo "$errors" | jq -r '.[] | "| \(.unit) | \(.count) | \(.severity) |"'
	fi
}

collect_systemd_timers() {
	section "Systemd Timers"

	local timers
	timers=$(safe_cmd systemctl list-timers --no-pager --no-legend --plain |
		awk 'NF >= 4 { printf "%s|%s %s %s\n", $(NF-1), $1, $2, $3 }' | head -20)

	if [[ -z "$timers" ]]; then
		echo "No active timers."
	else
		print_table_header "| Timer | Next Run |" "|-------|----------|"
		while IFS= read -r line; do
			local timer next_run
			IFS='|' read -r timer next_run <<<"$line"
			echo "| ${timer} | ${next_run} |"
		done <<<"$timers"
	fi
}

collect_network_traffic() {
	section "Network Traffic"

	if ! command -v vnstat &>/dev/null; then
		echo "[unavailable] vnstat not installed."
		return
	fi

	local vndata
	vndata=$(safe_cmd vnstat --json d 1 2>/dev/null)

	if [[ -z "$vndata" ]]; then
		echo "[unavailable] Could not query vnstat."
		return
	fi

	print_table_header "| Interface | Today | Month |" "|-----------|-------|-------|"

	echo "$vndata" | jq -r '
        .interfaces[]? |
        .name as $name |
        (.traffic.day[-1]? |
            ((.rx + .tx) / 1073741824 * 100 | round / 100)) as $today |
        "| \($name) | \($today // "N/A") GB | — |"
    ' 2>/dev/null || echo "| — | parse error | — |"
}

collect_nix_builds() {
	section "Nix Builds"

	local log_file="${HOME:-/home/${REPORT_USER}}/.local/share/nix-build-logs/builds.jsonl"

	if [[ ! -f "$log_file" ]]; then
		echo "No build log found."
		return
	fi

	local week_ago total success failure rate last_fail
	week_ago=$(iso_days_ago 7)

	if [[ -z "$week_ago" ]]; then
		echo "[unavailable] Could not compute date range."
		return
	fi

	local recent
	recent=$(jq -c --arg since "$week_ago" 'select(.timestamp >= $since)' "$log_file" 2>/dev/null)

	if [[ -z "$recent" ]]; then
		echo "No builds in the last 7 days."
		return
	fi

	total=$(echo "$recent" | wc -l)
	success=$(echo "$recent" | jq -r 'select(.status == "success")' | grep -c "success" || echo "0")
	failure=$((total - success))

	if [[ "$total" -gt 0 ]]; then
		rate=$(echo "scale=1; $success * 100 / $total" | bc 2>/dev/null || echo "?")
	else
		rate="N/A"
	fi

	echo "- Last 7 days: ${total} builds, ${success} success, ${failure} failure (${rate}%)"

	last_fail=$(echo "$recent" | jq -r 'select(.status == "failure")' | jq -rs 'last | "\(.timestamp) — \(.command): \(.error[:80])"' 2>/dev/null || echo "")
	if [[ -n "$last_fail" && "$last_fail" != "null" ]]; then
		echo "- Last failure: ${last_fail}"
	fi

	_BUILD_RATE="${rate:-0}"
}

collect_ai_agents() {
	section "AI Agent Errors"

	local -a candidate_dirs=(
		"$LOG_DIR"
		"$OPENCODE_LOG_DIR"
		"$CODEX_LOG_DIR"
	)
	local -a log_dirs=()

	for dir in "${candidate_dirs[@]}"; do
		[[ -d "$dir" ]] && log_dirs+=("$dir")
	done

	if [[ "${#log_dirs[@]}" -eq 0 ]]; then
		echo "No agent logs found."
		return
	fi

	local errors recent_errors
	errors=$(scan_error_log_count "" "${log_dirs[@]}")
	recent_errors=$(scan_error_log_count "-1" "${log_dirs[@]}")

	echo "- Log directories scanned: ${#log_dirs[@]}"
	echo "- Log files with errors: ${errors}"
	echo "- Files with errors (last 24h): ${recent_errors}"
}
