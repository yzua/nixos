#!/usr/bin/env bash
# Shared logging library for shell scripts - provides colored output and timestamped logging

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_colored() {
	local color="$1"
	local icon="$2"
	local message="$3"
	printf '%b\n' "${color}${icon}${NC} ${message}"
}

log_with_level() {
	local color="$1"
	local level="$2"
	local stream="$3"
	shift 3

	local msg="$*"
	local timestamp
	timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local formatted="${color}[${level}]${NC} ${timestamp} - ${msg}"

	if [[ "$stream" == "stderr" ]]; then
		printf '%b\n' "$formatted" >&2
	else
		printf '%b\n' "$formatted"
	fi
}

# Simple colored output functions (emoji style)
print_info() {
	print_colored "$BLUE" "ℹ" "$1"
}

print_success() {
	print_colored "$GREEN" "✓" "$1"
}

print_warning() {
	print_colored "$YELLOW" "⚠" "$1"
}

print_error() {
	print_colored "$RED" "✗" "$1"
}

# Timestamped logging functions (with optional file logging)
log_info() {
	log_with_level "$BLUE" "INFO" "stdout" "$@"
}

log_warning() {
	log_with_level "$YELLOW" "WARNING" "stderr" "$@"
}

log_error() {
	log_with_level "$RED" "ERROR" "stderr" "$@"
}

log_success() {
	log_with_level "$GREEN" "SUCCESS" "stdout" "$@"
}
