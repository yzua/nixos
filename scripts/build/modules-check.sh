#!/usr/bin/env bash
# modules-check.sh - Check for missing module imports in Nix configurations
# This script validates that all .nix files in directories with default.nix are properly imported

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck source=scripts/lib/require.sh
source "${SCRIPT_DIR}/../lib/require.sh"
SHARED_AWK="${SCRIPT_DIR}/../lib/awk-utils.awk"

validate_import_path() {
	local dir="$1"
	local import_path="$2"
	local target
	target="$(cd "$dir" && realpath -m "$import_path" 2>/dev/null)" || true

	if [[ -z "$target" ]]; then
		print_error "Bad import (cannot resolve path): $dir/$import_path"
		return 1
	fi

	if [[ -f "$target" ]]; then
		return 0
	fi

	if [[ -d "$target" ]]; then
		if [[ ! -f "${target}/default.nix" ]]; then
			print_error "Bad import (directory import missing default.nix): $dir/$import_path"
			return 1
		fi
		return 0
	fi

	print_error "Bad import (no such file or directory): $dir/$import_path"
	return 1
}

# Build the batch AWK script that processes all default.nix files at once
write_batch_awk() {
	{
		cat "$SHARED_AWK"
		cat <<'AWK'
function extract_nix_paths(line,    remaining, path, start) {
	remaining = line
	while (match(remaining, /\.\.\/[[:alnum:]_./-]+\.nix|\.\/[[:alnum:]_./-]+\.nix/)) {
		start = RSTART
		path = substr(remaining, start, RLENGTH)
		print norm_file "\tnix\t" path
		remaining = substr(remaining, start + RLENGTH)
	}
}

function extract_directory_imports(line,    remaining, path, start) {
	remaining = line
	while (match(remaining, /\.\.\/[[:alnum:]_./-]+|\.\/[[:alnum:]_./-]+/)) {
		start = RSTART
		path = substr(remaining, start, RLENGTH)
		if (path !~ /\.nix$/) {
			print norm_file "\tdir\t" path
		}
		remaining = substr(remaining, start + RLENGTH)
	}
}

FNR == 1 {
	in_imports = 0
	bracket_depth = 0
	waiting_for_open_bracket = 0
	norm_file = FILENAME
	sub(/^\.\//, "", norm_file)
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
				if (bracket_depth <= 0) { in_imports = 0; bracket_depth = 0 }
			} else {
				waiting_for_open_bracket = 1
			}
		} else if (waiting_for_open_bracket && index(line, "[") > 0) {
			in_imports = 1
			waiting_for_open_bracket = 0
			bracket_depth = count_char(line, "[") - count_char(line, "]")
			extract_directory_imports(line)
			if (bracket_depth <= 0) { in_imports = 0; bracket_depth = 0 }
		}
		next
	}
	extract_directory_imports(line)
	bracket_depth += count_char(line, "[") - count_char(line, "]")
	if (bracket_depth <= 0) { in_imports = 0; bracket_depth = 0 }
}
AWK
	} >"${TMP_DIR}/batch-awk"
}

write_manual_awk() {
	cat >"${TMP_DIR}/manual-awk.awk" <<'AWK'
{
	line = $0; lower_line = tolower(line)
	is_manual = (line ~ /#/ && (lower_line ~ /modules-check:[[:space:]]*manual-helper/ || lower_line ~ /imported manually/))
	if (is_manual) {
		norm_file = FILENAME; sub(/^\.\//, "", norm_file)
		while (match(line, /\.\/[[:alnum:]_./-]+\.nix/)) {
			path = substr(line, RSTART + 2, RLENGTH - 2)
			sub(/^.*\//, "", path)
			print norm_file "\tmanual\t" path
			line = substr(line, RSTART + RLENGTH)
		}
	}
}
AWK
}

main() {
	local error_count=0
	need_cmd awk
	need_cmd find
	need_cmd sort

	TMP_DIR=$(mktemp -d)
	trap 'rm -f "${TMP_DIR}/batch-awk" "${TMP_DIR}/manual-awk.awk"; rm -rf "${TMP_DIR:-}"' EXIT

	write_batch_awk
	write_manual_awk

	local -a defaults=()
	mapfile -t defaults < <(find . -type f -name default.nix | sort)

	if ((${#defaults[@]} == 0)); then
		print_warning "No default.nix files found." >&2
		return 0
	fi

	# Batch extraction: one AWK for imports + one xargs awk for manual helpers
	{
		awk -f "${TMP_DIR}/batch-awk" "${defaults[@]}" 2>/dev/null || true

		printf '%s\0' "${defaults[@]}" \
			| xargs -0 awk -f "${TMP_DIR}/manual-awk.awk" 2>/dev/null || true
	} | sort -u >"${TMP_DIR}/all-extracts.txt"

	# Single-pass AWK split: map each extract line to its default.nix index
	awk -F'\t' '
	NR == FNR { sub(/^\.\//, ""); map[$0] = FNR - 1; next }
	{ p = $1; if (p in map) print > "'"${TMP_DIR}"'/extracts-" map[p] ".txt" }
	' <(printf '%s\n' "${defaults[@]}") "${TMP_DIR}/all-extracts.txt" 2>/dev/null || true

	# Batch find all local modules across all directories at once
	local -a all_local_modules=()
	local -a all_dirs=()
	mapfile -t all_dirs < <(printf '%s\n' "${defaults[@]}" | xargs dirname | sort -u)
	mapfile -t all_local_modules < <(
		find "${all_dirs[@]}" -maxdepth 1 -type f -name '*.nix' \
			! -name default.nix ! -name '_*.nix' -printf '%h\t%f\n' 2>/dev/null
	)

	# Process results grouped by default.nix
	local proc_idx=0
	for default in "${defaults[@]}"; do
		local dir
		dir=$(dirname "$default")
		print_info "Checking $default"

		local -a imported=()
		local -a manual_helpers=()
		local -a unique_imports=()

		local extract_file="${TMP_DIR}/extracts-${proc_idx}"
		[[ -f "$extract_file" ]] || { ((proc_idx++)) || true; continue; }
		while IFS=$'\t' read -r _ type path; do
			if [[ "$type" == "manual" ]]; then
				manual_helpers+=("$path")
			else
				imported+=("$path")
			fi
		done <"$extract_file"

		# Build imported set (including basenames for directory imports)
		declare -A imported_set=()
		mapfile -t unique_imports < <(printf '%s\n' "${imported[@]}" | awk 'NF && !seen[$0]++')
		local import_path
		for import_path in "${unique_imports[@]}"; do
			imported_set["$import_path"]=1
			local basename="${import_path##*/}"
			imported_set["$basename"]=1
		done

		# Build manual helper set
		declare -A manual_helper_set=()
		local helper_name
		for helper_name in "${manual_helpers[@]}"; do
			manual_helper_set["$helper_name"]=1
		done

		# Get local modules from pre-built map
		local -a local_modules=()
		while IFS=$'\t' read -r ldir lfile; do
			if [[ "$ldir" == "$dir" ]]; then
				local_modules+=("$lfile")
			fi
		done <<< "$(printf '%s\n' "${all_local_modules[@]}")"

		# Check for missing imports
		local module_file
		for module_file in "${local_modules[@]}"; do
			if [[ -n "${manual_helper_set[$module_file]:-}" ]]; then
				continue
			fi
			if [[ -z "${imported_set[$module_file]:-}" ]]; then
				print_error "Missing import: $dir/$module_file"
				((error_count++))
			fi
		done

		# Validate import paths
		for import_path in "${unique_imports[@]}"; do
			if ! validate_import_path "$dir" "$import_path"; then
				((error_count++))
			fi
		done

		unset imported_set manual_helper_set
		((proc_idx++)) || true
	done

	if ((error_count > 0)); then
		print_error "Found $error_count import error(s)."
		return 1
	fi

	print_success "All imports OK!"
	return 0
}

main "$@"
