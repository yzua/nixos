#!/usr/bin/env bash
# Observability collectors for system report generation.

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

	if ! require_enabled_feature "$HAS_NETDATA" "Netdata"; then
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

	print_table_header "| Metric | Value | Status |" "|--------|-------|--------|"
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

	if ! require_enabled_feature "$HAS_LOKI" "Loki"; then
		return
	fi

	local start errors
	start=$(epoch_hours_ago 24)

	if [[ -z "$start" ]]; then
		echo "[unavailable] Could not compute time range."
		return
	fi

	errors=$(query_loki 'sum by (unit) (count_over_time({job="systemd-journal",level=~"err|error|crit|alert|emerg"} |~ "(?i)(error|fail|panic)" [24h]))' "$start")

	if json_is_empty "$errors"; then
		echo "No error logs found in Loki (24h)."
	else
		print_table_header "| Unit | Error Lines |" "|------|-------------|"
		echo "$errors" | jq -r '.[] | "| \(.metric.unit // "unknown") | \(.values | last | .[1]) |"' 2>/dev/null || echo "Parse error."
	fi
}

collect_netdata_alarms() {
	section "Active Alarms (Netdata)"

	if ! require_enabled_feature "$HAS_NETDATA" "Netdata"; then
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
		print_table_header "| Alarm | Status | Value |" "|-------|--------|-------|"
		echo "$alarms" | jq -r '.alarms | to_entries[] | "| \(.value.name) (\(.value.chart)) | \(.value.status) | \(.value.value) |"' 2>/dev/null
	fi

	_NETDATA_ALARMS="${alarm_count:-0}"
}

collect_scrutiny_health() {
	section "Disk Health (SMART)"

	if ! require_enabled_feature "$HAS_SCRUTINY" "Scrutiny"; then
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

	print_table_header "| Drive | Status | Temp |" "|-------|--------|------|"
	echo "$devices" | jq -r '
        to_entries[] |
        "| \(.value.device.device_name) | \(if .value.device.device_status == 0 then "PASSED" else "FAILING" end) | \(if .value.temp then "\(.value.temp)C" else "N/A" end) |"
    ' 2>/dev/null

	failing=$(echo "$devices" | jq '[to_entries[] | select(.value.device.device_status != 0)] | length' 2>/dev/null || echo "0")
	_SMART_FAILING="${failing:-0}"
}
