# 234 — Automated secret leak test

**Phase** 22 · Privacy and security  |  **Depends on** [022](../02-foundation/022-logger-service.md), [210](../19-bundles-and-merge/210-bundle-encryption.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A suite that produces a real export, a real bundle and a real exported log, then fails if any byte of them matches a
secret shape or a value held in secure storage during the run.

## Files

- `frontend/test/support/secret_patterns.dart` (new)
- `frontend/test/security/secret_scan_test.dart` (new)

## Steps

1. Patterns: AWS-style key ids and secrets, bearer and refresh tokens, PEM private-key headers, long base64 runs,
   provider key prefixes, plus every value written to the fake secure store during the test.
2. Generate artefacts through the real writers — the export packager, the bundle writer (392) and the log export (028) —
   never from hand-written fixtures, so the scan follows the code that ships.
3. Scan file bytes and archive entry names, including nested entries, and report every hit with artefact, entry and
   offset rather than stopping at the first.

## Constraints

- The suite plants its own secrets at run time; no real or example credential is committed (FE-SEC-01).
- Artefacts are generated into a temporary directory and removed afterwards (FE-TEST-05).

## Definition of done

- [ ] The suite fails when any artefact contains a key, token or credential, naming artefact, entry and offset.
- [ ] Tests: `frontend/test/security/secret_scan_test.dart` over a clean run, plus a fixture pair proving a token
      planted in a bundle entry name and one planted in a log line each fail the scan.
