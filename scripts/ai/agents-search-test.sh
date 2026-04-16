#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/test-helpers.sh"

SEARCH="${SCRIPT_DIR}/agents-search.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# --- Helper: create source files in a directory ---
# Usage: make_files <dir> <ext> <count> <lines_per_file>
make_files() {
	local dir="$TMPDIR/$1"
	local ext="$2"
	local count="$3"
	local lines="$4"
	mkdir -p "$dir"
	local line
	line="$(printf '%0.sx' $(seq 1 80))"
	for ((i = 0; i < count; i++)); do
		{
			for ((j = 0; j < lines; j++)); do
				echo "$line"
			done
		} > "$dir/file${i}.${ext}"
	done
}

# --- Test: --help exits 0 and shows usage ---
help_output="$("$SEARCH" --help 2>&1)" || true
assert_contains "$help_output" "Usage:" "--help shows usage header"
assert_contains "$help_output" "agents-search.sh" "--help mentions script name"

# --- Test: unknown flag exits non-zero ---
assert_false "unknown flag rejects" "$SEARCH" --bogus 2>/dev/null

# --- Test: base threshold — directory below both thresholds is filtered ---
# Default base: 4 files OR 250 lines. With 2 files × 10 lines = 20 lines — below both.
make_files "small" "nix" 2 10
output="$("$SEARCH" "$TMPDIR" 2>/dev/null)"
assert_not_contains "$output" "small" "below base thresholds filtered in smart mode"

# --- Test: base threshold — meets file count but not lines (OR logic) ---
# 5 files × 10 lines = 50 lines. file_count=5 ≥ 4, so it passes via OR.
make_files "file_thresh" "nix" 5 10
output="$("$SEARCH" "$TMPDIR" 2>/dev/null)"
assert_contains "$output" "file_thresh" "meets base file threshold shown in smart mode (OR logic)"

# --- Test: base threshold — meets line count but not files (OR logic) ---
# 1 file × 300 lines = 300 lines. lines ≥ 250, so it passes via OR.
make_files "line_thresh" "sh" 1 300
output="$("$SEARCH" "$TMPDIR" 2>/dev/null)"
assert_contains "$output" "line_thresh" "meets base line threshold shown in smart mode (OR logic)"

# --- Test: parent coverage — covered dir needs BOTH deep thresholds ---
# Create parent AGENTS.md, then child with 6 files × 100 lines (600 lines ≥ 400 but only 6 files).
# Actually 6 ≥ 5 files AND 600 ≥ 400 lines — passes deep. Let's test the rejection case.
mkdir -p "$TMPDIR/parent"
touch "$TMPDIR/parent/AGENTS.md"
make_files "parent/child" "nix" 4 500
output="$("$SEARCH" "$TMPDIR" 2>/dev/null)"
assert_not_contains "$output" "parent/child" "covered dir below deep file threshold filtered (AND logic)"

# --- Test: parent coverage — covered dir meets BOTH deep thresholds ---
make_files "parent/deep" "nix" 6 500
output="$("$SEARCH" "$TMPDIR" 2>/dev/null)"
assert_contains "$output" "parent/deep" "covered dir meeting both deep thresholds shown"

# --- Test: --all uses base thresholds for everything (ignores parent coverage) ---
output_all="$("$SEARCH" --all "$TMPDIR" 2>/dev/null)"
# parent/child has 4 files < 5 but 500 lines ≥ 250 — passes base OR in --all mode
assert_contains "$output_all" "parent/child" "--all shows covered dir that passes base threshold"

# --- Test: --json produces valid array structure ---
make_files "json_test" "nix" 5 300
json_output="$("$SEARCH" --json "$TMPDIR" 2>/dev/null)"
assert_contains "$json_output" '"path":' "--json contains path field"
assert_contains "$json_output" '"files":' "--json contains files field"
assert_contains "$json_output" '"lines":' "--json contains lines field"
assert_regex "$json_output" '^\s*\[' "--json starts with array bracket"

# --- Test: custom thresholds via -t and -l ---
# With -t 10, the file_thresh dir (5 files) should be filtered out
output_high_thresh="$("$SEARCH" -t 10 -l 10000 "$TMPDIR" 2>/dev/null)"
assert_not_contains "$output_high_thresh" "file_thresh" "custom -t threshold filters dir with fewer files"

# --- Test: non-directory argument exits with error ---
assert_false "non-directory path errors" "$SEARCH" "$TMPDIR/nonexistent" 2>/dev/null

# --- Test: has_parent_guide detects nested coverage ---
mkdir -p "$TMPDIR/nested/a/b/c"
touch "$TMPDIR/nested/AGENTS.md"
make_files "nested/a/b/c/deep" "nix" 6 500
output_nested="$("$SEARCH" "$TMPDIR" 2>/dev/null)"
assert_contains "$output_nested" "nested/a/b/c/deep" "deeply nested dir under parent guide uses deep thresholds"

echo "All agents-search tests passed."
