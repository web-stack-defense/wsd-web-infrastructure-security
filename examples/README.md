# Examples

This directory holds sanitized example output and reference files that complement the main configurations in this repository.

## Layout

```
examples/
  tls-verification-sample.txt   — Sample output from verify-tls.sh
  sshd-audit-sample.txt         — Sample output from audit-sshd-config.sh
  dns-records-sample.txt        — Sample sanitized zone file showing a complete record set
```

## Notes

- All examples use the documentation reserved range `203.0.113.0/24` for placeholder IP addresses
- All examples use `example.com` for domain names
- All credentials, keys, public-key fingerprints, account identifiers, and DKIM key material are clearly marked placeholders
- Example output reflects a hypothetical environment, not any real production system
