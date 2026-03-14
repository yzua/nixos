#!/usr/bin/env bash
# Collector module compatibility shim for system-report.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CORE_COLLECTORS_PATH="${SYSTEM_REPORT_COLLECTORS_CORE:-${SCRIPT_DIR}/report-collectors-core.sh}"
OBSERVABILITY_COLLECTORS_PATH="${SYSTEM_REPORT_COLLECTORS_OBSERVABILITY:-${SCRIPT_DIR}/report-collectors-observability.sh}"
SECURITY_COLLECTORS_PATH="${SYSTEM_REPORT_COLLECTORS_SECURITY:-${SCRIPT_DIR}/report-collectors-security.sh}"

# shellcheck source=/dev/null
source "${CORE_COLLECTORS_PATH}"
# shellcheck source=/dev/null
source "${OBSERVABILITY_COLLECTORS_PATH}"
# shellcheck source=/dev/null
source "${SECURITY_COLLECTORS_PATH}"
