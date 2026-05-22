# Web Infrastructure Security

Sanitized web infrastructure hardening content built from real Ubuntu-based web server deployments.

This repository focuses on practical SSH hardening, TLS configuration, security headers, firewall baselines, DNS protection (DNSSEC, CAA, SPF, DKIM, DMARC), and operator-safe implementation guidance. It is meant to be useful to defenders running self-managed VPS or dedicated server environments, and readable to engineers or business owners reviewing the work.

## Scope

This repository includes:

- SSH daemon hardening configuration with documented algorithm choices
- TLS configuration for Apache and Nginx aligned to Mozilla Intermediate
- Server-level security headers configurations
- UFW and iptables baseline firewall rules for web servers
- DNS hardening references for DNSSEC, CAA, SPF, DKIM, and DMARC
- Diagnostic scripts for verifying TLS, security headers, and SSH configuration
- Documentation written around manual placement, validation, rollback, and tuning discipline

This repository does not include:

- Full Linux distribution hardening automation
- Kernel parameter tuning beyond what affects web traffic
- Container security configurations
- Mail server hardening (only the DNS portions that affect web domains)
- Blind copy-all scripts
- Claims that every example here is universally safe to deploy without tuning

## Why this repository exists

A lot of public web server hardening content is either outdated, framework-specific (Wordpress-only, Plesk-only), or written as content marketing rather than engineering reference. The goal here is different:

- keep the structure clean
- keep the scope honest
- use only current, documented algorithm names and directives
- document real operational tradeoffs (especially around lockout risk)
- make validation and rollback first-class parts of the workflow

## Who this is for

This repository is aimed at:

- VPS and dedicated server operators running their own web hosting
- Web developers and agencies managing customer infrastructure
- Site reliability engineers handling web environments
- Security engineers reviewing server hardening
- Blue team engineers responsible for web-facing servers
- Business owners reviewing the work of Web Stack Defense

## Baseline environment

The content in this repository was shaped against real web server deployments running:

- Ubuntu 22.04 LTS and Ubuntu 24.04 LTS
- Debian 12
- OpenSSH 9.0+ (Ubuntu 22.04 LTS ships 8.9p1; commands are tested against both)
- Apache 2.4.x with mod_ssl, mod_headers, mod_rewrite
- Nginx 1.22.x and 1.24.x
- OpenSSL 3.0.x and 3.2.x
- UFW 0.36.x
- BIND 9 and Cloudflare-managed DNS as DNS hosts

For exact version and environment notes, see [TESTED_ON.md](TESTED_ON.md).

## Repository layout

```
configs/
  ssh/
  tls/
  headers/
  firewall/
  dns/

checklists/

scripts/

examples/
```

## Content design

The repository is intentionally split into:

**Server hardening configurations**
Hardened reference files for the layers where web infrastructure is enforced in practice: SSH daemon, TLS termination on Apache and Nginx, HTTP security headers, and host firewall rules. Every directive is commented with the reason it exists and the version of OpenSSH, OpenSSL, Apache, or Nginx the directive applies to.

**DNS hardening references**
Configurations and zone file fragments for DNS-layer protections that affect web traffic: DNSSEC enablement, CAA records, SPF, DKIM, and DMARC. These are scoped to what websites need, not full mail server DNS hardening.

**Checklists**
Operational checklists for server hardening, TLS validation, and firewall verification. Written to be used during real reviews, not just read once.

**Scripts**
Read-only diagnostic scripts for auditing TLS configuration, security headers, and SSH server hardening. No script in this repository modifies a live server's configuration files.

## Installation philosophy

This repository assumes manual configuration and deployment.

That is deliberate.

Web infrastructure hardening creates real lockout risk. An incorrect SSH configuration can lock you out of the server. An incorrect firewall rule can take the site offline. An aggressive TLS configuration can break older clients you didn't know were connecting. The realistic value of public hardening content is as a reference to adapt, not as a copy-paste deployment.

Review the configuration first. Take a backup of the current state. Apply one change at a time. Validate from a separate session. Keep a recovery method open until you've confirmed the change works.

## Validation workflow

Recommended order for any configuration change:

1. Open a separate, independent session to the server before making changes
2. Take a backup of the file being modified
3. Apply the change
4. Validate syntax (`sshd -t`, `nginx -t`, `apache2ctl configtest`)
5. Reload the service (do not restart unless required — reload is safer)
6. From the original separate session, verify the change took effect
7. From a new session, verify the service is still reachable
8. Only close the original session after the new session is confirmed working
9. Document the change

This workflow has prevented more lockouts than any specific configuration directive.

## Risks and guardrails

This repository assumes you understand the following risks:

- SSH configuration changes can lock you out of the server permanently if applied without an open recovery session
- Firewall rule changes can take the site or the SSH port offline
- TLS configuration that disables older protocols can break older clients (mobile apps with hardcoded TLS 1.0/1.1, legacy integrations)
- Security headers can break embeds, third-party scripts, and analytics
- HSTS preloading is essentially irreversible once browsers cache it
- DNSSEC misconfiguration can make the entire domain unresolvable
- CAA records that exclude your actual CA will block certificate renewal
- DMARC `p=reject` policies block legitimate mail if SPF and DKIM are not aligned
- Auto-update configurations can apply breaking changes during business hours

## Redaction policy

Nothing in this repository should expose:

- public or internal IP addresses tied to a real deployment
- domains tied to private infrastructure
- API keys, certificates, or private keys
- usernames or account identifiers
- hostnames unique to a specific deployment
- file paths that would only exist in a single environment

All examples use the documentation reserved range `203.0.113.0/24` for IP addresses, `example.com` for domain names, and clearly marked placeholder variables for credentials and identifiers.

## Affiliate disclosure

Some setup notes may reference hosting providers or commercial security tools using affiliate links. If you choose to use one, Web Stack Defense may receive a referral credit at no extra cost to you. Support is appreciated, but use whatever provider or tool fits your environment.

## Related platform

This repository is part of the broader website security work documented at [Web Stack Defense](https://www.webstackdefense.com). Guides on the site go deeper into context, tradeoffs, and implementation decisions. The configurations and checklists here are the practical artifacts that sit alongside those guides.

## Contribution policy

Issues and curated pull requests are allowed, but this is not an open-ended community repo where every submission will be merged.

Security issues should be reported privately according to [SECURITY.md](SECURITY.md).

Contribution standards are documented in [CONTRIBUTING.md](CONTRIBUTING.md).
