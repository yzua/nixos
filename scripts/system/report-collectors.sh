#!/usr/bin/env bash
# Collector module compatibility shim for system-report.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/report-collectors-core.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/report-collectors-observability.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/report-collectors-security.sh"
