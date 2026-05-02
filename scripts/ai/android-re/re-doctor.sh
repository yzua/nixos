#!/usr/bin/env bash
set -euo pipefail
# Comprehensive tool audit for Android RE agent.
# Checks all tools referenced in android-re/prompts/TOOLS.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/logging.sh"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/require.sh"

trap 'log_error "command failed at line ${LINENO}: ${BASH_COMMAND}"' ERR

PRESENT=0
MISSING=0
TOTAL=0

check_and_count() {
    local tool="$1"
    TOTAL=$((TOTAL + 1))
    if command -v "${tool}" >/dev/null 2>&1; then
        log_success "tool present: ${tool} -> $(command -v "${tool}")"
        PRESENT=$((PRESENT + 1))
    else
        log_warning "tool missing: ${tool}"
        MISSING=$((MISSING + 1))
    fi
}

check_python_module() {
    local module="$1"
    TOTAL=$((TOTAL + 1))
    if python3 -c "import ${module}" >/dev/null 2>&1; then
        log_success "python module present: ${module}"
        PRESENT=$((PRESENT + 1))
    else
        log_warning "python module missing: ${module}"
        MISSING=$((MISSING + 1))
    fi
}

doctor() {
    echo ""
    log_info "=== Android RE Doctor ==="
    echo ""

    log_info "--- Emulator/Device ---"
    for tool in adb emulator avdmanager sdkmanager scrcpy; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Dynamic Analysis ---"
    for tool in frida frida-ps objection; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Proxy/Network ---"
    for tool in mitmproxy mitmdump tshark httpx katana amass nmap masscan; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Static Analysis ---"
    for tool in jadx apktool radare2 cutter ghidra binwalk semgrep codeql afl-fuzz yara; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Web Testing ---"
    for tool in ffuf dalfox arjun zap nuclei subfinder whatweb interactsh testssl gobuster feroxbuster commix rustscan; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Binary Analysis ---"
    for tool in checksec objdump readelf nm; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Supply Chain ---"
    check_and_count trivy

    echo ""
    log_info "--- Android Build ---"
    for tool in aapt2 apksigner zipalign; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Coverage ---"
    check_and_count gcovr

    echo ""
    log_info "--- Core Utils ---"
    for tool in curl jq sqlite3 unzip xz git; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Python Modules ---"
    for module in androguard waybackpy z3; do
        check_python_module "${module}"
    done

    echo ""
    log_info "=== Summary: ${PRESENT}/${TOTAL} tools present, ${MISSING} missing ==="
}

usage() {
    cat <<'EOF'
Usage: re-doctor.sh

Comprehensive tool audit for Android RE agent. Checks all tools
referenced in android-re/prompts/TOOLS.md grouped by category.

Commands:
  (default)    Run full tool audit
  help         Show this usage message
EOF
}

main() {
    local cmd="${1:-}"
    case "${cmd}" in
    -h|--help|help)
        usage
        ;;
    *)
        doctor
        ;;
    esac
}

main "$@"
