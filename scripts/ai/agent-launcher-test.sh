#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/test-helpers.sh"

launcher_output="$({
	# shellcheck disable=SC1091
	AI_AGENT_LAUNCHER_SOURCE_ONLY=1 source "${SCRIPT_DIR}/agent-launcher.sh"
	workflow_display_lines
} 2>&1)"

assert_contains "${launcher_output}" "commit split (cm) — Splits working tree into logical commits with validated, minimal staging." "workflow picker shows commit split label"
assert_contains "${launcher_output}" "refactor maintainability (rf) — Improves structure and clarity without changing behavior, APIs, or workflows." "workflow picker shows refactor label"
assert_contains "${launcher_output}" "dependency upgrade (du) — Upgrades dependencies safely, handles breaking changes, validates compatibility, reports blockers." "workflow picker shows dependency upgrade label"

commit_suffix="$({
	# shellcheck disable=SC1091
	AI_AGENT_LAUNCHER_SOURCE_ONLY=1 source "${SCRIPT_DIR}/agent-launcher.sh"
	workflow_suffix_from_selection "commit split (cm) — Splits working tree into logical commits with validated, minimal staging."
} 2>&1)"
assert_eq "${commit_suffix}" "cm" "workflow label maps back to cm suffix"

none_suffix="$({
	# shellcheck disable=SC1091
	AI_AGENT_LAUNCHER_SOURCE_ONLY=1 source "${SCRIPT_DIR}/agent-launcher.sh"
	workflow_suffix_from_selection "none"
} 2>&1)"
assert_eq "${none_suffix}" "none" "none label maps back to none suffix"

echo "All agent launcher tests passed."
