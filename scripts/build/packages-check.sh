#!/usr/bin/env bash
# packages-check.sh - Check for duplicate packages across NixOS and Home Manager
#
# Detects:
# 1. Same package listed in multiple locations (home.packages, environment.systemPackages)
# 2. Package declared both via programs.<name> AND explicitly in package lists
# 3. Package declared both via services.<name> AND explicitly in package lists

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
AWK_EXTRACT="${SCRIPT_DIR}/../lib/extract-nix-packages.awk"

# Temporary files
TMP_DIR=""
cleanup() { rm -rf "${TMP_DIR:-}"; }
trap cleanup EXIT

# Directories to scan
SCAN_DIRS=(
	"home-manager/packages"
	"home-manager/modules"
	"nixos-modules"
	"hosts"
)

count_unique_keys() {
	local map_file="$1"
	cut -f1 "$map_file" 2>/dev/null | sort -u | wc -l || echo 0
}

overlap_keys() {
	local left_map_file="$1"
	local right_map_file="$2"

	join -t $'\t' -1 1 -2 1 \
		<(cut -f1 "$left_map_file" | sort -u) \
		<(cut -f1 "$right_map_file" | sort -u) 2>/dev/null
}

first_mapped_file() {
	local key="$1"
	local map_file="$2"

	grep "^${key}"$'\t' "$map_file" | head -1 | cut -f2
}

report_conflicts() {
	local owner_label="$1"
	local owner_map_file="$2"
	local package_map_file="$3"

	overlap_keys "$owner_map_file" "$package_map_file" | while read -r pkg; do
		[[ -n "$pkg" ]] || continue
		local owner_file pkg_file
		owner_file=$(first_mapped_file "$pkg" "$owner_map_file")
		pkg_file=$(first_mapped_file "$pkg" "$package_map_file")
		print_error "Package '$pkg' is both:"
		echo "    • Enabled via ${owner_label}.${pkg} in $owner_file"
		echo "    • Explicitly installed in: $pkg_file"
	done
}

count_conflicts() {
	local owner_map_file="$1"
	local package_map_file="$2"

	overlap_keys "$owner_map_file" "$package_map_file" | wc -l
}

# Analyze and find duplicates
analyze() {
	local errors=0

	local PKG_MAP_FILE PROG_MAP_FILE SVC_MAP_FILE
	PKG_MAP_FILE=$(mktemp)
	PROG_MAP_FILE=$(mktemp)
	SVC_MAP_FILE=$(mktemp)

	cut -f2,3 "${TMP_DIR}/packages.txt" 2>/dev/null | sort -u >"$PKG_MAP_FILE"
	cut -f2,3 "${TMP_DIR}/programs.txt" 2>/dev/null | sort -u >"$PROG_MAP_FILE"
	cut -f2,3 "${TMP_DIR}/services.txt" 2>/dev/null | sort -u >"$SVC_MAP_FILE"

	log_info "Checking for duplicate packages…"

	local dup_count
	dup_count=$(awk -F$'\t' '{print $1}' "$PKG_MAP_FILE" 2>/dev/null | sort | uniq -d | wc -l)
	errors=$dup_count

	log_info "Checking for program/module conflicts…"

	report_conflicts "programs" "$PROG_MAP_FILE" "$PKG_MAP_FILE"

	local conflict_count
	conflict_count=$(count_conflicts "$PROG_MAP_FILE" "$PKG_MAP_FILE")
	errors=$((errors + conflict_count))

	report_conflicts "services" "$SVC_MAP_FILE" "$PKG_MAP_FILE"

	local svc_conflict_count
	svc_conflict_count=$(count_conflicts "$SVC_MAP_FILE" "$PKG_MAP_FILE")
	errors=$((errors + svc_conflict_count))

	echo "" >&2
	if [[ $errors -gt 0 ]]; then
		print_error "Found $errors duplicate/conflict error(s)"
		rm -f "$PKG_MAP_FILE" "$PROG_MAP_FILE" "$SVC_MAP_FILE"
		return 1
	fi

	local pkg_count prog_count svc_count
	pkg_count=$(count_unique_keys "$PKG_MAP_FILE")
	prog_count=$(count_unique_keys "$PROG_MAP_FILE")
	svc_count=$(count_unique_keys "$SVC_MAP_FILE")

	rm -f "$PKG_MAP_FILE" "$PROG_MAP_FILE" "$SVC_MAP_FILE"

	print_success "No duplicates found!"
	echo "    • $pkg_count packages"
	echo "    • $prog_count program modules"
	echo "    • $svc_count service modules"
	return 0
}

main() {
	echo -e "\n➤ Scanning for packages…" >&2

	TMP_DIR=$(mktemp -d)

	# Single-pass extraction: one find + one AWK process for all files
	local file_count
	file_count=$(find "${SCAN_DIRS[@]}" \
		-type f -name "*.nix" \
		! -name "_*.nix" \
		! -path "*/custom/*" \
		-print 2>/dev/null | wc -l)
	echo "   Scanned $file_count files" >&2

	find "${SCAN_DIRS[@]}" \
		-type f -name "*.nix" \
		! -name "_*.nix" \
		! -path "*/custom/*" \
		-print0 2>/dev/null \
		| xargs -0 awk -f "${AWK_EXTRACT}" \
		| sort -u >"${TMP_DIR}/all.txt"

	grep "^PKG" "${TMP_DIR}/all.txt" >"${TMP_DIR}/packages.txt" || true
	grep "^PROG" "${TMP_DIR}/all.txt" >"${TMP_DIR}/programs.txt" || true
	grep "^SVC" "${TMP_DIR}/all.txt" >"${TMP_DIR}/services.txt" || true

	analyze
}

main "$@"
