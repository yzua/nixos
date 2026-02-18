#!/usr/bin/env bash
# Focused tests for modules-check.sh import validation behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_SCRIPT="${SCRIPT_DIR}/modules-check.sh"

setup_valid_imports() {
	mkdir -p modules/security
	cat >modules/default.nix <<'EOF'
{ ... }:
{
  imports = [
    ./audio.nix # Local module
    ./security  # Directory module
  ];
}
EOF
	cat >modules/audio.nix <<'EOF'
{ ... }: { }
EOF
	cat >modules/security/default.nix <<'EOF'
{ ... }:
{
  imports = [ ];
}
EOF
	cat >modules/_helpers.nix <<'EOF'
{ ... }: { }
EOF
}

setup_missing_file_import() {
	mkdir -p modules
	cat >modules/default.nix <<'EOF'
{ ... }:
{
  imports = [
    ./missing.nix
  ];
}
EOF
}

setup_missing_directory_default() {
	mkdir -p modules/security
	cat >modules/default.nix <<'EOF'
{ ... }:
{
  imports = [
    ./security
  ];
}
EOF
}

setup_unimported_local_module() {
	mkdir -p modules
	cat >modules/default.nix <<'EOF'
{ ... }:
{
  imports = [
    ./audio.nix
  ];
}
EOF
	cat >modules/audio.nix <<'EOF'
{ ... }: { }
EOF
	cat >modules/network.nix <<'EOF'
{ ... }: { }
EOF
}

setup_manual_helper_comment() {
	mkdir -p modules
	cat >modules/default.nix <<'EOF'
{ ... }:
{
  imports = [
    ./audio.nix
    # ./lib.nix (imported manually by submodules)
  ];
}
EOF
	cat >modules/audio.nix <<'EOF'
{ ... }: { }
EOF
	cat >modules/lib.nix <<'EOF'
{ ... }: { }
EOF
}

run_case() {
	local name="$1"
	local expected_exit="$2"
	local expected_pattern="$3"
	local setup_fn="$4"

	local tmp_dir
	tmp_dir="$(mktemp -d)"
	local output_file="${tmp_dir}/output.log"

	(
		cd "$tmp_dir"
		"$setup_fn"

		local status
		set +e
		bash "$CHECK_SCRIPT" >"$output_file" 2>&1
		status=$?
		set -e

		if [[ "$status" -ne "$expected_exit" ]]; then
			echo "FAIL: ${name} (expected exit ${expected_exit}, got ${status})"
			cat "$output_file"
			exit 1
		fi

		if [[ -n "$expected_pattern" ]] && ! grep -Eq "$expected_pattern" "$output_file"; then
			echo "FAIL: ${name} (missing expected output: ${expected_pattern})"
			cat "$output_file"
			exit 1
		fi
	)

	rm -rf "$tmp_dir"
	echo "PASS: ${name}"
}

failed=0

run_case "valid file + directory imports" 0 "All imports OK" setup_valid_imports || ((failed++))
run_case "missing file import fails" 1 "Bad import \\(no such file or directory\\)" setup_missing_file_import || ((failed++))
run_case "missing directory default fails" 1 "directory import missing default.nix" setup_missing_directory_default || ((failed++))
run_case "unimported local module fails" 1 "Missing import: ./modules/network.nix" setup_unimported_local_module || ((failed++))
run_case "manual helper comment is skipped" 0 "All imports OK" setup_manual_helper_comment || ((failed++))

if ((failed > 0)); then
	echo "${failed} case(s) failed."
	exit 1
fi

echo "All modules-check tests passed."
