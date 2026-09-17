# 157 — No-invention enforcement

**Phase** 13 · Processing  |  **Depends on** [150](150-response-parse.md), [155](155-evidence-linking.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A gate between parsing and application that drops any value the evidence does not support, so an empty field stays
empty rather than becoming a plausible guess.

## Files

- `frontend/lib/features/processing/domain/no_invention_guard.dart` (new)

## Steps

1. Drop values with an empty evidence list for fields marked evidence-required.
2. Reject values contradicting an identifier pattern or an option list.
3. Record each rejection and its reason on the job, so review can show why a field stayed empty.

## Definition of done

- [ ] A missing purchase year stays "Not detected" rather than becoming a guess.
- [ ] Tests: unit tests over fabricated responses — unsupported value, pattern violation and off-list option — each
      asserting the rejection reason, with no Flutter binding.
