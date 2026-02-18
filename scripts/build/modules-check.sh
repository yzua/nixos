#!/usr/bin/env bash
# modules-check.sh - Check for missing module imports in Nix configurations
# This script validates that all .nix files in directories with default.nix are properly imported

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

# Validate script dependencies
check_dependencies() {
	local deps=("awk" "find" "sort")
	for dep in "${deps[@]}"; do
		if ! command -v "$dep" >/dev/null 2>&1; then
			print_error "Required dependency '$dep' not found in PATH" >&2
			exit 1
		fi
	done
}

parse_imports() {
	local default_file="$1"

	# Extract:
	# 1) explicit .nix references anywhere in default.nix (including helper imports)
	# 2) directory entries from imports = [ ... ] lists.
	awk '
		function count_char(str, ch,    i, n) {
			n = 0
			for (i = 1; i <= length(str); i++) {
				if (substr(str, i, 1) == ch) {
					n += 1
				}
			}
			return n
		}

		function extract_nix_paths(line,    remaining, path) {
			remaining = line
			while (match(remaining, /\.\/[[:alnum:]_./-]+\.nix/)) {
				path = substr(remaining, RSTART + 2, RLENGTH - 2)
				print path
				remaining = substr(remaining, RSTART + RLENGTH)
			}
		}

		function extract_directory_imports(line,    remaining, path) {
			remaining = line
			while (match(remaining, /\.\/[[:alnum:]_./-]+/)) {
				path = substr(remaining, RSTART + 2, RLENGTH - 2)
				if (path !~ /\.nix$/) {
					print path
				}
				remaining = substr(remaining, RSTART + RLENGTH)
			}
		}

		{
			raw_line = $0
			extract_nix_paths(raw_line)

			line = raw_line
			sub(/#.*/, "", line)

			if (!in_imports) {
				if (line ~ /imports[[:space:]]*=/) {
					if (index(line, "[") > 0) {
						in_imports = 1
						bracket_depth = count_char(line, "[") - count_char(line, "]")
						extract_directory_imports(line)
						if (bracket_depth <= 0) {
							in_imports = 0
							bracket_depth = 0
						}
					} else {
						waiting_for_open_bracket = 1
					}
				} else if (waiting_for_open_bracket && index(line, "[") > 0) {
					in_imports = 1
					waiting_for_open_bracket = 0
					bracket_depth = count_char(line, "[") - count_char(line, "]")
					extract_directory_imports(line)
					if (bracket_depth <= 0) {
						in_imports = 0
						bracket_depth = 0
					}
				}
				next
			}

			extract_directory_imports(line)
			bracket_depth += count_char(line, "[") - count_char(line, "]")
			if (bracket_depth <= 0) {
				in_imports = 0
				bracket_depth = 0
			}
		}
	' "$default_file"
}

parse_manual_helpers() {
	local default_file="$1"

	awk '
		{
			line = $0
			lower_line = tolower(line)

			if (line ~ /#/ && lower_line ~ /imported manually/) {
				while (match(line, /\.\/[[:alnum:]_./-]+\.nix/)) {
					path = substr(line, RSTART + 2, RLENGTH - 2)
					sub(/^.*\//, "", path)
					print path
					line = substr(line, RSTART + RLENGTH)
				}
			}
		}
	' "$default_file"
}

main() {
	local error_count=0
	check_dependencies

	local -a defaults=()
	mapfile -t defaults < <(find . -type f -name default.nix | sort)

	if (( ${#defaults[@]} == 0 )); then
		print_warning "No default.nix files found." >&2
		return 0
	fi

	local default
	for default in "${defaults[@]}"; do
		local dir
		dir=$(dirname "$default")
		echo "⟳ Checking $default" >&2

		local -a imported=()
		mapfile -t imported < <(parse_imports "$default")

		local -a manual_helpers=()
		mapfile -t manual_helpers < <(parse_manual_helpers "$default")
		declare -A manual_helper_set=()
		local helper_name
		for helper_name in "${manual_helpers[@]}"; do
			manual_helper_set["$helper_name"]=1
		done

		declare -A imported_set=()
		local -a unique_imports=()
		local import_path
		for import_path in "${imported[@]}"; do
			[[ -n "$import_path" ]] || continue
			if [[ -z "${imported_set[$import_path]:-}" ]]; then
				imported_set["$import_path"]=1
				unique_imports+=("$import_path")
			fi
		done

		local -a local_modules=()
		mapfile -t local_modules < <(
			find "$dir" -maxdepth 1 -type f -name '*.nix' \
				! -name default.nix ! -name '_*.nix' -printf '%f\n' | sort
		)

		local module_file
		for module_file in "${local_modules[@]}"; do
			if [[ -n "${manual_helper_set[$module_file]:-}" ]]; then
				continue
			fi
			if [[ -z "${imported_set[$module_file]:-}" ]]; then
				echo "✗  Missing import: $dir/$module_file" >&2
				((error_count++))
			fi
		done

		for import_path in "${unique_imports[@]}"; do
			local resolved_path="${dir}/${import_path}"

			if [[ -f "$resolved_path" ]]; then
				continue
			fi

			if [[ -d "$resolved_path" ]]; then
				if [[ ! -f "${resolved_path}/default.nix" ]]; then
					echo "✗  Bad import (directory import missing default.nix): $dir/$import_path" >&2
					((error_count++))
				fi
				continue
			fi

			echo "✗  Bad import (no such file or directory): $dir/$import_path" >&2
			((error_count++))
		done
	done

	if ((error_count > 0)); then
		echo "➤ Found $error_count import error(s)." >&2
		return 1
	fi

	echo "➤ All imports OK!" >&2
	return 0
}

main "$@"
