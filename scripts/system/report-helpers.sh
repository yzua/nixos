#!/usr/bin/env bash
# Helper functions for system report generation (section, query_api, safe_cmd, etc.) and JSON summary.

section() { printf '\n## %s\n\n' "$1"; }

debug_log() {
	if [[ "${SYSTEM_REPORT_DEBUG:-false}" == "true" ]]; then
		printf '[system-report] %s\n' "$*" >&2
	fi
}

json_is_empty() {
	local json="${1:-}"
	[[ -z "$json" || "$json" == "null" || "$json" == "[]" || "$json" == "{}" ]]
}

epoch_hours_ago() {
	local hours="$1"
	date -d "${hours} hours ago" +%s 2>/dev/null || date -v-"${hours}"H +%s 2>/dev/null || echo ""
}

iso_days_ago() {
	local days="$1"
	date -d "${days} days ago" -Iseconds 2>/dev/null || date -v-"${days}"d -Iseconds 2>/dev/null || echo ""
}

query_api() {
	local url="$1"
	local response
	if response=$(curl -sf --max-time "$CURL_TIMEOUT" "$url" 2>/dev/null); then
		printf '%s\n' "$response"
		return 0
	fi
	debug_log "query_api failed: ${url}"
	echo ""
}

query_prometheus() {
	local query="$1"
	local result
	result=$(query_api "http://127.0.0.1:9090/api/v1/query?query=$(jq -rn --arg q "$query" '$q|@uri')")
	if [[ -n "$result" ]]; then
		echo "$result" | jq -r '.data.result[0].value[1] // empty' 2>/dev/null || echo ""
	fi
}

query_loki() {
	local query="$1" start="$2"
	local result
	result=$(query_api "http://127.0.0.1:3100/loki/api/v1/query_range?query=$(jq -rn --arg q "$query" '$q|@uri')&start=${start}&end=$(date +%s)&step=3600")
	if [[ -n "$result" ]]; then
		echo "$result" | jq -r '.data.result' 2>/dev/null || echo ""
	fi
}

safe_cmd() {
	local output
	if output=$(timeout "${CMD_TIMEOUT}s" "$@" 2>/dev/null); then
		printf '%s\n' "$output"
		return 0
	fi
	debug_log "safe_cmd failed: $*"
	echo ""
}

status_label() {
	local value="$1" warn="${2:-80}" crit="${3:-90}"
	local int_val="${value%%.*}"
	if [[ -z "$int_val" || "$int_val" -lt 0 ]]; then
		echo "unknown"
	elif [[ "$int_val" -ge "$crit" ]]; then
		echo "critical"
	elif [[ "$int_val" -ge "$warn" ]]; then
		echo "warning"
	else
		echo "ok"
	fi
}

generate_json_summary() {
	local status="ok"
	local issues=()

	local failed_count
	failed_count=$(systemctl --no-legend --plain list-units --state=failed --no-pager 2>/dev/null | wc -l || echo "0")

	local error_count
	error_count=$(journalctl --no-pager --quiet -p 0..3 --since "-24h" 2>/dev/null | wc -l || echo "0")

	if [[ "${failed_count:-0}" -gt 0 ]]; then
		status="critical"
		issues+=("${failed_count} failed services")
	fi
	if [[ "${_DISK_ROOT:-0}" -ge 90 || "${_DISK_HOME:-0}" -ge 90 ]]; then
		status="critical"
		issues+=("disk usage critical")
	elif [[ "${_DISK_ROOT:-0}" -ge 80 || "${_DISK_HOME:-0}" -ge 80 ]]; then
		[[ "$status" != "critical" ]] && status="warning"
		issues+=("disk usage elevated")
	fi
	if [[ "${_SMART_FAILING:-0}" -gt 0 ]]; then
		status="critical"
		issues+=("${_SMART_FAILING} SMART failures")
	fi
	if [[ "${error_count:-0}" -gt 50 ]]; then
		[[ "$status" != "critical" ]] && status="warning"
		issues+=("${error_count} journal errors (24h)")
	fi

	local issues_json
	issues_json=$(printf '%s\n' "${issues[@]}" 2>/dev/null | jq -R . | jq -s . 2>/dev/null || echo "[]")

	jq -n \
		--arg ts "$TIMESTAMP" \
		--arg host "$HOSTNAME" \
		--arg status "$status" \
		--argjson failed "${failed_count:-0}" \
		--argjson errors "${error_count:-0}" \
		--argjson cpu "${_CPU:-0}" \
		--argjson mem "${_MEM:-0}" \
		--argjson disk_root "${_DISK_ROOT:-0}" \
		--argjson disk_home "${_DISK_HOME:-0}" \
		--argjson smart_failing "${_SMART_FAILING:-0}" \
		--argjson f2b_banned "${_FAIL2BAN_BANNED:-0}" \
		--argjson netdata_alarms "${_NETDATA_ALARMS:-0}" \
		--argjson build_rate "${_BUILD_RATE:-0}" \
		--argjson issues "$issues_json" \
		'{
            timestamp: $ts,
            hostname: $host,
            status: $status,
            failed_services: $failed,
            journal_errors_24h: $errors,
            cpu_percent: $cpu,
            memory_percent: $mem,
            disk_root_percent: $disk_root,
            disk_home_percent: $disk_home,
            smart_failing: $smart_failing,
            fail2ban_banned: $f2b_banned,
            netdata_alarms: $netdata_alarms,
            build_success_rate_7d: $build_rate,
            issues: $issues
        }'
}
