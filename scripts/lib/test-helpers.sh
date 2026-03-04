#!/usr/bin/env bash
# Shared test assertion library for shell scripts.
# Source this file in test scripts to use assertion functions.

# Assert two values are equal.
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

# Assert haystack contains needle (substring match).
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

# Assert haystack does NOT contain needle.
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

# Assert a command fails (returns non-zero).
assert_cmd_fail() {
	local msg="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		echo "FAIL: ${msg} (expected failure)"
		exit 1
	fi
	echo "PASS: ${msg}"
}

# Assert a command succeeds (returns zero).
assert_true() {
	local msg="$1"
	shift
	if ! "$@" >/dev/null 2>&1; then
		echo "FAIL: ${msg}"
		exit 1
	fi
	echo "PASS: ${msg}"
}

# Assert a command fails (alias for assert_cmd_fail with different signature).
assert_false() {
	local msg="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		echo "FAIL: ${msg}"
		exit 1
	fi
	echo "PASS: ${msg}"
}

# Assert value matches a regex pattern.
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
