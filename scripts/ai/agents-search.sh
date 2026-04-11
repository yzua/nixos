#!/usr/bin/env bash
# Find directories that genuinely need AGENTS.md guidance files.
#
# Smart heuristic: directories covered by a parent AGENTS.md need higher
# complexity to warrant their own (the parent already documents them).
# Uncovered directories get the base threshold.
#
# Usage:
#   agents-search.sh [PATH]              # smart mode (recommended)
#   agents-search.sh --all [PATH]        # show everything that passes base threshold
#   agents-search.sh -t 5 -l 500 [PATH]  # custom base thresholds
#   agents-search.sh --json [PATH]       # machine-readable output
#
# Exit codes: 0 always (this is a reporting tool, not a gate).

set -euo pipefail

# --- Defaults ---
BASE_FILE_THRESHOLD=4
BASE_LINE_THRESHOLD=250
# When a parent directory already has AGENTS.md, require BOTH thresholds met
# at these higher values — parent coverage means the child only needs its own
# guide if it's substantially complex.
DEEP_FILE_THRESHOLD=5
DEEP_LINE_THRESHOLD=400
GUIDE_NAME="AGENTS.md"
SCAN_PATH="."
OUTPUT_MODE="table" # table | json
SHOW_MODE="needed"  # needed | all

# --- Args ---
while [[ $# -gt 0 ]]; do
	case "$1" in
	-t)
		BASE_FILE_THRESHOLD="${2:?missing value for -t}"
		shift 2
		;;
	-l)
		BASE_LINE_THRESHOLD="${2:?missing value for -l}"
		shift 2
		;;
	--all)
		SHOW_MODE="all"
		shift
		;;
	--json)
		OUTPUT_MODE="json"
		shift
		;;
	-h | --help)
		sed -n '2,/^$/p' "$0" | sed 's/^# //' | sed 's/^#//'
		exit 0
		;;
	-*)
		echo "Unknown flag: $1" >&2
		echo "Usage: $(basename "$0") [--all] [-t N] [-l N] [--json] [PATH]" >&2
		exit 1
		;;
	*)
		SCAN_PATH="$1"
		shift
		;;
	esac
done

SCAN_PATH="$(cd "$SCAN_PATH" && pwd)"

if [[ ! -d "$SCAN_PATH" ]]; then
	echo "Error: '$SCAN_PATH' is not a directory" >&2
	exit 1
fi

# File extensions that count as "source" for complexity measurement.
# Built as an array so globs stay literal (not expanded by the shell).
SOURCE_EXTS=(nix sh py js ts tsx jsx go rs lua toml yaml yml json qml css)

# --- Enumerate candidate directories ---
# Use git ls-files when available — respects .gitignore, global gitignore,
# and .git/info/exclude. Falls back to raw find for non-git trees.
enumerate_dirs() {
	if git -C "$SCAN_PATH" rev-parse --git-dir >/dev/null 2>&1; then
		git -C "$SCAN_PATH" ls-files -z |
			awk -v RS='\0' '
				function dirname(f,    n, parts, d, result) {
					n = split(f, parts, "/")
					result = parts[1]
					seen[result] = 1
					for (d = 2; d < n; d++) {
						result = result "/" parts[d]
						seen[result] = 1
					}
				}
				{ dirname($0) }
				END {
					for (d in seen)
						printf "%s/%s\0", "'"$SCAN_PATH"'", d
				}
			' |
			LC_ALL=C sort -z -u
	else
		find "$SCAN_PATH" -type d -print0 2>/dev/null |
			grep -z -v -E '(^|/)\.git(/|$)' |
			grep -z -v -E '(^|/)node_modules(/|$)' |
			grep -z -v -E '(^|/)vendor(/|$)' |
			grep -z -v -E '(^|/)__pycache__(/|$)' |
			grep -z -v -E '(^|/)\.venv(/|$)' |
			grep -z -v -E '(^|/)result(-?[0-9]*)?$'
	fi
}

# --- Check if a directory has a parent with AGENTS.md ---
# Walks up from $rel_dir checking each ancestor for $GUIDE_NAME.
has_parent_guide() {
	local rel_dir="$1"
	local path="$rel_dir"
	while [[ "$path" == */* ]]; do
		path="${path%/*}"
		if [[ -f "$SCAN_PATH/$path/$GUIDE_NAME" ]]; then
			return 0
		fi
	done
	return 1
}

# --- Collect directory data ---
# Each entry: rel_dir file_count file_lines sub_dir_count has_guide parent_covered
declare -a results=()

while IFS= read -r -d '' dir; do
	[[ -d "$dir" ]] || continue

	rel_dir="${dir#"$SCAN_PATH"/}"

	# Count source files in this directory (not recursive)
	file_count=0
	file_lines=0
	while IFS= read -r -d '' f; do
		((file_count++)) || true
		lines=$(wc -l <"$f")
		((file_lines += lines)) || true
	done < <(
		name_args=()
		for ext in "${SOURCE_EXTS[@]}"; do
			((${#name_args[@]} > 0)) && name_args+=(-o)
			name_args+=(-name "*.${ext}")
		done
		find "$dir" -maxdepth 1 -type f \( "${name_args[@]}" \) -print0 2>/dev/null
	)

	# Count subdirectories (excluding .)
	sub_dir_count=$(find "$dir" -maxdepth 1 -mindepth 1 -type d | wc -l)

	# Check for guide file
	has_guide="MISSING"
	if [[ -f "$dir/$GUIDE_NAME" ]]; then
		has_guide="HAS_GUIDE"
	fi

	# Check parent coverage
	parent_covered="no"
	if has_parent_guide "$rel_dir"; then
		parent_covered="yes"
	fi

	# Apply threshold based on mode and parent coverage
	if [[ "$SHOW_MODE" == "all" ]]; then
		# --all: just use base thresholds (either file OR line)
		[[ $file_count -lt $BASE_FILE_THRESHOLD && $file_lines -lt $BASE_LINE_THRESHOLD ]] && continue
	else
		# Smart mode: different thresholds based on parent coverage
		if [[ "$parent_covered" == "yes" ]]; then
			# Parent has AGENTS.md — child needs BOTH deep thresholds met
			# to justify its own guide (parent already covers it).
			[[ $file_count -ge $DEEP_FILE_THRESHOLD && $file_lines -ge $DEEP_LINE_THRESHOLD ]] || continue
		else
			# No parent coverage — use base thresholds (either file OR line).
			[[ $file_count -lt $BASE_FILE_THRESHOLD && $file_lines -lt $BASE_LINE_THRESHOLD ]] && continue
		fi
	fi

	results+=("${rel_dir}" "${file_count}" "${file_lines}" "${sub_dir_count}" "${has_guide}" "${parent_covered}")
done < <(enumerate_dirs)

# --- Sort by line count descending ---
total=${#results[@]}
n_entries=$((total / 6))

declare -a sort_indices=()
for ((i = 0; i < n_entries; i++)); do
	idx=$((i * 6))
	lines=${results[$((idx + 2))]}
	sort_indices+=("$(printf '%010d' "$lines") $i")
done

if [[ ${#sort_indices[@]} -gt 0 ]]; then
	mapfile -t sorted < <(printf '%s\n' "${sort_indices[@]}" | sort -rn)
else
	sorted=()
fi

# --- Output ---
if [[ "$OUTPUT_MODE" == "json" ]]; then
	echo "["
	first=true
	for entry in "${sorted[@]}"; do
		[[ "$entry" =~ ^[0-9]+\ (.*)$ ]] && i=${BASH_REMATCH[1]}
		idx=$((i * 6))
		rel_dir="${results[$idx]}"
		file_count="${results[$((idx + 1))]}"
		file_lines="${results[$((idx + 2))]}"
		sub_dir_count="${results[$((idx + 3))]}"
		has_guide="${results[$((idx + 4))]}"
		parent_covered="${results[$((idx + 5))]}"

		"$first" && first=false || echo ","

		cat <<ENTRY
  {
    "path": "${rel_dir}",
    "files": ${file_count},
    "lines": ${file_lines},
    "subdirs": ${sub_dir_count},
    "status": "${has_guide}",
    "parent_covered": "${parent_covered}"
  }
ENTRY
	done
	echo ""
	echo "]"
else
	# Table output
	printf "\n%-55s %5s %6s %7s  %-9s %s\n" "DIRECTORY" "FILES" "LINES" "SUBDIRS" "STATUS" "PARENT"
	printf "%-55s %5s %6s %7s  %-9s %s\n" "-------------------------------------------------------" "-----" "------" "-------" "---------" "----------"

	missing=0
	has=0
	for entry in "${sorted[@]}"; do
		[[ "$entry" =~ ^[0-9]+\ (.*)$ ]] && i=${BASH_REMATCH[1]}
		idx=$((i * 6))
		rel_dir="${results[$idx]}"
		file_count="${results[$((idx + 1))]}"
		file_lines="${results[$((idx + 2))]}"
		sub_dir_count="${results[$((idx + 3))]}"
		has_guide="${results[$((idx + 4))]}"
		parent_covered="${results[$((idx + 5))]}"

		if [[ "$has_guide" == "HAS_GUIDE" ]]; then
			status_str="\033[0;32m✓ has\033[0m"
			((has++)) || true
		else
			status_str="\033[0;31m✗ needs\033[0m"
			((missing++)) || true
		fi

		if [[ "$parent_covered" == "yes" ]]; then
			parent_str="\033[0;33mcovered\033[0m"
		else
			parent_str="\033[0;34muncovered\033[0m"
		fi

		printf "%-55s %5d %6d %7d  " "$rel_dir" "$file_count" "$file_lines" "$sub_dir_count"
		echo -e "$status_str  $parent_str"
	done

	echo ""
	if [[ "$SHOW_MODE" == "all" ]]; then
		echo "Mode: all (base: ≥${BASE_FILE_THRESHOLD} files or ≥${BASE_LINE_THRESHOLD} lines)"
	else
		echo "Mode: needed (uncovered: ≥${BASE_FILE_THRESHOLD} files or ≥${BASE_LINE_THRESHOLD} lines | covered: ≥${DEEP_FILE_THRESHOLD} files AND ≥${DEEP_LINE_THRESHOLD} lines)"
	fi
	echo "Total: $((has + missing)) directories — ${has} with ${GUIDE_NAME}, ${missing} need one"
fi
