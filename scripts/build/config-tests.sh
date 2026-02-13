#!/usr/bin/env bash
# config-tests.sh - Configuration validation tests for NixOS setup
# Provides basic testing infrastructure for system configuration validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
TEST_RESULTS="${TMPDIR:-/tmp}/nixos-config-tests-$$.log"
FAILED_TESTS=0
PASSED_TESTS=0

# Logging functions (missing from original implementation)
log_info() {
	echo "[INFO] $*" | tee -a "$TEST_RESULTS"
}

log_error() {
	echo "[ERROR] $*" | tee -a "$TEST_RESULTS"
}

log_success() {
	echo "[SUCCESS] $*" | tee -a "$TEST_RESULTS"
}

log_warning() {
	echo "[WARNING] $*" | tee -a "$TEST_RESULTS"
}

# Test result functions
test_pass() {
	local test_name="$1"
	echo "✓ PASS: $test_name" | tee -a "$TEST_RESULTS"
	((PASSED_TESTS++))
}

test_fail() {
	local test_name="$1"
	local reason="$2"
	echo "✗ FAIL: $test_name - $reason" | tee -a "$TEST_RESULTS"
	((FAILED_TESTS++))
}

test_skip() {
	local test_name="$1"
	local reason="$2"
	echo "⚠ SKIP: $test_name - $reason" | tee -a "$TEST_RESULTS"
}

# Initialize test results
init_tests() {
	echo "=== NixOS Configuration Tests $(date) ===" >"$TEST_RESULTS"
	log_info "Starting configuration validation tests"
}

# Test flake evaluation
test_flake_evaluation() {
	local test_name="Flake Evaluation"
	echo "Testing flake evaluation..."

	if nix flake metadata . >/dev/null 2>&1; then
		test_pass "$test_name"
	else
		test_fail "$test_name" "Flake metadata evaluation failed"
	fi
}

# Test flake check (basic)
test_flake_check() {
	local test_name="Flake Check"
	log_info "Testing flake check..."

	if nix flake check --no-build . >/dev/null 2>&1; then
		test_pass "$test_name"
	else
		test_fail "$test_name" "Flake check failed"
	fi
}

# Test module imports
test_module_imports() {
	local test_name="Module Imports"
	log_info "Testing module imports..."

	if bash "$SCRIPT_DIR/modules-check.sh" >/dev/null 2>&1; then
		test_pass "$test_name"
	else
		test_fail "$test_name" "Module import validation failed"
	fi
}

# Test syntax validation
test_nix_syntax() {
	local test_name="Nix Syntax"
	log_info "Testing Nix syntax..."

	local syntax_errors=0
	# Find all .nix files and check syntax
	while IFS= read -r -d '' file; do
		if ! nix-instantiate --parse "$file" >/dev/null 2>&1; then
			log_error "Syntax error in $file"
			((syntax_errors++))
		fi
	done < <(find . -name "*.nix" -type f -print0)

	if [[ $syntax_errors -eq 0 ]]; then
		test_pass "$test_name"
	else
		test_fail "$test_name" "$syntax_errors files have syntax errors"
	fi
}

# Test shell script syntax
test_shell_syntax() {
	local test_name="Shell Script Syntax"
	log_info "Testing shell script syntax..."

	if command -v shellcheck >/dev/null 2>&1; then
		if find . -name "*.sh" -type f -exec nix run nixpkgs#shellcheck -- {} + >/dev/null 2>&1; then
			test_pass "$test_name"
		else
			test_fail "$test_name" "Shell script linting failed"
		fi
	else
		test_skip "$test_name" "shellcheck not available"
	fi
}

# Test that critical services are configured
test_critical_services() {
	local test_name="Critical Services"
	log_info "Testing critical service configuration..."

	# This is a basic test - in a real scenario we'd parse the Nix config
	# For now, just check that key modules exist
	local critical_modules=("security.nix" "networking.nix" "validation.nix")

	local missing_modules=0
	for module in "${critical_modules[@]}"; do
		if [[ ! -f "nixos/modules/$module" ]]; then
			log_error "Critical module missing: $module"
			((missing_modules++))
		fi
	done

	if [[ $missing_modules -eq 0 ]]; then
		test_pass "$test_name"
	else
		test_fail "$test_name" "$missing_modules critical modules missing"
	fi
}

# Test that hosts are properly configured
test_host_configurations() {
	local test_name="Host Configurations"
	log_info "Testing host configurations..."

	local host_count=0
	local valid_hosts=0

	for host_dir in hosts/*/; do
		if [[ -d "$host_dir" ]]; then
			((host_count++))
			local host_name
			host_name=$(basename "$host_dir")

			# Check for required files
			if [[ -f "${host_dir}configuration.nix" ]] && [[ -f "${host_dir}hardware-configuration.nix" ]]; then
				((valid_hosts++))
			else
				log_warning "Host $host_name missing required configuration files"
			fi
		fi
	done

	if [[ $host_count -gt 0 ]] && [[ $valid_hosts -eq $host_count ]]; then
		test_pass "$test_name"
	else
		test_fail "$test_name" "Only $valid_hosts/$host_count hosts properly configured"
	fi
}

# Test that secrets are properly configured (without revealing them)
test_secrets_setup() {
	local test_name="Secrets Configuration"
	log_info "Testing secrets configuration..."

	if [[ -f "secrets/secrets.yaml" ]] && [[ -f "secrets/.sops.yaml" ]]; then
		# Basic check - files exist, but don't try to decrypt
		test_pass "$test_name"
	else
		test_skip "$test_name" "Secrets not configured or not present"
	fi
}

# Run all tests
run_all_tests() {
	init_tests

	echo "Running NixOS Configuration Tests..."
	echo

	echo "Running test_flake_evaluation..."
	test_flake_evaluation
	echo "Running test_flake_check..."
	test_flake_check
	echo "Running test_module_imports..."
	test_module_imports
	echo "Running test_nix_syntax..."
	test_nix_syntax
	echo "Running test_shell_syntax..."
	test_shell_syntax
	echo "Running test_critical_services..."
	test_critical_services
	echo "Running test_host_configurations..."
	test_host_configurations
	echo "Running test_secrets_setup..."
	test_secrets_setup

	echo
	echo "=== Test Results ==="
	echo "Passed: $PASSED_TESTS"
	echo "Failed: $FAILED_TESTS"
	echo "Total: $((PASSED_TESTS + FAILED_TESTS))"
	echo
	echo "Detailed results saved to: $TEST_RESULTS"

	if [[ $FAILED_TESTS -gt 0 ]]; then
		log_error "Some tests failed. Check $TEST_RESULTS for details."
		return 1
	else
		log_success "All configuration tests passed!"
		return 0
	fi
}

# Always run tests when script is executed
run_all_tests
