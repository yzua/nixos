#!/usr/bin/env bash
set -euo pipefail
# TOTP code generation for web RE 2FA testing.
# Usage: generate-totp.sh <base32_secret> [period=30] [digits=6] [algorithm=sha1]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/logging.sh"

trap 'log_error "command failed at line ${LINENO}: ${BASH_COMMAND}"' ERR

cmd_generate() {
    local secret="$1"
    local period="${2:-30}"
    local digits="${3:-6}"
    local algorithm="${4:-sha1}"

    # Normalize algorithm to uppercase for display
    local algo_upper
    algo_upper="$(echo "${algorithm}" | tr '[:lower:]' '[:upper:]')"

    python3 -c "
import base64, hashlib, hmac, struct, time, sys

secret = '${secret}'
period = ${period}
digits = ${digits}
algorithm = '${algo_upper}'

# Map algorithm name to hashlib function
algo_map = {
    'SHA1': hashlib.sha1,
    'SHA256': hashlib.sha256,
    'SHA512': hashlib.sha512,
}
if algorithm not in algo_map:
    print(f'ERROR: unsupported algorithm: {algorithm}', file=sys.stderr)
    sys.exit(1)
hash_func = algo_map[algorithm]

# Decode base32 secret (strip whitespace and padding)
key = base64.b32decode(secret.strip().upper() + '=' * (-len(secret.strip()) % 8))

# Calculate TOTP
timestamp = int(time.time())
counter = timestamp // period
remaining = period - (timestamp % period)

# HMAC-based one-time password
counter_bytes = struct.pack('>Q', counter)
hmac_digest = hmac.new(key, counter_bytes, hash_func).digest()
offset = hmac_digest[-1] & 0x0F
truncated = struct.unpack('>I', hmac_digest[offset:offset+4])[0] & 0x7FFFFFFF
otp = truncated % (10 ** digits)

print(f'{otp:0{digits}d}')
print(f'remaining={remaining}s period={period} algorithm={algorithm}')
" || error_exit "TOTP generation failed"
}

usage() {
    cat <<'EOF'
Usage: generate-totp.sh <base32_secret> [period] [digits] [algorithm]

Arguments:
  base32_secret   Base32-encoded TOTP secret
  period          Time step in seconds (default: 30)
  digits          Number of OTP digits (default: 6)
  algorithm       HMAC algorithm: sha1, sha256, sha512 (default: sha1)

WARNING: This tool is for authorized security testing only.
EOF
}

main() {
    # Print warning on every invocation
    log_warning "This tool is for authorized security testing only."

    local cmd="${1:-}"
    case "${cmd}" in
    -h|--help|help)
        usage
        ;;
    *)
        [[ -n "${cmd}" ]] || error_exit "generate-totp requires base32_secret"
        cmd_generate "$1" "${2:-}" "${3:-}" "${4:-}"
        ;;
    esac
}

main "$@"
