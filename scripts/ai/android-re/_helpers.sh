#!/usr/bin/env bash
# Shared helper functions for Android RE scripts.
# Source this file after sourcing logging.sh.

error_exit() {
	log_error "$1"
	exit "${2:-1}"
}

need_cmd() {
	local name="$1"
	command -v "$name" >/dev/null 2>&1 || error_exit "missing command: ${name}"
}

need_file() {
	local path="$1"
	[[ -e "$path" ]] || error_exit "missing file: ${path}"
}
