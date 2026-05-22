# Web Server Hardening Checklist

Checklist for hardening a public-facing web server. Use during initial provisioning or as a periodic audit on existing servers.

## Pre-flight

- [ ] Server is provisioned with a current LTS Linux distribution (Ubuntu 22.04 LTS, 24.04 LTS, Debian 12)
- [ ] Server has a known, stable administrative source IP range (or a documented bastion / VPN access pattern)
- [ ] At least one alternative recovery method exists (console access through hosting provider, separate admin user)
- [ ] Time on the server is correct (`timedatectl status`) — critical for TLS certificate validation and log correlation
- [ ] Server is fully updated (`apt update && apt upgrade`) before applying hardening changes
- [ ] Backup of current configuration files is taken

## User Accounts and Privileges

- [ ] No user has the password `root` or matches the hosting provider's default
- [ ] Root account password is set (even if root login is disabled — set a strong password as defense-in-depth)
- [ ] A non-root administrative user exists with sudo access
- [ ] Default cloud images' `ubuntu`, `admin`, `ec2-user` etc. are reviewed and renamed or removed
- [ ] No accounts have a UID of 0 except `root`
- [ ] No accounts have empty password fields (`awk -F: '($2 == "") {print}' /etc/shadow`)
- [ ] System service accounts have `/usr/sbin/nologin` or `/bin/false` as shell

## SSH Configuration

Apply the configuration from `configs/ssh/sshd_config.hardened`. Verify:

- [ ] SSH key for the admin user is in `~/.ssh/authorized_keys`
- [ ] SSH key permissions are correct (`~/.ssh` is 700, `authorized_keys` is 600)
- [ ] `PasswordAuthentication no` is set
- [ ] `PermitRootLogin prohibit-password` or `no` is set
- [ ] `PermitEmptyPasswords no` is set
- [ ] `MaxAuthTries 3` is set
- [ ] `LogLevel VERBOSE` is set
- [ ] Algorithm allowlists (Ciphers, MACs, KexAlgorithms) are set per the hardened config
- [ ] `sshd -t` returns no errors before reloading
- [ ] `sudo systemctl reload ssh` succeeds
- [ ] Login from a NEW session works before closing the original session
- [ ] `audit-sshd-config.sh` returns no issues

## Firewall

Apply the configuration from `configs/firewall/ufw-web-server-baseline.sh`. Verify:

- [ ] UFW default policy is `deny incoming, allow outgoing`
- [ ] SSH allow rule is in place from the admin source range (NOT from anywhere)
- [ ] HTTP (port 80) is allowed from anywhere
- [ ] HTTPS (port 443) is allowed from anywhere
- [ ] No other inbound ports are open
- [ ] UFW is enabled (`ufw status` shows "Status: active")
- [ ] UFW logging is set to `low` (or `medium` during initial deployment for tuning)
- [ ] IPv6 traffic is also restricted (UFW handles this by default if IPv6 is configured in `/etc/default/ufw`)

## TLS Configuration

Apply the configuration from `configs/tls/`. Verify:

- [ ] Valid TLS certificate is installed (Let's Encrypt or commercial)
- [ ] Certificate expiration is more than 14 days away (`verify-tls.sh` checks this)
- [ ] TLS 1.0 and TLS 1.1 are disabled
- [ ] TLS 1.2 is supported
- [ ] TLS 1.3 is supported
- [ ] Cipher suite list matches Mozilla Intermediate (no CBC, no DHE per v5.8+)
- [ ] OCSP stapling is enabled (note: Let's Encrypt deprecated OCSP URLs in 2024, so this may show as inactive)
- [ ] HTTP to HTTPS redirect is in place
- [ ] `verify-tls.sh example.com` returns no issues

## Security Headers

Apply the configuration from `configs/headers/`. Verify:

- [ ] X-Content-Type-Options: nosniff is set
- [ ] X-Frame-Options: SAMEORIGIN (or DENY) is set
- [ ] Referrer-Policy is set
- [ ] Permissions-Policy is set
- [ ] X-Powered-By header is stripped
- [ ] Server header does not reveal version (ServerTokens Prod for Apache, server_tokens off for Nginx)
- [ ] HSTS is reviewed but only enabled after HTTPS is confirmed working everywhere

## DNS Records

Apply the references from `configs/dns/zone-fragments.txt`. Verify:

- [ ] CAA record(s) are set and include your actual CA (verify before adding)
- [ ] SPF record is set (`-all` for non-mail-sending domains, `~all` for sending domains)
- [ ] DKIM record is set if mail is sent (from mail provider's recommendation)
- [ ] DMARC record is set, starting with `p=none` for monitoring
- [ ] DNSSEC is enabled at the DNS host AND DS record is published at registrar
- [ ] DNSSEC validation passes ([dnssec-analyzer.verisignlabs.com](https://dnssec-analyzer.verisignlabs.com/), [dnsviz.net](https://dnsviz.net/))

## Software Updates and Patching

- [ ] `unattended-upgrades` is installed and configured for security updates
- [ ] `/etc/apt/apt.conf.d/50unattended-upgrades` is configured to apply security updates automatically
- [ ] `/etc/apt/apt.conf.d/20auto-upgrades` is set to run `Update-Package-Lists "1"` and `Unattended-Upgrade "1"`
- [ ] Reboots after kernel updates are scheduled (or `needrestart` is configured)
- [ ] Major version upgrades are NOT automatic — these require manual review

## Filesystem Hardening

- [ ] `/tmp` is mounted with `noexec`, `nosuid`, `nodev` (separate partition or tmpfs)
- [ ] `/var/tmp` is similarly mounted, or is a symlink to `/tmp`
- [ ] SUID and SGID binaries are reviewed (`find / -perm -4000 -o -perm -2000 -type f 2>/dev/null`)
- [ ] World-writable files are reviewed (`find / -type f -perm -002 -not -path /proc/\* 2>/dev/null`)
- [ ] Sensitive files have appropriate permissions:
  - [ ] `/etc/shadow` is 640 root:shadow
  - [ ] `/etc/ssh/sshd_config` is 600 root:root
  - [ ] `/etc/sudoers` is 440 root:root

## Logging and Monitoring

- [ ] `/var/log/auth.log` (Debian/Ubuntu) or `/var/log/secure` (RHEL family) is being written
- [ ] Log rotation is configured (`/etc/logrotate.d/`)
- [ ] Logs are retained for at least 90 days
- [ ] Disk space monitoring exists (`/var/log` filling up is a common failure mode)
- [ ] External monitoring exists (uptime checks, certificate expiration alerts)

## Fail2ban or Equivalent (Recommended)

- [ ] `fail2ban` is installed and active
- [ ] SSH jail is enabled (`/etc/fail2ban/jail.local`)
- [ ] Web server jail is enabled if applicable (Nginx, Apache)
- [ ] Ban duration is at least 1 hour for repeat offenders
- [ ] Ban thresholds are documented

## Final Validation

- [ ] All hardening changes have been documented
- [ ] Recovery procedure is documented (what to do if locked out)
- [ ] Reboot the server to verify all services come back up correctly
- [ ] After reboot: SSH works, web server is up, TLS is valid, firewall is active
- [ ] External scan from securityheaders.com or observatory.mozilla.org returns a passing grade
- [ ] Next audit date is scheduled (recommended: quarterly)
