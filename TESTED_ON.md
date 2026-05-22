# Tested Environment

The content in this repository was shaped against the following environments.

## Operating Systems

- Ubuntu 22.04 LTS (jammy)
- Ubuntu 24.04 LTS (noble)
- Debian 12 (bookworm)

## SSH

- OpenSSH 8.9p1 (Ubuntu 22.04 LTS default)
- OpenSSH 9.6p1 (Ubuntu 24.04 LTS default)
- OpenSSH 9.2p1 (Debian 12 default)

The SSH hardening configuration in this repository uses algorithm names supported by OpenSSH 8.x and newer. Where post-quantum or version-specific algorithms are used, they are clearly marked with the minimum OpenSSH version required.

## TLS / OpenSSL

- OpenSSL 3.0.x (Ubuntu 22.04 LTS, Debian 12)
- OpenSSL 3.2.x and 3.3.x (Ubuntu 24.04 LTS)

The TLS configurations align to Mozilla SSL Configuration Generator profiles. The Intermediate profile referenced in this repository was current as of Mozilla Server Side TLS guideline v5.8 (the October 2025 refresh that removed kDHE ciphers from Intermediate).

Reference: [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
Reference: [Mozilla Server Side TLS wiki](https://wiki.mozilla.org/Security/Server_Side_TLS)

## Web Servers

- Apache 2.4.52 (Ubuntu 22.04 LTS default)
- Apache 2.4.58 (Ubuntu 24.04 LTS default)
- Nginx 1.18.0 and 1.22.x (Ubuntu 22.04 LTS default and PPA)
- Nginx 1.24.0 (Ubuntu 24.04 LTS default)

## Firewall

- UFW 0.36.1 (Ubuntu 22.04 LTS)
- UFW 0.36.2 (Ubuntu 24.04 LTS)
- nftables 1.0.x (underlying iptables-nft backend on modern Ubuntu)

## DNS

- BIND 9.16 and 9.18 (where self-hosted)
- Cloudflare DNS (most commonly used as the DNS host in test environments)
- AWS Route 53 (also referenced)

The DNS hardening content covers DNSSEC, CAA, SPF, DKIM, and DMARC at the zone file level. The CAA and DMARC examples assume Let's Encrypt as the certificate authority and a small number of common mail providers.

## Notes on Compatibility

- The SSH hardening configuration uses an algorithm allowlist approach. This protects against weak algorithms but also opts out of any future algorithms OpenSSH may introduce. Review the configuration when upgrading OpenSSH major versions.
- TLS configurations target the Mozilla Intermediate profile, which supports TLS 1.2 and 1.3. Clients limited to TLS 1.0/1.1 will not connect.
- HSTS configurations are commented out by default. Enable only after confirming HTTPS works across the entire site.
- HSTS preload submission is essentially irreversible at the browser level. Do not preload a domain until you are committed to permanent HTTPS for the domain and all subdomains.
- DNSSEC configurations require coordination with your DNS host and domain registrar. Steps are documented but execution is platform-specific.
