#!/usr/bin/env bash
# =============================================================================
# TLS Configuration Verification
#
# Repository: wsd-web-infrastructure-security
# Maintained as part of Web Stack Defense — https://www.webstackdefense.com
#
# Read-only verification script. Does not modify any configuration.
#
# Verifies the TLS configuration of a remote web server by connecting
# with openssl s_client and checking:
#
#   - Which TLS protocol versions are supported
#   - Whether the certificate chain validates
#   - Certificate expiration date
#   - Whether HSTS header is present
#   - Whether key security headers are present
#
# Usage:
#   ./verify-tls.sh example.com
#   ./verify-tls.sh example.com 443
#
# Requirements:
#   - openssl
#   - curl
#   - Bash 4.0+
# =============================================================================

set -euo pipefail


# -----------------------------------------------------------------------------
# Argument handling
# -----------------------------------------------------------------------------

if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
    echo "Usage: $0 <hostname> [port]" >&2
    echo "Example: $0 example.com" >&2
    echo "Example: $0 example.com 443" >&2
    exit 2
fi

HOST="$1"
PORT="${2:-443}"


# -----------------------------------------------------------------------------
# Pre-flight checks
# -----------------------------------------------------------------------------

for tool in openssl curl; do
    if ! command -v "$tool" &>/dev/null; then
        echo "Error: $tool is not installed." >&2
        exit 1
    fi
done


# -----------------------------------------------------------------------------
# Output helpers
# -----------------------------------------------------------------------------

ISSUES=0

report_section() {
    echo ""
    echo "=============================================================="
    echo "  $1"
    echo "=============================================================="
}

report_ok() {
    echo "  [OK]    $1"
}

report_issue() {
    echo "  [ISSUE] $1"
    ISSUES=$((ISSUES + 1))
}

report_info() {
    echo "  [INFO]  $1"
}


# -----------------------------------------------------------------------------
# Check 1: Protocol versions
# -----------------------------------------------------------------------------

report_section "TLS protocol support — ${HOST}:${PORT}"

for proto in tls1 tls1_1 tls1_2 tls1_3; do
    if echo "" | timeout 10 openssl s_client -connect "${HOST}:${PORT}" \
        -servername "${HOST}" -"${proto}" 2>/dev/null \
        | grep -q "BEGIN CERTIFICATE"; then
        case "${proto}" in
            tls1|tls1_1)
                report_issue "${proto} is supported (should be disabled)"
                ;;
            tls1_2|tls1_3)
                report_ok "${proto} is supported"
                ;;
        esac
    else
        case "${proto}" in
            tls1|tls1_1)
                report_ok "${proto} is correctly disabled"
                ;;
            tls1_2|tls1_3)
                report_issue "${proto} is NOT supported (should be enabled)"
                ;;
        esac
    fi
done


# -----------------------------------------------------------------------------
# Check 2: Certificate validity and expiration
# -----------------------------------------------------------------------------

report_section "Certificate validation"

CERT_OUTPUT=$(echo "" | timeout 10 openssl s_client -connect "${HOST}:${PORT}" \
    -servername "${HOST}" -verify_return_error 2>&1 || true)

if echo "${CERT_OUTPUT}" | grep -q "Verify return code: 0 (ok)"; then
    report_ok "Certificate chain validates"
else
    report_issue "Certificate chain validation failed"
    echo "${CERT_OUTPUT}" | grep -A 1 "Verify return code" | sed 's/^/        /'
fi

# Extract expiration date.
EXPIRY=$(echo "" | timeout 10 openssl s_client -connect "${HOST}:${PORT}" \
    -servername "${HOST}" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null \
    | sed 's/notAfter=//')

if [[ -n "${EXPIRY}" ]]; then
    EXPIRY_EPOCH=$(date -d "${EXPIRY}" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    DAYS_REMAINING=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

    if [[ "${DAYS_REMAINING}" -lt 0 ]]; then
        report_issue "Certificate EXPIRED ${DAYS_REMAINING#-} days ago"
    elif [[ "${DAYS_REMAINING}" -lt 14 ]]; then
        report_issue "Certificate expires in ${DAYS_REMAINING} days (renewal urgent)"
    elif [[ "${DAYS_REMAINING}" -lt 30 ]]; then
        report_info "Certificate expires in ${DAYS_REMAINING} days"
    else
        report_ok "Certificate expires in ${DAYS_REMAINING} days (${EXPIRY})"
    fi
else
    report_issue "Could not determine certificate expiration"
fi


# -----------------------------------------------------------------------------
# Check 3: HSTS header
# -----------------------------------------------------------------------------

report_section "HSTS header"

HSTS=$(curl -sI --max-time 10 "https://${HOST}/" 2>/dev/null \
    | grep -i "^strict-transport-security:" || true)

if [[ -n "${HSTS}" ]]; then
    report_ok "HSTS header present: $(echo "${HSTS}" | tr -d '\r\n')"

    # Check max-age value.
    MAX_AGE=$(echo "${HSTS}" | grep -oE 'max-age=[0-9]+' | sed 's/max-age=//' || echo "0")
    if [[ "${MAX_AGE}" -lt 31536000 ]]; then
        report_info "HSTS max-age is ${MAX_AGE} seconds (recommended: 31536000 = 1 year)"
    fi
else
    report_info "HSTS header not present (acceptable if HTTPS rollout is incomplete)"
fi


# -----------------------------------------------------------------------------
# Check 4: Other security headers
# -----------------------------------------------------------------------------

report_section "Security headers"

HEADERS=$(curl -sI --max-time 10 "https://${HOST}/" 2>/dev/null || echo "")

for header in "x-content-type-options" "x-frame-options" "referrer-policy" "permissions-policy"; do
    VALUE=$(echo "${HEADERS}" | grep -i "^${header}:" || true)
    if [[ -n "${VALUE}" ]]; then
        report_ok "${header} present"
    else
        report_issue "${header} missing"
    fi
done

# Content-Security-Policy is checked but missing is not flagged as an issue.
CSP=$(echo "${HEADERS}" | grep -iE "^content-security-policy(-report-only)?:" || true)
if [[ -n "${CSP}" ]]; then
    report_ok "content-security-policy present"
else
    report_info "content-security-policy not configured (requires tuning per-site)"
fi


# -----------------------------------------------------------------------------
# Check 5: Server header
# -----------------------------------------------------------------------------

report_section "Server identification"

SERVER=$(echo "${HEADERS}" | grep -i "^server:" || true)
X_POWERED=$(echo "${HEADERS}" | grep -i "^x-powered-by:" || true)

if [[ -n "${SERVER}" ]]; then
    if echo "${SERVER}" | grep -qE "Apache/[0-9]|nginx/[0-9]|LiteSpeed/[0-9]"; then
        report_issue "Server header reveals version: $(echo "${SERVER}" | tr -d '\r\n')"
    else
        report_ok "Server header present without version: $(echo "${SERVER}" | tr -d '\r\n')"
    fi
fi

if [[ -n "${X_POWERED}" ]]; then
    report_issue "X-Powered-By header present: $(echo "${X_POWERED}" | tr -d '\r\n')"
else
    report_ok "X-Powered-By header not present"
fi


# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

report_section "Summary"

if [[ "${ISSUES}" -eq 0 ]]; then
    echo "  No issues found."
    exit 0
else
    echo "  ${ISSUES} issue(s) found. Review above for details."
    exit 1
fi
