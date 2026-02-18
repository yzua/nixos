#!/usr/bin/env bash
# Focused tests for api-quota.sh helper behavior.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/api-quota.sh"

assert_eq() {
	local got="$1"
	local want="$2"
	local msg="$3"
	if [[ "$got" != "$want" ]]; then
		echo "FAIL: ${msg} (got='${got}', want='${want}')"
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

assert_cmd_fail() {
	local msg="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		echo "FAIL: ${msg} (expected failure)"
		exit 1
	fi
	echo "PASS: ${msg}"
}

assert_eq "$(numeric_pct_to_remaining 34.6)" "65" "remaining percent rounds used value"
assert_eq "$(numeric_pct_to_remaining 120)" "0" "remaining percent clamps values above 100"
assert_eq "$(numeric_pct_to_remaining -5)" "100" "remaining percent clamps values below 0"
assert_cmd_fail "remaining percent rejects non-numeric values" numeric_pct_to_remaining "nope"

future_epoch=$(( $(date +%s) + 3600 ))
tip_epoch="$(build_window_tip "OpenAI Codex" "23.4" "${future_epoch}" "45.0" "epoch")"
assert_contains "$tip_epoch" "OpenAI Codex" "tooltip contains provider title"
assert_contains "$tip_epoch" "5h used: 23.4%" "tooltip contains 5h usage line"
assert_contains "$tip_epoch" "7d used: 45.0% (left 55%)" "tooltip contains 7d usage line"
assert_contains "$tip_epoch" "Reset:" "tooltip adds reset string for epoch timestamps"

tip_bad_reset="$(build_window_tip "OpenAI Codex" "23.4" "invalid" "45.0" "epoch")"
assert_not_contains "$tip_bad_reset" "Reset:" "tooltip omits reset on invalid timestamp"

tmp_cache="$(mktemp -d)"
# shellcheck disable=SC2034
CACHE_DIR="$tmp_cache"
# shellcheck disable=SC2034
CACHE_TTL=3600
write_cache "sample" '{"ok":true}'
assert_eq "$(read_cache sample)" '{"ok":true}' "read_cache returns fresh cached payload"
# shellcheck disable=SC2034
CACHE_TTL=0
assert_cmd_fail "read_cache rejects stale cache entries" read_cache "sample"
rm -rf "$tmp_cache"

echo "All api-quota helper tests passed."
