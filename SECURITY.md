# Security Policy

This repository contains web infrastructure hardening references intended for use in defensive web security work.

## Reporting Security Issues in This Repository

If you find a security issue in any configuration, script, or guide in this repository that could cause harm if applied as written, please report it privately.

**Do not file public GitHub issues for security problems in the content itself.**

To report a security issue:

- Open a private security advisory through GitHub's security advisory feature
- Or contact Web Stack Defense through [webstackdefense.com](https://www.webstackdefense.com)

Reports should include:

- The file or section affected
- A description of the issue
- The conditions under which the issue would cause harm
- Suggested remediation if known

## Reporting Vulnerabilities in Upstream Software

This repository is not the correct venue for reporting vulnerabilities in OpenSSH, OpenSSL, Apache, Nginx, BIND, or any other upstream software. Those should be reported to the projects directly:

- OpenSSH: [https://www.openssh.com/security.html](https://www.openssh.com/security.html)
- OpenSSL: [https://www.openssl.org/news/vulnerabilities.html](https://www.openssl.org/news/vulnerabilities.html)
- Apache: [https://httpd.apache.org/security_report.html](https://httpd.apache.org/security_report.html)
- Nginx: [https://nginx.org/en/security_advisories.html](https://nginx.org/en/security_advisories.html)
- BIND: [https://www.isc.org/security/](https://www.isc.org/security/)

## Disclaimer

All content in this repository is provided for reference. Test all configurations in a non-production environment before deploying. The maintainers accept no liability for outcomes from applying any content here.

SSH configuration changes can lock you out of a server. Firewall changes can take a site offline. TLS changes can break older clients. DNS changes can make a domain unresolvable. Every change in this repository has a documented validation step — follow it.
