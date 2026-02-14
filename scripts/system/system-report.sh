#!/usr/bin/env bash
# Unified system health report generator.

set -euo pipefail

OUTPUT_DIR="${SYSTEM_REPORT_DIR:-/var/lib/system-report}"
HISTORY_DIR="${OUTPUT_DIR}/history"
MODE="${1:-full}"
REPORT_USER="${REPORT_USER:-}"
HOSTNAME="$(hostname)"
TIMESTAMP="$(date -Iseconds)"
DATE_SHORT="$(date +%Y-%m-%dT%H:%M:%S)"

HAS_PROMETHEUS="${HAS_PROMETHEUS:-false}"
HAS_LOKI="${HAS_LOKI:-false}"
HAS_NETDATA="${HAS_NETDATA:-false}"
HAS_SCRUTINY="${HAS_SCRUTINY:-false}"
HAS_OPENSNITCH="${HAS_OPENSNITCH:-false}"
HAS_FAIL2BAN="${HAS_FAIL2BAN:-false}"

# shellcheck disable=SC2034
CURL_TIMEOUT=3
# shellcheck disable=SC2034
CMD_TIMEOUT=5

_CPU=0 _MEM=0 _DISK_ROOT=0 _DISK_HOME=0
_SMART_FAILING=0 _FAIL2BAN_BANNED=0 _NETDATA_ALARMS=0 _BUILD_RATE=0

# shellcheck source=/dev/null
source "$(dirname "$0")/report-helpers.sh"
# shellcheck source=/dev/null
source "$(dirname "$0")/report-collectors.sh"

generate_errors_report() {
	{
		echo "# System Error Report"
		echo "Generated: ${TIMESTAMP}"
		echo "Host: ${HOSTNAME}"
		echo "Mode: errors"
		collect_systemd_errors 1
	} | tee "${OUTPUT_DIR}/latest-errors.md"

	local hist_file="${HISTORY_DIR}/errors-${DATE_SHORT}.md"
	cp "${OUTPUT_DIR}/latest-errors.md" "$hist_file"
}

generate_full_report() {
	{
		echo "# System Health Report"
		echo "Generated: ${TIMESTAMP}"
		echo "Host: ${HOSTNAME}"
		echo "Mode: full"
		collect_systemd_errors 24
		collect_systemd_timers
		collect_resource_metrics
		collect_loki_errors
		collect_netdata_alarms
		collect_scrutiny_health
		collect_network_traffic
		collect_security
		collect_nix_builds
		collect_ai_agents
	} | tee "${OUTPUT_DIR}/latest-full.md"

	generate_json_summary >"${OUTPUT_DIR}/summary.json"

	local hist_file="${HISTORY_DIR}/full-${DATE_SHORT}.md"
	cp "${OUTPUT_DIR}/latest-full.md" "$hist_file"
}

view_report() {
	local file="${OUTPUT_DIR}/latest-full.md"
	if [[ ! -f "$file" ]]; then
		echo "No full report found. Run: sudo system-report full"
		exit 1
	fi
	if command -v bat &>/dev/null; then
		bat --style=auto --language=markdown "$file"
	else
		cat "$file"
	fi
}

view_errors_report() {
	local file="${OUTPUT_DIR}/latest-errors.md"
	if [[ ! -f "$file" ]]; then
		echo "No error report found. Run: sudo system-report errors"
		exit 1
	fi
	if command -v bat &>/dev/null; then
		bat --style=auto --language=markdown "$file"
	else
		cat "$file"
	fi
}

mkdir -p "$OUTPUT_DIR" "$HISTORY_DIR"

case "$MODE" in
errors) generate_errors_report ;;
full) generate_full_report ;;
view) view_report ;;
view-errors) view_errors_report ;;
*)
	echo "Usage: system-report {errors|full|view|view-errors}"
	exit 1
	;;
esac
