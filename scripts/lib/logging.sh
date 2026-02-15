#!/usr/bin/env bash
# Shared logging library for shell scripts - provides colored output and timestamped logging

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Simple colored output functions (emoji style)
print_info() {
	echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
	echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
	echo -e "${RED}✗${NC} $1"
}

# Timestamped logging functions (with optional file logging)
log_info() {
	local msg="$*"
	if [[ -n "${LOG_FILE:-}" ]]; then
		echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $msg" | tee -a "$LOG_FILE"
	else
		echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $msg"
	fi
}

log_warning() {
	local msg="$*"
	if [[ -n "${LOG_FILE:-}" ]]; then
		echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $msg" | tee -a "$LOG_FILE" >&2
	else
		echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $msg" >&2
	fi
}

log_error() {
	local msg="$*"
	if [[ -n "${LOG_FILE:-}" ]]; then
		echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $msg" | tee -a "$LOG_FILE" >&2
	else
		echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $msg" >&2
	fi
}

log_success() {
	local msg="$*"
	if [[ -n "${LOG_FILE:-}" ]]; then
		echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $msg" | tee -a "$LOG_FILE"
	else
		echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $msg"
	fi
}
