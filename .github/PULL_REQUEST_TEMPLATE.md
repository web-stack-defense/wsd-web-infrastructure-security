# Pull Request

## Summary

<!-- What does this PR change? -->

## Linked issue

<!-- Reference the issue that was opened first to discuss scope. PRs without a prior issue are unlikely to be merged. -->

Closes #

## Type of change

- [ ] Correction to existing content
- [ ] New configuration template
- [ ] New checklist
- [ ] New diagnostic script
- [ ] Documentation update
- [ ] Other (describe below)

## Sanitization confirmation

- [ ] No real domain names appear in the changes (uses `example.com`)
- [ ] No real IP addresses appear (uses `203.0.113.0/24` or equivalent documentation range)
- [ ] No real keys, certificates, fingerprints, or account identifiers appear
- [ ] Any new placeholder values are clearly marked as placeholders

## Upstream compliance

- [ ] New SSH directives use names supported by OpenSSH (validated against `ssh -Q kex`, `ssh -Q cipher`, `ssh -Q mac` or the OpenSSH man pages)
- [ ] New TLS cipher names match the IANA / OpenSSL naming used by the relevant server software
- [ ] References to Mozilla guidelines specify the guideline version where relevant

## Validation

- [ ] Changes have been tested against at least one environment documented in TESTED_ON.md
- [ ] If a new configuration is added, inline comments explain the reason for each directive
- [ ] If a new script is added, it has been tested and does not modify files unless explicitly stated
- [ ] Shell scripts pass `bash -n` syntax check

## Notes for reviewers

<!-- Anything reviewers should pay particular attention to. -->
