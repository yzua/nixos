#!/usr/bin/env bash
# packages-check.sh - Check for duplicate packages across NixOS and Home Manager
#
# Detects:
# 1. Same package listed in multiple locations (home.packages, environment.systemPackages)
# 2. Package declared both via programs.<name> AND explicitly in package lists
# 3. Package declared both via services.<name> AND explicitly in package lists

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

# Temporary files
TMP_DIR=""
cleanup() { rm -rf "${TMP_DIR:-}"; }
trap cleanup EXIT

# Directories to scan
SCAN_DIRS=(
	"home-manager/packages"
	"home-manager/modules"
	"nixos/modules"
	"hosts"
)

# Non-package attributes (common pkgs.* that aren't packages)
SKIP_ATTRS="
lib stdenv stdenvNoCC mkShell mkDerivation fetchurl fetchgit fetchFromGitHub
fetchpatch fetchzip fetchTarball fetchsvn fetchcvs fetchhg fetchbower fetchnpm
fetchyarn writeShellScript writeShellScriptBin writeScript writeScriptBin writeText
writeTextFile runCommand runCommandLocal runCommandCC symlinkJoin buildEnv
makeWrapper wrapBinary override overrideAttrs overrideDerivation callPackage
callPackageWith newScope scope spliced targetPlatform hostPlatform buildPlatform
python3 python3Packages python310 python310Packages python311 python311Packages
python312 python312Packages rustPlatform rustc cargo go nodejs nodePackages
nodePackages_latest nodePackages_20 nodePackages_22 perlPackages rubyPackages
luaPackages lua5_1 lua5_3 lua5_4 luajit emacsPackages vimPlugins haskellPackages
ghc idrisPackages agdaPackages coqPackages lean lean4 ocamlPackages opam swift
swiftPackages dotnetCorePackages dotnetNetCorePackages jre jdk openjdk gradle
maven sbt scala kotlin rustup cargo-audit cargo-edit cargo-expand cargo-watch
bacon rust-analyzer unstable stable legacy_2311 latest appimageTools
makeDesktopItem copyDesktopItems wrapGAppsHook wrapQtAppsHook
gobject-introspection autoreconfHook pkg-config cmake meson ninja bison flex
qt6Packages writeShellApplication linuxPackages linuxPackages_latest
fetchFromGitea fetchFromSourcehut fetchFromGitLab fetchFromBitbucket
buildFHSEnv buildAppImage extractAppImage makeWrapperArgs
"

# Create skip pattern for grep
SKIP_PATTERN=$(echo "$SKIP_ATTRS" | tr ' ' '|' | tr '\n' ' ' | sed 's/  */|/g' | sed 's/^|*//;s/|*$//')

# Check if file should be skipped
should_skip() {
	local file="$1"
	local base
	base=$(basename "$file")
	[[ "$base" == _* ]] && return 0
	[[ "$file" == */custom/* ]] && return 0
	return 1
}

# Extract packages from a single file
extract_packages() {
	local file="$1"
	local relfile="${file#./}"

	# Pattern 1: pkgs.XXX and pkgsStable.XXX patterns
	# Skip common non-package attributes
	grep -oE '\b(pkgs|pkgsStable)\.[a-zA-Z][a-zA-Z0-9_-]*\b' "$file" 2>/dev/null |
		grep -vE '\b(pkgs|pkgsStable)\.('"$SKIP_PATTERN"')\b' |
		sed 's/^/PKG\t/' |
		sed "s/$/\t${relfile}/" \
			>>"${TMP_DIR}/packages.txt" 2>/dev/null || true

	# Pattern 2: with pkgs; [...] and with pkgsStable; [...] blocks
	# Use awk to parse these blocks
	awk -v relfile="$relfile" '
        BEGIN { scope=""; in_list=0; depth=0 }

        # Remove comments
        { gsub(/#.*/, "") }

        # Track scope from "with pkgs;" or "with pkgsStable;"
        /with[[:space:]]+pkgsStable[[:space:]]*;/ { scope="pkgsStable" }
        /with[[:space:]]+pkgs[[:space:]]*;/ && !/pkgsStable/ { scope="pkgs" }

        # Detect start of package list
        # Pattern: home.packages = ... [  or  environment.systemPackages = ... [
        /(home\.packages|environment\.systemPackages)[[:space:]]*=.*\[/ {
            in_list=1
            # Count brackets on this line
            depth += gsub(/\[/, "[") - gsub(/\]/, "]")
        }

        # Track brackets and extract packages
        in_list && scope != "" {
            # Extract words that look like package names
            for (i=1; i<=NF; i++) {
                word = $i
                # Clean punctuation
                gsub(/[\[\]\{\}\(\),;]/, "", word)
                # Skip empty, short, or keyword-like words
                if (length(word) < 2) continue
                if (word !~ /^[a-z][a-z0-9_-]*$/) continue
                # Skip common non-packages
                if (word == "enable" || word == "true" || word == "false") continue
                if (word == "package" || word == "packages" || word == "inherit") continue
                if (word == "home" || word == "environment" || word == "systemPackages") continue
                if (word == "with" || word == "pkgs" || word == "pkgsStable") continue
                print "PKG\t" word "\t" relfile
            }

            # Update depth (but not on first line where already counted)
            if (!/(home\.packages|environment\.systemPackages)/) {
                depth += gsub(/\[/, "[") - gsub(/\]/, "]")
            }

            if (depth <= 0) {
                in_list=0
                depth=0
            }
        }
    ' "$file" >>"${TMP_DIR}/packages.txt" 2>/dev/null || true
}

# Extract program modules
extract_programs() {
	local file="$1"
	local relfile="${file#./}"

	grep -oE 'programs\.[a-zA-Z0-9_-]+' "$file" 2>/dev/null |
		sed 's/programs\./PROG\t/' |
		awk -F'\t' '!seen[$0]++' |
		awk "{print \$0\"\t${relfile}\"}" \
			>>"${TMP_DIR}/programs.txt" 2>/dev/null || true
}

extract_services() {
	local file="$1"
	local relfile="${file#./}"

	grep -oE 'services\.[a-zA-Z0-9_-]+' "$file" 2>/dev/null |
		sed 's/services\./SVC\t/' |
		awk -F'\t' '!seen[$0]++' |
		awk "{print \$0\"\t${relfile}\"}" \
			>>"${TMP_DIR}/services.txt" 2>/dev/null || true
}

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

	# Build package -> files mapping using temp files to avoid subshell issues
	local PKG_MAP_FILE PROG_MAP_FILE SVC_MAP_FILE
	PKG_MAP_FILE=$(mktemp)
	PROG_MAP_FILE=$(mktemp)
	SVC_MAP_FILE=$(mktemp)

	# Process packages: create sorted list of pkg\tfile
	cut -f2,3 "${TMP_DIR}/packages.txt" 2>/dev/null | sort -u >"$PKG_MAP_FILE"

	# Process programs
	cut -f2,3 "${TMP_DIR}/programs.txt" 2>/dev/null | sort -u >"$PROG_MAP_FILE"

	# Process services
	cut -f2,3 "${TMP_DIR}/services.txt" 2>/dev/null | sort -u >"$SVC_MAP_FILE"

	echo "➤ Checking for duplicate packages…" >&2

	# Find packages in multiple files
	# Get packages that appear more than once with different files
	awk -F$'\t' '{print $1}' "$PKG_MAP_FILE" 2>/dev/null | sort | uniq -c | while read -r count pkg; do
		[[ $count -gt 1 ]] || continue
		print_error "Package '$pkg' declared in multiple files:"
		grep "^${pkg}"$'\t' "$PKG_MAP_FILE" | cut -f2 | while read -r f; do
			echo "    • $f"
		done
		# Can't increment errors here due to subshell
	done

	# Count actual errors for return code
	local dup_count
	dup_count=$(awk -F$'\t' '{print $1}' "$PKG_MAP_FILE" 2>/dev/null | sort | uniq -d | wc -l)
	errors=$dup_count

	echo -e "\n➤ Checking for program/module conflicts…" >&2

	# Check program modules vs explicit packages
	report_conflicts "programs" "$PROG_MAP_FILE" "$PKG_MAP_FILE"

	# Count conflicts
	local conflict_count
	conflict_count=$(count_conflicts "$PROG_MAP_FILE" "$PKG_MAP_FILE")
	errors=$((errors + conflict_count))

	# Check service modules vs explicit packages
	report_conflicts "services" "$SVC_MAP_FILE" "$PKG_MAP_FILE"

	local svc_conflict_count
	svc_conflict_count=$(count_conflicts "$SVC_MAP_FILE" "$PKG_MAP_FILE")
	errors=$((errors + svc_conflict_count))

	# Summary
	echo "" >&2
	if [[ $errors -gt 0 ]]; then
		print_error "Found $errors duplicate/conflict error(s)"
		rm -f "$PKG_MAP_FILE" "$PROG_MAP_FILE" "$SVC_MAP_FILE"
		return 1
	fi

	# Count before cleanup
	local pkg_count prog_count svc_count
	pkg_count=$(count_unique_keys "$PKG_MAP_FILE")
	prog_count=$(count_unique_keys "$PROG_MAP_FILE")
	svc_count=$(count_unique_keys "$SVC_MAP_FILE")

	# Cleanup temp files
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
	touch "${TMP_DIR}/packages.txt" "${TMP_DIR}/programs.txt" "${TMP_DIR}/services.txt"

	local file_count=0

	for dir in "${SCAN_DIRS[@]}"; do
		[[ -d "$dir" ]] || continue
		while IFS= read -r -d '' file; do
			should_skip "$file" && continue
			((file_count++)) || true
			extract_packages "$file"
			extract_programs "$file"
			extract_services "$file"
		done < <(find "$dir" -type f -name "*.nix" -print0 2>/dev/null)
	done

	echo "   Scanned $file_count files" >&2
	analyze
}

main "$@"
