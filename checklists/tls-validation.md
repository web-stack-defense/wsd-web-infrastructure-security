# TLS Validation Checklist

Verification steps for confirming a TLS configuration is correctly deployed. Use after any TLS configuration change or quarterly as part of routine review.

## Local Validation

Run from the server itself before going public.

### Configuration syntax

- [ ] Apache: `sudo apache2ctl configtest` returns "Syntax OK"
- [ ] Nginx: `sudo nginx -t` returns "syntax is ok" and "test is successful"
- [ ] Certificate files exist and are readable by the web server user
- [ ] Private key file is owned by root and is mode 600

### Service status

- [ ] Web server is running (`systemctl status apache2` or `systemctl status nginx`)
- [ ] No errors in the web server error log since the last reload
- [ ] No "could not load certificate" or "bad certificate" errors in the log

### Certificate sanity

- [ ] Certificate matches the domain it is serving (`openssl x509 -in fullchain.pem -noout -subject -issuer`)
- [ ] Certificate is currently valid (not expired, not yet valid is rare but possible after clock skew)
- [ ] Certificate chain is complete (the file includes the issuer's intermediate certificate)
- [ ] Private key matches the certificate (`openssl x509 -in cert.pem -noout -modulus | md5sum` matches `openssl rsa -in key.pem -noout -modulus | md5sum`)

## External Validation

Run from outside the server to confirm public visibility.

### Quick smoke test

Run the script in `scripts/verify-tls.sh`:

```bash
./verify-tls.sh example.com
```

Check that:

- [ ] TLS 1.0 and TLS 1.1 are reported as disabled
- [ ] TLS 1.2 and TLS 1.3 are reported as enabled
- [ ] Certificate chain validates
- [ ] Certificate expiration is more than 14 days away
- [ ] HSTS header is present (if HSTS is enabled in your config)
- [ ] Other security headers are present

### Qualys SSL Labs

Browse to [SSL Labs SSL Test](https://www.ssllabs.com/ssltest/) and enter your domain.

- [ ] Overall grade is A or A+
- [ ] No "Vulnerable to" warnings
- [ ] "Forward Secrecy" shows as "Yes (with all simulated clients)"
- [ ] HSTS shows as configured (if enabled)
- [ ] OCSP stapling is reported (or noted as inactive if using Let's Encrypt without OCSP URL)

If the grade is below A:

- B or lower with cipher issues → cipher suite includes weak ciphers, review the TLS config
- B or lower with key exchange issues → DH parameters too small or RSA key too small
- C or lower → fundamental problem, do not move to production

### Mozilla Observatory

Browse to [Mozilla Observatory](https://observatory.mozilla.org/) and enter your domain.

- [ ] Overall grade is B or higher (A or A+ requires CSP, which requires per-site tuning)
- [ ] No critical issues flagged
- [ ] Score components are reviewed:
  - [ ] HTTPS configuration: pass
  - [ ] HSTS: pass (if enabled)
  - [ ] X-Content-Type-Options: pass
  - [ ] X-Frame-Options: pass
  - [ ] Referrer-Policy: pass

### securityheaders.com

Browse to [securityheaders.com](https://securityheaders.com/) and enter your domain.

- [ ] Grade is B+ or higher
- [ ] All expected headers are present
- [ ] No "Server" header version disclosure
- [ ] No "X-Powered-By" header

## Functional Validation

After the TLS config is verified, confirm the site actually works.

- [ ] Homepage loads over HTTPS
- [ ] Admin login page loads over HTTPS
- [ ] HTTP requests redirect to HTTPS
- [ ] Forms submit successfully over HTTPS
- [ ] Images, CSS, and JavaScript all load (no mixed content warnings in browser console)
- [ ] Third-party embeds work (or known-broken embeds are documented)
- [ ] Analytics still register page views (Google Analytics, Plausible, etc.)
- [ ] WebSocket connections (if used) work over WSS

## HSTS-Specific Validation

If HSTS is enabled, additional steps apply.

- [ ] HSTS header is present in response (check with `curl -sI https://example.com`)
- [ ] max-age starts low (300 seconds) for testing
- [ ] After several days of clean operation with low max-age, increase to 31536000
- [ ] includeSubDomains is set only if ALL subdomains support HTTPS
- [ ] preload is NOT set unless you are committed to permanent HTTPS for the domain
- [ ] If preload is intended, submit at [hstspreload.org](https://hstspreload.org/) only after confirming all requirements

## Certificate Renewal Validation

Especially important for Let's Encrypt certificates that renew every 60-90 days.

- [ ] Certbot or equivalent ACME client is installed
- [ ] Renewal cron job or systemd timer is active (`sudo certbot renew --dry-run` succeeds)
- [ ] Renewal hooks are configured to reload the web server after renewal
- [ ] Email notifications for renewal failures are configured
- [ ] Renewal has succeeded at least once in production (not just dry-run)

## Recurring Review

- [ ] Schedule quarterly review of:
  - [ ] Mozilla SSL Configuration Generator guidelines (check for updates)
  - [ ] Cipher suite list (remove anything now classified as weak)
  - [ ] Certificate expiration dates
  - [ ] DNS-related TLS records (CAA records, DS records for DNSSEC)
  - [ ] HSTS configuration (especially if domain or subdomain structure changes)

## Documentation

After successful validation:

- [ ] Current TLS configuration is documented (which Mozilla profile, which OpenSSL version, when last reviewed)
- [ ] Certificate management process is documented (renewal method, where keys are stored, who has access)
- [ ] HSTS deployment status is documented (max-age value, includeSubDomains, preload status)
- [ ] Next scheduled review date is recorded
