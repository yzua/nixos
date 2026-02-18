#!/usr/bin/env bash
# Focused tests for report helper and collector behavior.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/report-helpers.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/report-collectors.sh"

assert_true() {
	local msg="$1"
	shift
	if ! "$@" >/dev/null 2>&1; then
		echo "FAIL: ${msg}"
		exit 1
	fi
	echo "PASS: ${msg}"
}

assert_false() {
	local msg="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		echo "FAIL: ${msg}"
		exit 1
	fi
	echo "PASS: ${msg}"
}

assert_contains() {
	local haystack="$1"
	local needle="$2"
	local msg="$3"
	if [[ "$haystack" != *"$needle"* ]]; then
		echo "FAIL: ${msg} (missing '${needle}')"
		exit 1
	fi
	echo "PASS: ${msg}"
}

assert_not_contains() {
	local haystack="$1"
	local needle="$2"
	local msg="$3"
	if [[ "$haystack" == *"$needle"* ]]; then
		echo "FAIL: ${msg} (unexpected '${needle}')"
		exit 1
	fi
	echo "PASS: ${msg}"
}

assert_regex() {
	local value="$1"
	local pattern="$2"
	local msg="$3"
	if [[ ! "$value" =~ $pattern ]]; then
		echo "FAIL: ${msg} (value='${value}')"
		exit 1
	fi
	echo "PASS: ${msg}"
}

assert_true "json_is_empty handles empty string" json_is_empty ""
assert_true "json_is_empty handles null" json_is_empty "null"
assert_true "json_is_empty handles []" json_is_empty "[]"
assert_true "json_is_empty handles {}" json_is_empty "{}"
assert_false "json_is_empty rejects non-empty object" json_is_empty '{"value":1}'

epoch_24h="$(epoch_hours_ago 24)"
assert_regex "$epoch_24h" '^[0-9]+$' "epoch_hours_ago returns numeric epoch"
iso_7d="$(iso_days_ago 7)"
assert_contains "$iso_7d" "T" "iso_days_ago returns ISO timestamp"

safe_cmd() {
	if [[ "$1" == "systemctl" && "$2" == "list-timers" ]]; then
		cat <<'EOF'
Mon 2026-02-16 09:00:00 UTC 1h left Mon 2026-02-16 08:00:00 UTC 2h ago apt-daily.timer apt-daily.service
Tue 2026-02-17 01:00:00 UTC 5h left Mon 2026-02-16 20:00:00 UTC 6h ago fstrim.timer fstrim.service
EOF
		return 0
	fi
	return 1
}

timers_output="$(collect_systemd_timers)"
assert_contains "$timers_output" "| apt-daily.timer | Mon 2026-02-16 09:00:00 |" "timers table uses timer unit name"
assert_contains "$timers_output" "| fstrim.timer | Tue 2026-02-17 01:00:00 |" "timers table includes second timer"
assert_not_contains "$timers_output" "| apt-daily.service |" "timers table does not use activates service as timer name"

echo "All system report helper/collector tests passed."
