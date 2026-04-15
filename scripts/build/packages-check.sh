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

# Write the single-pass extraction AWK to a temp file
write_extract_awk() {
	cat >"${TMP_DIR}/extract.awk" <<'AWK'
BEGIN {
	OFS = "\t"
	# Non-package pkgs.* attributes to skip
	skip["lib"]=1; skip["stdenv"]=1; skip["stdenvNoCC"]=1; skip["mkShell"]=1
	skip["mkDerivation"]=1; skip["fetchurl"]=1; skip["fetchgit"]=1
	skip["fetchFromGitHub"]=1; skip["fetchpatch"]=1; skip["fetchzip"]=1
	skip["fetchTarball"]=1; skip["fetchsvn"]=1; skip["fetchcvs"]=1
	skip["fetchhg"]=1; skip["fetchbower"]=1; skip["fetchnpm"]=1
	skip["fetchyarn"]=1; skip["writeShellScript"]=1; skip["writeShellScriptBin"]=1
	skip["writeScript"]=1; skip["writeScriptBin"]=1; skip["writeText"]=1
	skip["writeTextFile"]=1; skip["runCommand"]=1; skip["runCommandLocal"]=1
	skip["runCommandCC"]=1; skip["symlinkJoin"]=1; skip["buildEnv"]=1
	skip["makeWrapper"]=1; skip["wrapBinary"]=1; skip["override"]=1
	skip["overrideAttrs"]=1; skip["overrideDerivation"]=1; skip["callPackage"]=1
	skip["callPackageWith"]=1; skip["newScope"]=1; skip["scope"]=1
	skip["spliced"]=1; skip["targetPlatform"]=1; skip["hostPlatform"]=1
	skip["buildPlatform"]=1; skip["python3"]=1; skip["python3Packages"]=1
	skip["python310"]=1; skip["python310Packages"]=1; skip["python311"]=1
	skip["python311Packages"]=1; skip["python312"]=1; skip["python312Packages"]=1
	skip["rustPlatform"]=1; skip["rustc"]=1; skip["cargo"]=1; skip["go"]=1
	skip["nodejs"]=1; skip["nodePackages"]=1; skip["nodePackages_latest"]=1
	skip["nodePackages_20"]=1; skip["nodePackages_22"]=1; skip["perlPackages"]=1
	skip["rubyPackages"]=1; skip["luaPackages"]=1; skip["lua5_1"]=1
	skip["lua5_3"]=1; skip["lua5_4"]=1; skip["luajit"]=1
	skip["emacsPackages"]=1; skip["vimPlugins"]=1; skip["haskellPackages"]=1
	skip["ghc"]=1; skip["idrisPackages"]=1; skip["agdaPackages"]=1
	skip["coqPackages"]=1; skip["lean"]=1; skip["lean4"]=1
	skip["ocamlPackages"]=1; skip["opam"]=1; skip["swift"]=1
	skip["swiftPackages"]=1; skip["dotnetCorePackages"]=1; skip["dotnetNetCorePackages"]=1
	skip["jre"]=1; skip["jdk"]=1; skip["openjdk"]=1; skip["gradle"]=1
	skip["maven"]=1; skip["sbt"]=1; skip["scala"]=1; skip["kotlin"]=1
	skip["rustup"]=1; skip["cargo-audit"]=1; skip["cargo-edit"]=1
	skip["cargo-expand"]=1; skip["cargo-watch"]=1; skip["bacon"]=1
	skip["rust-analyzer"]=1; skip["unstable"]=1; skip["stable"]=1
	skip["legacy_2311"]=1; skip["latest"]=1; skip["appimageTools"]=1
	skip["makeDesktopItem"]=1; skip["copyDesktopItems"]=1
	skip["wrapGAppsHook"]=1; skip["wrapQtAppsHook"]=1
	skip["gobject-introspection"]=1; skip["autoreconfHook"]=1; skip["pkg-config"]=1
	skip["cmake"]=1; skip["meson"]=1; skip["ninja"]=1; skip["bison"]=1; skip["flex"]=1
	skip["qt6Packages"]=1; skip["writeShellApplication"]=1
	skip["linuxPackages"]=1; skip["linuxPackages_latest"]=1
	skip["fetchFromGitea"]=1; skip["fetchFromSourcehut"]=1
	skip["fetchFromGitLab"]=1; skip["fetchFromBitbucket"]=1
	skip["buildFHSEnv"]=1; skip["buildAppImage"]=1; skip["extractAppImage"]=1
	skip["makeWrapperArgs"]=1
	# Non-package words to skip in with-pkgs blocks
	wskip["enable"]=1; wskip["true"]=1; wskip["false"]=1
	wskip["package"]=1; wskip["packages"]=1; wskip["inherit"]=1
	wskip["home"]=1; wskip["environment"]=1; wskip["systemPackages"]=1
	wskip["with"]=1; wskip["pkgs"]=1; wskip["pkgsStable"]=1
	in_list = 0; depth = 0; scope = ""; waiting_bracket = 0
}
FNR == 1 { in_list = 0; depth = 0; scope = ""; waiting_bracket = 0 }
{
	gsub(/#.*/, "")
	# Track with-pkgs scope
	if (match($0, /with[[:space:]]+pkgsStable[[:space:]]*;/)) scope = "pkgsStable"
	else if (match($0, /with[[:space:]]+pkgs[[:space:]]*;/) && !match($0, /pkgsStable/)) scope = "pkgs"
	# Detect package list start
	if (!in_list && !waiting_bracket) {
		if (match($0, /(home\.packages|environment\.systemPackages)[[:space:]]*=.*\[/)) {
			in_list = 1; depth += gsub(/\[/, "[", $0) - gsub(/\]/, "]", $0)
		} else if (match($0, /(home\.packages|environment\.systemPackages)[[:space:]]*=/)) {
			waiting_bracket = 1
		}
	} else if (waiting_bracket && match($0, /\[/)) {
		in_list = 1; waiting_bracket = 0; depth += gsub(/\[/, "[", $0) - gsub(/\]/, "]", $0)
	}
	# Extract words from with-pkgs block
	if (in_list && scope != "") {
		for (i = 1; i <= NF; i++) {
			word = $i; gsub(/[\[\]\{\}\(\),;]/, "", word)
			if (length(word) < 2) continue
			if (word !~ /^[a-z][a-z0-9_-]*$/) continue
			if (word in wskip) continue
			if (!(word in skip)) print "PKG", word, FILENAME
		}
		if (!match($0, /(home\.packages|environment\.systemPackages)/)) {
			depth += gsub(/\[/, "[", $0) - gsub(/\]/, "]", $0)
		}
		if (depth <= 0) { in_list = 0; depth = 0 }
	}
	# Extract programs.XXX (unique per file)
	remaining = $0
	while (match(remaining, /programs\.[a-zA-Z0-9_-]+/)) {
		name = substr(remaining, RSTART + 9, RLENGTH - 9)
		key = name SUBSEP FILENAME
		if (!(key in seen_prog)) { seen_prog[key] = 1; print "PROG", name, FILENAME }
		remaining = substr(remaining, RSTART + RLENGTH)
	}
	# Extract services.XXX (unique per file)
	remaining = $0
	while (match(remaining, /services\.[a-zA-Z0-9_-]+/)) {
		name = substr(remaining, RSTART + 9, RLENGTH - 9)
		key = name SUBSEP FILENAME
		if (!(key in seen_svc)) { seen_svc[key] = 1; print "SVC", name, FILENAME }
		remaining = substr(remaining, RSTART + RLENGTH)
	}
}
AWK
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

	local PKG_MAP_FILE PROG_MAP_FILE SVC_MAP_FILE
	PKG_MAP_FILE=$(mktemp)
	PROG_MAP_FILE=$(mktemp)
	SVC_MAP_FILE=$(mktemp)

	cut -f2,3 "${TMP_DIR}/packages.txt" 2>/dev/null | sort -u >"$PKG_MAP_FILE"
	cut -f2,3 "${TMP_DIR}/programs.txt" 2>/dev/null | sort -u >"$PROG_MAP_FILE"
	cut -f2,3 "${TMP_DIR}/services.txt" 2>/dev/null | sort -u >"$SVC_MAP_FILE"

	echo "➤ Checking for duplicate packages…" >&2

	local dup_count
	dup_count=$(awk -F$'\t' '{print $1}' "$PKG_MAP_FILE" 2>/dev/null | sort | uniq -d | wc -l)
	errors=$dup_count

	echo -e "\n➤ Checking for program/module conflicts…" >&2

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
	write_extract_awk

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
		| xargs -0 awk -f "${TMP_DIR}/extract.awk" \
		| sort -u >"${TMP_DIR}/all.txt"

	grep "^PKG" "${TMP_DIR}/all.txt" >"${TMP_DIR}/packages.txt" || true
	grep "^PROG" "${TMP_DIR}/all.txt" >"${TMP_DIR}/programs.txt" || true
	grep "^SVC" "${TMP_DIR}/all.txt" >"${TMP_DIR}/services.txt" || true

	analyze
}

main "$@"
