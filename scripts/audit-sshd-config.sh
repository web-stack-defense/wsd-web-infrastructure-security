#!/usr/bin/env bash
# =============================================================================
# SSH Server Hardening Audit
#
# Repository: wsd-web-infrastructure-security
# Maintained as part of Web Stack Defense — https://www.webstackdefense.com
#
# Read-only audit script. Does not modify any configuration.
#
# Audits the local sshd configuration for common hardening directives.
# Reports findings to stdout. Returns exit code 0 if no issues found,
# 1 if issues found.
#
# This script reports the EFFECTIVE configuration (what sshd would
# actually use), not just what is in /etc/ssh/sshd_config. This catches
# directives set in included config files (sshd_config.d/*) and via
# command-line overrides.
#
# Usage:
#   sudo ./audit-sshd-config.sh
#
# Requirements:
#   - sshd installed
#   - Bash 4.0+
#   - Root or sudo (for sshd -T to dump effective config)
# =============================================================================

set -euo pipefail


# -----------------------------------------------------------------------------
# Pre-flight checks
# -----------------------------------------------------------------------------

if ! command -v sshd &>/dev/null; then
    # Try the common sbin location.
    if [[ -x /usr/sbin/sshd ]]; then
        SSHD="/usr/sbin/sshd"
    else
        echo "Error: sshd not found in PATH or /usr/sbin/sshd." >&2
        exit 1
    fi
else
    SSHD="$(command -v sshd)"
fi

# sshd -T requires root. Warn if not running as root.
if [[ "${EUID}" -ne 0 ]]; then
    echo "Warning: not running as root. sshd -T may fail." >&2
    echo "         Run with sudo for accurate results." >&2
    echo ""
fi


# -----------------------------------------------------------------------------
# Get effective configuration
# -----------------------------------------------------------------------------

CONFIG=$("${SSHD}" -T 2>/dev/null) || {
    echo "Error: sshd -T failed. Are you running as root?" >&2
    exit 1
}


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

# Get a directive value from the effective config.
get_value() {
    local directive="$1"
    # sshd -T output is lowercase directive names, space-separated.
    echo "${CONFIG}" | grep -i "^${directive} " | head -1 | cut -d' ' -f2-
}


# -----------------------------------------------------------------------------
# Check: SSHD version
# -----------------------------------------------------------------------------

report_section "SSH server version"

VERSION=$("${SSHD}" -V 2>&1 | head -1 || "${SSHD}" -v 2>&1 | grep -i "openssh" | head -1 || true)
SSH_VERSION=$(ssh -V 2>&1 || true)

report_info "${SSH_VERSION}"


# -----------------------------------------------------------------------------
# Check: Authentication settings
# -----------------------------------------------------------------------------

report_section "Authentication"

PASS_AUTH=$(get_value "passwordauthentication")
if [[ "${PASS_AUTH}" == "no" ]]; then
    report_ok "PasswordAuthentication is disabled"
else
    report_issue "PasswordAuthentication is enabled (${PASS_AUTH}) — should be 'no'"
fi

EMPTY_PASS=$(get_value "permitemptypasswords")
if [[ "${EMPTY_PASS}" == "no" ]]; then
    report_ok "PermitEmptyPasswords is disabled"
else
    report_issue "PermitEmptyPasswords is enabled (${EMPTY_PASS}) — should be 'no'"
fi

PUBKEY=$(get_value "pubkeyauthentication")
if [[ "${PUBKEY}" == "yes" ]]; then
    report_ok "PubkeyAuthentication is enabled"
else
    report_issue "PubkeyAuthentication is disabled — should be 'yes'"
fi

ROOT_LOGIN=$(get_value "permitrootlogin")
case "${ROOT_LOGIN}" in
    no|prohibit-password|forced-commands-only)
        report_ok "PermitRootLogin is restricted (${ROOT_LOGIN})"
        ;;
    yes)
        report_issue "PermitRootLogin is 'yes' — should be 'no' or 'prohibit-password'"
        ;;
    *)
        report_info "PermitRootLogin is '${ROOT_LOGIN}'"
        ;;
esac


# -----------------------------------------------------------------------------
# Check: Login restrictions
# -----------------------------------------------------------------------------

report_section "Login restrictions"

MAX_AUTH=$(get_value "maxauthtries")
if [[ -n "${MAX_AUTH}" ]] && [[ "${MAX_AUTH}" -le 3 ]]; then
    report_ok "MaxAuthTries is ${MAX_AUTH} (good)"
elif [[ -n "${MAX_AUTH}" ]] && [[ "${MAX_AUTH}" -le 6 ]]; then
    report_info "MaxAuthTries is ${MAX_AUTH} (default — consider reducing to 3)"
else
    report_issue "MaxAuthTries is ${MAX_AUTH:-not set} (should be 3 or lower)"
fi

LOGIN_GRACE=$(get_value "logingracetime")
report_info "LoginGraceTime: ${LOGIN_GRACE:-default}"

CLIENT_ALIVE=$(get_value "clientaliveinterval")
report_info "ClientAliveInterval: ${CLIENT_ALIVE:-default}"


# -----------------------------------------------------------------------------
# Check: Forwarding restrictions
# -----------------------------------------------------------------------------

report_section "Forwarding restrictions"

for directive in "x11forwarding" "allowtcpforwarding" "allowagentforwarding" "gatewayports"; do
    VALUE=$(get_value "${directive}")
    if [[ "${VALUE}" == "no" ]]; then
        report_ok "${directive} is disabled"
    else
        report_info "${directive} is enabled (${VALUE}) — disable if not needed"
    fi
done


# -----------------------------------------------------------------------------
# Check: Logging
# -----------------------------------------------------------------------------

report_section "Logging"

LOG_LEVEL=$(get_value "loglevel")
if [[ "${LOG_LEVEL}" == "verbose" ]] || [[ "${LOG_LEVEL}" == "VERBOSE" ]]; then
    report_ok "LogLevel is VERBOSE (good for audit trails)"
else
    report_info "LogLevel is '${LOG_LEVEL}' — VERBOSE is recommended for audit"
fi


# -----------------------------------------------------------------------------
# Check: Algorithm allowlists
# -----------------------------------------------------------------------------

report_section "Cryptographic algorithms"

# Check Ciphers for weak algorithms.
CIPHERS=$(get_value "ciphers")
WEAK_CIPHERS=()
for weak in "3des-cbc" "aes128-cbc" "aes192-cbc" "aes256-cbc" "arcfour" "blowfish-cbc" "cast128-cbc"; do
    if echo "${CIPHERS}" | grep -q "${weak}"; then
        WEAK_CIPHERS+=("${weak}")
    fi
done
if [[ ${#WEAK_CIPHERS[@]} -gt 0 ]]; then
    report_issue "Weak ciphers enabled: ${WEAK_CIPHERS[*]}"
else
    report_ok "No known-weak ciphers in Ciphers list"
fi

# Check MACs for weak algorithms.
MACS=$(get_value "macs")
WEAK_MACS=()
for weak in "hmac-md5" "hmac-md5-96" "hmac-sha1-96" "umac-64"; do
    if echo "${MACS}" | grep -q "${weak}"; then
        WEAK_MACS+=("${weak}")
    fi
done
if [[ ${#WEAK_MACS[@]} -gt 0 ]]; then
    report_issue "Weak MACs enabled: ${WEAK_MACS[*]}"
else
    report_ok "No known-weak MACs in MACs list"
fi

# Check KexAlgorithms for weak algorithms.
KEX=$(get_value "kexalgorithms")
WEAK_KEX=()
for weak in "diffie-hellman-group1-sha1" "diffie-hellman-group14-sha1" "diffie-hellman-group-exchange-sha1"; do
    if echo "${KEX}" | grep -q "${weak}"; then
        WEAK_KEX+=("${weak}")
    fi
done
if [[ ${#WEAK_KEX[@]} -gt 0 ]]; then
    report_issue "Weak key exchange algorithms enabled: ${WEAK_KEX[*]}"
else
    report_ok "No known-weak key exchange algorithms in KexAlgorithms list"
fi


# -----------------------------------------------------------------------------
# Check: Port and listen
# -----------------------------------------------------------------------------

report_section "Network configuration"

PORTS=$(get_value "port")
report_info "Listening port(s): ${PORTS}"

LISTEN=$(echo "${CONFIG}" | grep "^listenaddress " | awk '{print $2}' | tr '\n' ' ')
if [[ -n "${LISTEN}" ]]; then
    report_info "Listen addresses: ${LISTEN}"
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
