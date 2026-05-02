#!/usr/bin/env bash
set -euo pipefail
# Comprehensive tool audit for Web RE agent.
# Checks all tools needed for web RE workflows.

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

check_browser() {
    TOTAL=$((TOTAL + 1))
    if command -v google-chrome-stable >/dev/null 2>&1; then
        log_success "tool present: google-chrome-stable -> $(command -v google-chrome-stable)"
        PRESENT=$((PRESENT + 1))
    elif command -v chromium >/dev/null 2>&1; then
        log_success "tool present: chromium -> $(command -v chromium)"
        PRESENT=$((PRESENT + 1))
    else
        log_warning "tool missing: google-chrome-stable (or chromium)"
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

check_uvx() {
    TOTAL=$((TOTAL + 1))
    if command -v uvx >/dev/null 2>&1; then
        local ver
        ver="$(uvx --version 2>/dev/null || echo 'unknown')"
        log_success "tool present: uvx -> ${ver}"
        PRESENT=$((PRESENT + 1))
    else
        log_warning "tool missing: uvx"
        MISSING=$((MISSING + 1))
    fi
}

doctor() {
    echo ""
    log_info "=== Web RE Doctor ==="
    echo ""

    log_info "--- Browser ---"
    check_browser

    echo ""
    log_info "--- Proxy ---"
    for tool in mitmdump burpsuite; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Recon ---"
    for tool in subfinder amass httpx whatweb katana rustscan; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Vulnerability Scanning ---"
    for tool in nuclei nikto sqlmap dalfox zap semgrep commix; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Fuzzing ---"
    for tool in ffuf arjun gobuster feroxbuster; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Network ---"
    for tool in nmap masscan tcpdump tshark wireshark-cli; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- HTTP Clients ---"
    for tool in curl httpie hurl bruno grpcurl; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- Analysis ---"
    for tool in cyberchef jq linkfinder trivy testssl; do
        check_and_count "${tool}"
    done

    echo ""
    log_info "--- OOB ---"
    check_and_count interactsh

    echo ""
    log_info "--- Auth ---"
    check_and_count hydra

    echo ""
    log_info "--- Core ---"
    check_and_count git

    echo ""
    log_info "--- Python Modules ---"
    check_python_module waybackpy

    echo ""
    log_info "--- Tool Runners ---"
    check_uvx

    echo ""
    log_info "=== Summary: ${PRESENT}/${TOTAL} tools present, ${MISSING} missing ==="
}

usage() {
    cat <<'EOF'
Usage: web-re-doctor.sh

Comprehensive tool audit for Web RE agent. Checks all tools
needed for web RE workflows grouped by category.

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
