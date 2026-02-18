#!/usr/bin/env bash
# Data collector functions for system report generation.

collect_systemd_errors() {
	section "Failed Services"

	local failed
	failed=$(safe_cmd systemctl --no-legend --plain list-units --state=failed --no-pager)

	if [[ -z "$failed" ]]; then
		echo "No failed services."
	else
		while IFS= read -r line; do
			local unit
			unit=$(echo "$line" | awk '{print $1}')
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
		echo "| Unit | Count | Severity |"
		echo "|------|-------|----------|"
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
		echo "| Timer | Next Run |"
		echo "|-------|----------|"
		while IFS= read -r line; do
			local timer next_run
			IFS='|' read -r timer next_run <<<"$line"
			echo "| ${timer} | ${next_run} |"
		done <<<"$timers"
	fi
}

netdata_chart() {
	local chart="$1" after="${2:--300}" points="${3:-1}"
	local result
	result=$(query_api "http://127.0.0.1:19999/api/v1/data?chart=${chart}&after=${after}&points=${points}&format=json&options=absolute")
	if [[ -n "$result" ]]; then
		echo "$result"
	fi
}

collect_resource_metrics() {
	section "Resource Usage"

	if [[ "$HAS_NETDATA" != "true" ]]; then
		echo "[unavailable] Netdata not enabled."
		return
	fi

	local cpu_data mem_data disk_root_data disk_home_data load_data
	cpu_data=$(netdata_chart "system.cpu")
	mem_data=$(netdata_chart "system.ram")
	disk_root_data=$(netdata_chart "disk_space._")
	disk_home_data=$(netdata_chart "disk_space._home")
	load_data=$(netdata_chart "system.load")

	local cpu mem disk_root disk_home load

	cpu=$(echo "$cpu_data" | jq '[.data[0][1:] | add] | .[0] // 0' 2>/dev/null || echo "")
	cpu=$(printf "%.0f" "${cpu:-0}" 2>/dev/null || echo "0")

	local mem_used mem_total mem_free_gb
	mem_used=$(echo "$mem_data" | jq '[.data[0][] | select(. != null)] | .[1] // 0' 2>/dev/null || echo "0")
	mem_total=$(echo "$mem_data" | jq '[.data[0][1:] | map(select(. != null))] | .[0] | add // 0' 2>/dev/null || echo "0")
	if [[ "$mem_total" != "0" && -n "$mem_total" ]]; then
		mem=$(echo "scale=0; $mem_used * 100 / $mem_total" | bc 2>/dev/null || echo "0")
		mem_total_gb=$(echo "scale=1; $mem_total / 1024" | bc 2>/dev/null || echo "0")
		mem_free_gb=$(echo "scale=1; ($mem_total - $mem_used) / 1024" | bc 2>/dev/null || echo "0")
	else
		mem="0"
		mem_total_gb="0"
		mem_free_gb="0"
	fi

	disk_root=$(echo "$disk_root_data" | jq '.data[0][2] // 0' 2>/dev/null || echo "")
	disk_root=$(printf "%.0f" "${disk_root:-0}" 2>/dev/null || echo "0")

	disk_home=$(echo "$disk_home_data" | jq '.data[0][2] // 0' 2>/dev/null || echo "")
	disk_home=$(printf "%.0f" "${disk_home:-0}" 2>/dev/null || echo "0")

	load=$(echo "$load_data" | jq '.data[0][3] // 0' 2>/dev/null || echo "")
	load=$(printf "%.1f" "${load:-0}" 2>/dev/null || echo "0")

	echo "| Metric | Value | Status |"
	echo "|--------|-------|--------|"
	echo "| CPU (5m avg) | ${cpu}% | $(status_label "$cpu" 70 90) |"
	echo "| Memory | ${mem}% (${mem_free_gb}/${mem_total_gb} GB free) | $(status_label "$mem" 80 95) |"
	echo "| Disk / | ${disk_root}% | $(status_label "$disk_root" 80 90) |"
	echo "| Disk /home | ${disk_home}% | $(status_label "$disk_home" 80 90) |"
	echo "| Load (15m) | ${load} | ok |"

	_CPU="$cpu"
	_MEM="$mem"
	_DISK_ROOT="$disk_root"
	_DISK_HOME="$disk_home"
}

collect_loki_errors() {
	section "Log Error Counts (Loki, 24h)"

	if [[ "$HAS_LOKI" != "true" ]]; then
		echo "[unavailable] Loki not enabled."
		return
	fi

	local start errors
	start=$(epoch_hours_ago 24)

	if [[ -z "$start" ]]; then
		echo "[unavailable] Could not compute time range."
		return
	fi

	errors=$(query_loki 'sum by (unit) (count_over_time({job="systemd-journal"} |~ "(?i)error|fail|panic" [24h]))' "$start")

	if json_is_empty "$errors"; then
		echo "No error logs found in Loki (24h)."
	else
		echo "| Unit | Error Lines |"
		echo "|------|-------------|"
		echo "$errors" | jq -r '.[] | "| \(.metric.unit // "unknown") | \(.values | last | .[1]) |"' 2>/dev/null || echo "Parse error."
	fi
}

collect_netdata_alarms() {
	section "Active Alarms (Netdata)"

	if [[ "$HAS_NETDATA" != "true" ]]; then
		echo "[unavailable] Netdata not enabled."
		return
	fi

	local alarms
	alarms=$(query_api "http://127.0.0.1:19999/api/v1/alarms?active")

	if [[ -z "$alarms" ]]; then
		echo "[unavailable] Could not reach Netdata."
		return
	fi

	local alarm_count
	alarm_count=$(echo "$alarms" | jq '.alarms | length' 2>/dev/null || echo "0")

	if [[ "$alarm_count" == "0" ]]; then
		echo "No active alarms."
	else
		echo "| Alarm | Status | Value |"
		echo "|-------|--------|-------|"
		echo "$alarms" | jq -r '.alarms | to_entries[] | "| \(.value.name) (\(.value.chart)) | \(.value.status) | \(.value.value) |"' 2>/dev/null
	fi

	_NETDATA_ALARMS="${alarm_count:-0}"
}

collect_scrutiny_health() {
	section "Disk Health (SMART)"

	if [[ "$HAS_SCRUTINY" != "true" ]]; then
		echo "[unavailable] Scrutiny not enabled."
		return
	fi

	local summary
	summary=$(query_api "http://127.0.0.1:8080/api/summary")

	if [[ -z "$summary" ]]; then
		echo "[unavailable] Could not reach Scrutiny."
		return
	fi

	local devices
	devices=$(echo "$summary" | jq -r '.data.summary // empty' 2>/dev/null)

	if json_is_empty "$devices"; then
		echo "No disk data available."
		return
	fi

	local failing=0

	echo "| Drive | Status | Temp |"
	echo "|-------|--------|------|"
	echo "$devices" | jq -r '
        to_entries[] |
        "| \(.value.device.device_name) | \(if .value.device.device_status == 0 then "PASSED" else "FAILING" end) | \(if .value.temp then "\(.value.temp)C" else "N/A" end) |"
    ' 2>/dev/null

	failing=$(echo "$devices" | jq '[to_entries[] | select(.value.device.device_status != 0)] | length' 2>/dev/null || echo "0")
	_SMART_FAILING="${failing:-0}"
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

	echo "| Interface | Today | Month |"
	echo "|-----------|-------|-------|"

	echo "$vndata" | jq -r '
        .interfaces[]? |
        .name as $name |
        (.traffic.day[-1]? |
            ((.rx + .tx) / 1073741824 * 100 | round / 100)) as $today |
        "| \($name) | \($today // "N/A") GB | — |"
    ' 2>/dev/null || echo "| — | parse error | — |"
}

collect_security() {
	section "Security"

	local items=()

	if [[ "$HAS_FAIL2BAN" == "true" ]] && command -v fail2ban-client &>/dev/null; then
		local banned total_bans
		banned=$(safe_cmd sudo fail2ban-client status sshd 2>/dev/null |
			grep "Currently banned" | awk '{print $NF}') || banned="?"
		total_bans=$(safe_cmd sudo fail2ban-client status sshd 2>/dev/null |
			grep "Total banned" | awk '{print $NF}') || total_bans="?"
		items+=("- fail2ban: ${banned:-0} currently banned, ${total_bans:-0} total bans (sshd)")
		_FAIL2BAN_BANNED="${banned:-0}"
	else
		items+=("- fail2ban: [unavailable]")
		_FAIL2BAN_BANNED="0"
	fi

	local lynis_output
	lynis_output=$(safe_cmd journalctl -u security-audit --no-pager -n 50 --since "-7d" 2>/dev/null)
	if [[ -n "$lynis_output" ]]; then
		local score
		score=$(echo "$lynis_output" | grep -oP 'Hardening index : \K[0-9]+' | tail -1 || echo "")
		if [[ -n "$score" ]]; then
			items+=("- Lynis audit score: ${score}/100")
		else
			items+=("- Lynis: no recent audit score found")
		fi
	else
		items+=("- Lynis: [unavailable]")
	fi

	if [[ "$HAS_OPENSNITCH" == "true" ]]; then
		local blocked
		blocked=$(safe_cmd journalctl -u opensnitchd --no-pager --since "-24h" -o json 2>/dev/null |
			jq -rs '[.[] | select(.MESSAGE? | test("blocked"; "i"))] | length' 2>/dev/null || echo "0")
		items+=("- OpenSnitch: ${blocked:-0} blocked connections (24h)")
	else
		items+=("- OpenSnitch: [unavailable]")
	fi

	if command -v systemd-analyze &>/dev/null; then
		local exposed
		exposed=$(safe_cmd systemd-analyze security --no-pager 2>/dev/null |
			awk '$NF == "EXPOSED" || $NF == "UNSAFE" {count++} END {print count+0}') || exposed="0"
		items+=("- systemd unit hardening: ${exposed} units rated EXPOSED/UNSAFE")
	fi

	printf '%s\n' "${items[@]}"
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

	local log_dir="${HOME:-/home/${REPORT_USER}}/.local/share/opencode/log"

	if [[ ! -d "$log_dir" ]]; then
		echo "No agent logs found."
		return
	fi

	local errors
	errors=$(safe_cmd grep -rihl "error\|panic\|fatal" "$log_dir"/*.log 2>/dev/null | wc -l || echo "0")
	local recent_errors
	recent_errors=$(safe_cmd find "$log_dir" -name "*.log" -mtime -1 -exec grep -il "error\|panic\|fatal" {} \; 2>/dev/null | wc -l || echo "0")

	echo "- Log files with errors: ${errors}"
	echo "- Files with errors (last 24h): ${recent_errors}"
}
