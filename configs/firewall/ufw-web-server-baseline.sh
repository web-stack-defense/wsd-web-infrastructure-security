#!/usr/bin/env bash
# =============================================================================
# UFW Baseline for Web Servers
#
# Repository: wsd-web-infrastructure-security
# Maintained as part of Web Stack Defense — https://www.webstackdefense.com
#
# Establishes a baseline UFW firewall configuration for a public-facing
# web server. Opens HTTP, HTTPS, and SSH. Denies everything else inbound.
# Allows all outbound traffic.
#
# What this script does:
#
#   1. Sets default policies (deny incoming, allow outgoing)
#   2. Allows SSH from an admin source range (placeholder — REPLACE)
#   3. Allows HTTP and HTTPS from anywhere
#   4. Optionally enables UFW logging
#
# What this script does NOT do:
#
#   - Enable UFW (the script prints the enable command for you to run
#     deliberately, since enabling UFW with no SSH rule loses your session)
#   - Modify any existing rules silently
#   - Configure IPv6-specific rules beyond what UFW does by default
#
# CRITICAL: If you are connected over SSH, do NOT enable UFW without
# first confirming an SSH allow rule is in place. Enabling UFW with the
# default deny policy and no SSH allow rule will lock you out.
#
# Usage:
#   sudo ./ufw-web-server-baseline.sh
#
# Then review the rules and enable UFW manually:
#   sudo ufw status numbered
#   sudo ufw enable
#
# Requirements:
#   - Root or sudo access
#   - UFW installed (apt install ufw)
#   - Bash 4.0+
# =============================================================================

set -euo pipefail


# -----------------------------------------------------------------------------
# Pre-flight checks
# -----------------------------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
    echo "Error: this script must be run as root or with sudo." >&2
    exit 1
fi

if ! command -v ufw &>/dev/null; then
    echo "Error: ufw is not installed. Install with: apt install ufw" >&2
    exit 1
fi


# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
# REPLACE the ADMIN_SOURCE_RANGE value below with your actual administrative
# source IP range before running this script. The placeholder is the
# documentation reserved range 203.0.113.0/24 and will allow no real
# administrators to connect.
#
# Common patterns:
#   - Single IP:          203.0.113.42
#   - Small range:        203.0.113.0/24
#   - Multiple ranges:    declare an array (see commented example below)
#
# If you do not have a stable admin source IP and need SSH open to the
# world, replace ADMIN_SOURCE_RANGE with "any" — but that significantly
# increases brute force exposure. Strongly consider an SSH bastion or
# WireGuard VPN instead.
# -----------------------------------------------------------------------------

ADMIN_SOURCE_RANGE="203.0.113.0/24"   # REPLACE with your actual admin source range

# Example: multiple ranges
# ADMIN_RANGES=("203.0.113.0/24" "198.51.100.0/24")
# for range in "${ADMIN_RANGES[@]}"; do
#     ufw allow proto tcp from "$range" to any port 22 comment "SSH admin"
# done


# -----------------------------------------------------------------------------
# Set default policies
# -----------------------------------------------------------------------------
# Default deny incoming, default allow outgoing. This is the standard
# baseline for an internet-facing server.
# -----------------------------------------------------------------------------

echo "Setting default policies (deny incoming, allow outgoing)..."
ufw default deny incoming
ufw default allow outgoing


# -----------------------------------------------------------------------------
# Allow SSH from the admin source range
# -----------------------------------------------------------------------------
# This rule MUST be in place before UFW is enabled. Without it, enabling
# UFW will immediately disconnect any active SSH sessions.
# -----------------------------------------------------------------------------

echo "Adding SSH allow rule for ${ADMIN_SOURCE_RANGE}..."
ufw allow proto tcp from "${ADMIN_SOURCE_RANGE}" to any port 22 comment "SSH admin"


# -----------------------------------------------------------------------------
# Allow HTTP and HTTPS
# -----------------------------------------------------------------------------
# Public-facing web traffic. Allowed from anywhere.
# -----------------------------------------------------------------------------

echo "Adding HTTP and HTTPS allow rules..."
ufw allow proto tcp from any to any port 80 comment "HTTP"
ufw allow proto tcp from any to any port 443 comment "HTTPS"


# -----------------------------------------------------------------------------
# Enable logging
# -----------------------------------------------------------------------------
# UFW logging levels:
#   off    - No logging
#   low    - Logs blocked packets (default in many systems)
#   medium - Logs blocked packets + new connections that match no rule
#   high   - Verbose, will fill up logs quickly on a public-facing server
#   full   - Everything, only useful for debugging
#
# "low" is the right baseline. "medium" is useful for the first 30 days
# after deployment for tuning.
# -----------------------------------------------------------------------------

echo "Setting UFW logging to low..."
ufw logging low


# -----------------------------------------------------------------------------
# Show resulting configuration
# -----------------------------------------------------------------------------

echo ""
echo "Current UFW configuration (rules added, but UFW not yet enabled):"
echo ""
ufw show added

echo ""
echo "==================================================================="
echo "Next steps:"
echo ""
echo "  1. Review the rules above."
echo ""
echo "  2. CONFIRM you have SSH access from the configured admin range:"
echo "       Current admin range: ${ADMIN_SOURCE_RANGE}"
echo ""
echo "  3. If everything looks correct, ENABLE UFW manually:"
echo "       sudo ufw enable"
echo ""
echo "  4. Verify UFW is active and rules are in effect:"
echo "       sudo ufw status verbose"
echo ""
echo "  5. From a NEW session (not this one), confirm SSH still works."
echo "==================================================================="
