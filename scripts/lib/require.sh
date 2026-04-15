#!/usr/bin/env bash
# Shared command/file requirement helpers.
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

# Check tool availability and report status (does not exit on missing).
check_tool() {
	local tool="$1"
	if command -v "$tool" >/dev/null 2>&1; then
		log_success "tool present: ${tool} -> $(command -v "$tool")"
	else
		log_warning "tool missing: ${tool}"
	fi
}
